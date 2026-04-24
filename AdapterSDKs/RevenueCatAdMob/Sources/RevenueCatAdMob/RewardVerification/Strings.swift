//
//  Strings.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Centralised message strings for the RewardVerification subsystem so call sites stay
    /// readable and message wording is reviewed in one place.
    enum Strings {

        static let customRewardTextEncodingFailed: String =
            "RewardVerification.Setup: failed to encode customRewardText JSON for a " +
            "[String: String] payload — JSONSerialization should never fail on this input."
    }
}

#endif
