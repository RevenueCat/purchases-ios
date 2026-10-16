//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdPromptResult.swift
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import RevenueCat

/// The terminal result of a rewarded-ad prompt with reward verification enabled.
@available(iOS 15.0, *)
public struct RewardedAdPromptVerificationResult {

    /// The category of terminal result.
    public let kind: Kind

    /// The RevenueCat verification result when ``kind`` is ``Kind/verificationCompleted``.
    public let rewardVerificationResult: RewardVerificationResult?

    /// The presentation error when ``kind`` is ``Kind/notPresented``.
    public let presentationError: RewardedAdPromptError?

    /// A category of verification-enabled rewarded-ad prompt result.
    public struct Kind: Sendable, Equatable, Hashable {

        /// The ad was dismissed and reward verification finished, whether successful or not.
        public static let verificationCompleted = Kind(rawValue: "verification_completed")

        /// The ad was dismissed before a reward was earned.
        public static let dismissed = Kind(rawValue: "dismissed")

        /// The ad was not presented. Inspect `presentationError` for the reason.
        public static let notPresented = Kind(rawValue: "not_presented")

        private let rawValue: String

        private init(rawValue: String) {
            self.rawValue = rawValue
        }

    }

}

/// The terminal result of a rewarded-ad prompt with reward verification disabled.
@available(iOS 15.0, *)
public struct RewardedAdPromptUnverifiedResult {

    /// The category of terminal result.
    public let kind: Kind

    /// The presentation error when ``kind`` is ``Kind/notPresented``.
    public let presentationError: RewardedAdPromptError?

    /// A category of verification-disabled rewarded-ad prompt result.
    public struct Kind: Sendable, Equatable, Hashable {

        /// The ad was dismissed after AdMob reported that the reward was earned. The app grants the reward.
        public static let rewardEarned = Kind(rawValue: "reward_earned")

        /// The ad was dismissed before a reward was earned.
        public static let dismissed = Kind(rawValue: "dismissed")

        /// The ad was not presented. Inspect `presentationError` for the reason.
        public static let notPresented = Kind(rawValue: "not_presented")

        private let rawValue: String

        private init(rawValue: String) {
            self.rawValue = rawValue
        }

    }

}

#endif
