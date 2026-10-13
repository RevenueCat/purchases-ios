//
//  RewardedAdPromptError.swift
//
//  Created by RevenueCat.
//

import Foundation

#if ENABLE_CONFIGURED_AD_REWARDS && os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)

/// A failure while preparing or presenting a ``RewardedAdPrompt``.
@available(iOS 15.0, *)
public struct RewardedAdPromptError: LocalizedError {

    /// The category of failure.
    public let code: Code

    /// The underlying error, when the failure originated in AdMob.
    public let underlyingError: Error?

    /// A description suitable for displaying in a prompt's failure state.
    public var errorDescription: String? {
        switch self.code {
        case .purchasesNotConfigured:
            return "RevenueCat is not configured."
        case .configuredRewardsUnavailable:
            return "No configured rewards are available for this ad unit."
        case .adFailedToLoad:
            if let underlyingError {
                return "The rewarded ad failed to load: \(underlyingError.localizedDescription)"
            } else {
                return "The rewarded ad failed to load."
            }
        case .adFailedToPresent:
            if let underlyingError {
                return "The rewarded ad failed to present: \(underlyingError.localizedDescription)"
            } else {
                return "The rewarded ad failed to present."
            }
        default:
            return "The rewarded ad prompt could not be loaded."
        }
    }

    init(code: Code, underlyingError: Error? = nil) {
        self.code = code
        self.underlyingError = underlyingError
    }

    /// A category of rewarded-ad prompt failure.
    public struct Code: Sendable, Equatable, Hashable {

        /// RevenueCat has not been configured yet.
        public static let purchasesNotConfigured = Code(rawValue: "purchases_not_configured")

        /// RevenueCat could not provide configured rewards for the ad unit.
        public static let configuredRewardsUnavailable = Code(rawValue: "configured_rewards_unavailable")

        /// AdMob failed to load the rewarded ad.
        public static let adFailedToLoad = Code(rawValue: "ad_failed_to_load")

        /// AdMob failed to present the loaded rewarded ad.
        public static let adFailedToPresent = Code(rawValue: "ad_failed_to_present")

        /// The stable string representation of this failure category.
        public let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

    }

}

#endif
