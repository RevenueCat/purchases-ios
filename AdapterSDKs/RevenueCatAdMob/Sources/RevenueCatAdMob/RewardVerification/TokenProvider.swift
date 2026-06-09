//
//  TokenProvider.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Source of reward-verification tokens for load-time SSV setup.
    ///
    /// The adapter never calls `Purchases.shared.generateRewardVerificationToken` directly;
    /// `Setup` routes through a `TokenProvider`. The production conformance is
    /// `RewardVerification.PurchasesTokenProvider`; tests inject fakes.
    protocol TokenProvider {
        var isConfigured: Bool { get }
        func generateToken(
            impressionId: String
        ) -> (customData: String, clientTransactionID: String, appUserID: String)
    }

    /// Production `TokenProvider` backed by `Purchases.shared`.
    struct PurchasesTokenProvider: TokenProvider {

        var isConfigured: Bool { Purchases.isConfigured }

        func generateToken(
            impressionId: String
        ) -> (customData: String, clientTransactionID: String, appUserID: String) {
            Purchases.shared.generateRewardVerificationToken(impressionId: impressionId)
        }
    }
}

#endif
