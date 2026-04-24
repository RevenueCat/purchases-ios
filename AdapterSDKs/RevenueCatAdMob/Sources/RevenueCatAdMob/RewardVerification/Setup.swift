//
//  Setup.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// AdMob ad types that accept server-side verification options.
    protocol CapableAd: AnyObject {
        var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions? { get set }
    }

    /// Load-time SSV setup for rewarded AdMob ads.
    enum Setup {

        /// Production entry point. Reads SDK config from `Purchases.shared`; no-ops if not configured.
        @MainActor
        static func install(on loadedAd: some CapableAd) {
            guard Purchases.isConfigured else { return }
            let purchases = Purchases.shared
            self.install(on: loadedAd, apiKey: purchases.apiKey, appUserID: purchases.appUserID)
        }

        /// Generates a `client_transaction_id`, wires `ServerSideVerificationOptions` onto the ad,
        /// and stashes per-ad state via `StateStore`. Returns the stashed state, or `nil` if
        /// payload encoding fails (which also triggers an `assertionFailure`).
        ///
        /// `@MainActor` to match the production seam above and to document the
        /// `StateStore`/GMA-mutation invariant.
        @MainActor
        @discardableResult
        static func install(
            on loadedAd: some CapableAd,
            apiKey: String,
            appUserID: String
        ) -> State? {
            let clientTransactionID = UUID().uuidString

            guard let customRewardText = self.makeCustomRewardText(
                apiKey: apiKey,
                clientTransactionID: clientTransactionID
            ) else {
                assertionFailure(Strings.customRewardTextEncodingFailed)
                return nil
            }

            let options = GoogleMobileAds.ServerSideVerificationOptions()
            options.userIdentifier = appUserID
            // GMA renames the ObjC `customRewardString` to `customRewardText` in Swift.
            options.customRewardText = customRewardText
            loadedAd.serverSideVerificationOptions = options

            let state = State(clientTransactionID: clientTransactionID)
            RewardVerification.stateStore.set(state, for: loadedAd)
            return state
        }

        /// Encodes the SSV `customRewardString` payload as deterministic JSON
        /// (`.sortedKeys`) so logs and tests are stable.
        static func makeCustomRewardText(apiKey: String, clientTransactionID: String) -> String? {
            let payload: [String: String] = [
                "api_key": apiKey,
                "client_transaction_id": clientTransactionID
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
                  let string = String(data: data, encoding: .utf8) else {
                return nil
            }
            return string
        }
    }
}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RewardVerification.CapableAd {}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RewardVerification.CapableAd {}

#endif
