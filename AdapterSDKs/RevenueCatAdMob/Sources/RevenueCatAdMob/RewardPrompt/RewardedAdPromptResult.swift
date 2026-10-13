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

#if ENABLE_CONFIGURED_AD_REWARDS && os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import RevenueCat

/// The terminal result of a rewarded-ad prompt with reward verification enabled.
@available(iOS 15.0, *)
public struct RewardedAdPromptVerificationResult {

    /// The category of terminal result.
    public let kind: Kind

    /// The RevenueCat verification result when ``kind`` is ``Kind/verificationCompleted``.
    public let rewardVerificationResult: RewardVerificationResult?

    /// The presentation error when ``kind`` is ``Kind/presentationFailed``.
    public let presentationError: RewardedAdPromptError?

    private init(
        kind: Kind,
        rewardVerificationResult: RewardVerificationResult? = nil,
        presentationError: RewardedAdPromptError? = nil
    ) {
        self.kind = kind
        self.rewardVerificationResult = rewardVerificationResult
        self.presentationError = presentationError
    }

    static func verificationCompleted(_ result: RewardVerificationResult) -> Self {
        return .init(kind: .verificationCompleted, rewardVerificationResult: result)
    }

    static let dismissed = Self(kind: .dismissed)

    static func presentationFailed(_ error: RewardedAdPromptError) -> Self {
        return .init(kind: .presentationFailed, presentationError: error)
    }

    /// A category of verification-enabled rewarded-ad prompt result.
    public struct Kind: Sendable, Equatable, Hashable {

        /// Reward verification reached its final result.
        public static let verificationCompleted = Kind(rawValue: "verification_completed")

        /// The ad was dismissed before a reward was earned.
        public static let dismissed = Kind(rawValue: "dismissed")

        /// The loaded ad failed to present.
        public static let presentationFailed = Kind(rawValue: "presentation_failed")

        /// The stable string representation of this result category.
        public let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

    }

}

/// The terminal result of a rewarded-ad prompt with reward verification disabled.
@available(iOS 15.0, *)
public struct RewardedAdPromptUnverifiedResult {

    /// The category of terminal result.
    public let kind: Kind

    /// The presentation error when ``kind`` is ``Kind/presentationFailed``.
    public let presentationError: RewardedAdPromptError?

    private init(kind: Kind, presentationError: RewardedAdPromptError? = nil) {
        self.kind = kind
        self.presentationError = presentationError
    }

    static let rewardEarned = Self(kind: .rewardEarned)

    static let dismissed = Self(kind: .dismissed)

    static func presentationFailed(_ error: RewardedAdPromptError) -> Self {
        return .init(kind: .presentationFailed, presentationError: error)
    }

    /// A category of verification-disabled rewarded-ad prompt result.
    public struct Kind: Sendable, Equatable, Hashable {

        /// AdMob reported that the reward was earned. The app is responsible for granting it.
        public static let rewardEarned = Kind(rawValue: "reward_earned")

        /// The ad was dismissed before a reward was earned.
        public static let dismissed = Kind(rawValue: "dismissed")

        /// The loaded ad failed to present.
        public static let presentationFailed = Kind(rawValue: "presentation_failed")

        /// The stable string representation of this result category.
        public let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

    }

}

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptResultDispatcher {

    enum Mode {
        case verificationEnabled(@MainActor (RewardedAdPromptVerificationResult) -> Void)
        case verificationDisabled(@MainActor (RewardedAdPromptUnverifiedResult) -> Void)
    }

    private let mode: Mode
    private var rewardWasEarned = false
    private var hasDeliveredResult = false

    init(mode: Mode) {
        self.mode = mode
    }

    func rewardEarned() {
        guard !self.hasDeliveredResult else { return }
        self.rewardWasEarned = true

        guard case .verificationDisabled(let resultHandler) = self.mode else { return }
        self.hasDeliveredResult = true
        resultHandler(.rewardEarned)
    }

    func verificationCompleted(_ result: RewardVerificationResult) {
        guard !self.hasDeliveredResult,
              case .verificationEnabled(let resultHandler) = self.mode else {
            return
        }

        self.hasDeliveredResult = true
        resultHandler(.verificationCompleted(result))
    }

    func dismissed() {
        guard !self.hasDeliveredResult, !self.rewardWasEarned else { return }
        self.hasDeliveredResult = true

        switch self.mode {
        case .verificationEnabled(let resultHandler):
            resultHandler(.dismissed)
        case .verificationDisabled(let resultHandler):
            resultHandler(.dismissed)
        }
    }

    func presentationFailed(_ error: RewardedAdPromptError) {
        guard !self.hasDeliveredResult else { return }
        self.hasDeliveredResult = true

        switch self.mode {
        case .verificationEnabled(let resultHandler):
            resultHandler(.presentationFailed(error))
        case .verificationDisabled(let resultHandler):
            resultHandler(.presentationFailed(error))
        }
    }

}

#endif
