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
import UIKit

/// The terminal result of a rewarded-ad prompt with reward verification enabled.
@available(iOS 15.0, *)
public struct RewardedAdPromptVerificationResult {

    /// The category of terminal result.
    public let kind: Kind

    /// The RevenueCat verification result when ``kind`` is ``Kind/verificationCompleted``.
    public let rewardVerificationResult: RewardVerificationResult?

    /// The presentation error when ``kind`` is ``Kind/notPresented``.
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

    static func notPresented(_ error: RewardedAdPromptError) -> Self {
        return .init(kind: .notPresented, presentationError: error)
    }

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

    private init(kind: Kind, presentationError: RewardedAdPromptError? = nil) {
        self.kind = kind
        self.presentationError = presentationError
    }

    static let rewardEarned = Self(kind: .rewardEarned)

    static let dismissed = Self(kind: .dismissed)

    static func notPresented(_ error: RewardedAdPromptError) -> Self {
        return .init(kind: .notPresented, presentationError: error)
    }

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

@available(iOS 15.0, *)
@MainActor
protocol RewardedAdPromptResultDispatching: AnyObject {

    func present(
        _ rewardedAd: any RewardedAdPromptPresentingAd,
        from viewController: UIViewController
    )

    func dismissed()

    func notPresented(_ error: RewardedAdPromptError)

}

@available(iOS 15.0, *)
@MainActor
final class VerifiedRewardResultDispatcher: RewardedAdPromptResultDispatching {

    private let resultHandler: @MainActor (RewardedAdPromptVerificationResult) -> Void
    private var rewardWasEarned = false
    private var hasDeliveredResult = false

    init(onResult: @escaping @MainActor (RewardedAdPromptVerificationResult) -> Void) {
        self.resultHandler = onResult
    }

    func present(
        _ rewardedAd: any RewardedAdPromptPresentingAd,
        from viewController: UIViewController
    ) {
        rewardedAd.enableRewardVerification()
        rewardedAd.present(
            from: viewController,
            rewardVerificationStarted: {
                self.rewardEarned()
            },
            rewardVerificationCompleted: { result in
                self.verificationCompleted(result)
            }
        )
    }

    func rewardEarned() {
        self.rewardWasEarned = true
    }

    func verificationCompleted(_ result: RewardVerificationResult) {
        guard !self.hasDeliveredResult else { return }

        self.hasDeliveredResult = true
        self.resultHandler(.verificationCompleted(result))
    }

    func dismissed() {
        guard !self.hasDeliveredResult, !self.rewardWasEarned else { return }
        self.hasDeliveredResult = true
        self.resultHandler(.dismissed)
    }

    func notPresented(_ error: RewardedAdPromptError) {
        guard !self.hasDeliveredResult else { return }
        self.hasDeliveredResult = true
        self.resultHandler(.notPresented(error))
    }

}

@available(iOS 15.0, *)
@MainActor
final class UnverifiedRewardResultDispatcher: RewardedAdPromptResultDispatching {

    private let resultHandler: @MainActor (RewardedAdPromptUnverifiedResult) -> Void
    private var hasDeliveredResult = false

    init(onResult: @escaping @MainActor (RewardedAdPromptUnverifiedResult) -> Void) {
        self.resultHandler = onResult
    }

    func present(
        _ rewardedAd: any RewardedAdPromptPresentingAd,
        from viewController: UIViewController
    ) {
        rewardedAd.disableRewardVerification()
        rewardedAd.present(
            from: viewController,
            userDidEarnRewardHandler: {
                self.rewardEarned()
            }
        )
    }

    func rewardEarned() {
        guard !self.hasDeliveredResult else { return }
        self.hasDeliveredResult = true
        self.resultHandler(.rewardEarned)
    }

    func dismissed() {
        guard !self.hasDeliveredResult else { return }
        self.hasDeliveredResult = true
        self.resultHandler(.dismissed)
    }

    func notPresented(_ error: RewardedAdPromptError) {
        guard !self.hasDeliveredResult else { return }
        self.hasDeliveredResult = true
        self.resultHandler(.notPresented(error))
    }

}

#endif
