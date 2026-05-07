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

        static func customRewardTextEncodingFailed(_ error: Error) -> String {
            "RewardVerification.Setup: failed to encode customRewardText JSON for a " +
            "[String: String] payload — JSONSerialization should never fail on this input. Error: \(error)"
        }

        static let rewardVerificationResultRequiresEnable: String =
            "Passing a reward verification result callback requires calling enableRewardVerification() " +
            "on this ad after load (with the RevenueCat SDK configured)."

        static let rewardVerificationResultMissingVerificationState: String =
            "Reward verification result callback ignored because reward verification was not enabled " +
            "for this ad. Call `enableRewardVerification()` after loading and before presenting."
    }
}

#endif
