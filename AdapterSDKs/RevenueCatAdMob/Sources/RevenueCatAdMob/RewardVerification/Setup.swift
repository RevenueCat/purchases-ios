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
    }

    /// Load-time SSV setup for rewarded AdMob ads.
    enum Setup {

        /// Returns per-ad verification state stashed by ``install(on:token:)``, if any.
        @MainActor
        static func verificationState(for object: AnyObject) -> State? {
            RewardVerification.stateStore.retrieve(for: object)
        }

        /// Production entry point. Mints a token via `tokenProvider`; no-ops if not configured.
        ///
        /// Delegates token generation to the core SDK (through `TokenProvider`) so the adapter
        /// holds no SSV payload logic. The `tokenProvider` parameter is injectable for tests.
        @MainActor
        static func install(
            on loadedAd: some CapableAd,
            tokenProvider: TokenProvider = PurchasesTokenProvider()
        ) {
            guard tokenProvider.isConfigured else {
                Logger.warn(RewardVerificationStrings.setup_purchases_not_configured)
                return
            }
            let impressionId = Tracking.Adapter.impressionID(from: loadedAd.responseInfo)
            let token = tokenProvider.generateToken(impressionId: impressionId)
            self.install(on: loadedAd, token: token)
        }

        /// Wires `ServerSideVerificationOptions` onto the ad from a core-minted token and stashes
        /// per-ad state via `StateStore`. Holds no payload logic — the token is produced by core.
        @MainActor
        @discardableResult
        static func install(
            on loadedAd: some CapableAd,
            token: (customData: String, clientTransactionID: String, appUserID: String)
        ) -> State {
            Logger.info(RewardVerificationStrings.setup_install(
                adType: "\(type(of: loadedAd))",
                transactionID: token.clientTransactionID
            ))

            let options = GoogleMobileAds.ServerSideVerificationOptions()
            options.userIdentifier = token.appUserID
            options.customRewardText = token.customData
            loadedAd.serverSideVerificationOptions = options

            let state = State(clientTransactionID: token.clientTransactionID)
            RewardVerification.stateStore.set(state, for: loadedAd)
            return state
        }
    }
}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RewardVerification.CapableAd {}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RewardVerification.CapableAd {}

#endif
