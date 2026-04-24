//
//  Strings.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Centralised message strings for the RewardVerification subsystem.
    enum Strings {

        static let customRewardTextEncodingFailed: String =
            "RewardVerification.Setup: failed to encode customRewardText JSON for a " +
            "[String: String] payload — JSONSerialization should never fail on this input."

        static let rewardVerificationOutcomeRequiresEnable: String =
            "Passing a reward verification outcome callback requires calling enableRewardVerification() " +
            "on this ad after load (with the RevenueCat SDK configured)."
    }
}

#endif
