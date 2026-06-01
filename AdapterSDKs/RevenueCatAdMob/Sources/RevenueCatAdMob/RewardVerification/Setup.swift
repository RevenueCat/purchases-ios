//
//  Setup.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) @_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// AdMob ad types that accept server-side verification options.
    protocol CapableAd: AnyObject {
        var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions? { get set }
        var responseInfo: GoogleMobileAds.ResponseInfo { get }
        var adUnitID: String { get }
        var adReward: GoogleMobileAds.AdReward { get }
        var rewardedAdFormat: RevenueCat.AdFormat { get }
    }

    /// Load-time SSV setup for rewarded AdMob ads.
    enum Setup {

        /// Returns per-ad verification state stashed by ``install(on:apiKey:appUserID:)``, if any.
        @MainActor
        static func verificationState(for object: AnyObject) -> State? {
            RewardVerification.stateStore.retrieve(for: object)
        }

        /// Production entry point. Reads SDK config from `Purchases.shared`; no-ops if not configured.
        @MainActor
        static func install(on loadedAd: some CapableAd) {
            guard Purchases.isConfigured else {
                Logger.warn(RewardVerificationStrings.setup_purchases_not_configured)
                return
            }
            let purchases = Purchases.shared
            self.install(on: loadedAd, apiKey: purchases.apiKey, appUserID: purchases.appUserID)
        }

        /// Generates a `client_transaction_id`, wires `ServerSideVerificationOptions` onto the ad,
        /// and stashes per-ad state via `StateStore`. Returns `nil` if payload encoding fails.
        @MainActor
        @discardableResult
        static func install(
            on loadedAd: some CapableAd,
            apiKey: String,
            appUserID: String
        ) -> State? {
            let clientTransactionID = UUID().uuidString
            let impressionId = Tracking.Adapter.impressionID(from: loadedAd.responseInfo)

            guard let customRewardText = self.makeCustomRewardText(
                apiKey: apiKey,
                clientTransactionID: clientTransactionID,
                impressionId: impressionId
            ) else {
                return nil
            }

            Logger.info(RewardVerificationStrings.setup_install(
                adType: "\(type(of: loadedAd))",
                transactionID: clientTransactionID
            ))

            let options = GoogleMobileAds.ServerSideVerificationOptions()
            options.userIdentifier = appUserID
            options.customRewardText = customRewardText
            loadedAd.serverSideVerificationOptions = options

            let state = State(clientTransactionID: clientTransactionID, impressionId: impressionId)
            RewardVerification.stateStore.set(state, for: loadedAd)
            return state
        }

        /// Encodes the SSV `customRewardString` payload as deterministic JSON
        /// (`.sortedKeys`) so logs and tests are stable.
        static func makeCustomRewardText(
            apiKey: String,
            clientTransactionID: String,
            impressionId: String
        ) -> String? {
            let payload: [String: String] = [
                "api_key": apiKey,
                "client_transaction_id": clientTransactionID,
                "impression_id": impressionId
            ]
            do {
                let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
                return String(data: data, encoding: .utf8)
            } catch {
                let message = RewardVerificationStrings.setup_custom_reward_text_encoding_failed(error: error)
                Logger.error(message)
                assertionFailure(message.description)
                return nil
            }
        }
    }
}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RewardVerification.CapableAd {
    internal var rewardedAdFormat: RevenueCat.AdFormat { .rewarded }
}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RewardVerification.CapableAd {
    internal var rewardedAdFormat: RevenueCat.AdFormat { .rewardedInterstitial }
}

@available(iOS 15.0, *)
internal extension RewardVerification.CapableAd {
    /// Impression identifier derived from the loaded ad, with the canonical fallback applied.
    var impressionId: String {
        Tracking.Adapter.impressionID(from: self.responseInfo)
    }

    @MainActor
    func fireEarnedUnverifiedEvent(
        tracker: Tracking.Tracker,
        impressionId: String,
        rewardVerificationEnabled: Bool
    ) {
        guard tracker.isConfigured else { return }
        let placement = Tracking.Adapter.shared.fullScreenDelegateStore
            .retrieve(for: self)?.placement
        tracker.trackAdRewardEarnedUnverified(.init(
            networkName: self.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
            mediatorName: .adMob,
            adFormat: self.rewardedAdFormat,
            placement: placement,
            adUnitId: self.adUnitID,
            impressionId: impressionId,
            rewardVerificationEnabled: rewardVerificationEnabled,
            rewardItem: self.adReward.type,
            rewardAmount: self.adReward.amount.intValue
        ))
    }
}

#endif
