//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdPromptCallbacks.swift
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import RevenueCat
import UIKit

@available(iOS 15.0, *)
@MainActor
protocol RewardedAdPromptCallbackDispatching: AnyObject {

    func present(_ rewardedAd: any RewardedAdPromptPresentingAd, from viewController: UIViewController)

    func dismissed()

    func notPresented(_ error: RewardedAdPromptError)

}

@available(iOS 15.0, *)
@MainActor
final class VerifiedRewardCallbackDispatcher: RewardedAdPromptCallbackDispatching {

    private let onVerificationCompleted: @MainActor (RewardVerificationResult) -> Void
    private let presentationCallbacks: RewardedAdPromptPresentationCallbacks

    init(
        onVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void,
        onDismiss: (@MainActor () -> Void)?,
        onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)?
    ) {
        self.onVerificationCompleted = onVerificationCompleted
        self.presentationCallbacks = .init(onDismiss: onDismiss, onPresentationFailed: onPresentationFailed)
    }

    func present(_ rewardedAd: any RewardedAdPromptPresentingAd, from viewController: UIViewController) {
        rewardedAd.enableRewardVerification()
        rewardedAd.present(
            from: viewController,
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { self.verificationCompleted($0) }
        )
    }

    func verificationCompleted(_ result: RewardVerificationResult) {
        guard self.presentationCallbacks.consumeReward() else { return }
        self.onVerificationCompleted(result)
    }

    func dismissed() {
        self.presentationCallbacks.dismissed()
    }

    func notPresented(_ error: RewardedAdPromptError) {
        self.presentationCallbacks.notPresented(error)
    }

}

@available(iOS 15.0, *)
@MainActor
final class UnverifiedRewardCallbackDispatcher: RewardedAdPromptCallbackDispatching {

    private let onRewardEarned: @MainActor () -> Void
    private let presentationCallbacks: RewardedAdPromptPresentationCallbacks

    init(
        onRewardEarned: @escaping @MainActor () -> Void,
        onDismiss: (@MainActor () -> Void)?,
        onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)?
    ) {
        self.onRewardEarned = onRewardEarned
        self.presentationCallbacks = .init(onDismiss: onDismiss, onPresentationFailed: onPresentationFailed)
    }

    func present(_ rewardedAd: any RewardedAdPromptPresentingAd, from viewController: UIViewController) {
        rewardedAd.disableRewardVerification()
        rewardedAd.present(from: viewController, userDidEarnRewardHandler: { self.rewardEarned() })
    }

    func rewardEarned() {
        guard self.presentationCallbacks.consumeReward() else { return }
        self.onRewardEarned()
    }

    func dismissed() {
        self.presentationCallbacks.dismissed()
    }

    func notPresented(_ error: RewardedAdPromptError) {
        self.presentationCallbacks.notPresented(error)
    }

}

@available(iOS 15.0, *)
@MainActor
private final class RewardedAdPromptPresentationCallbacks {

    private let onDismiss: (@MainActor () -> Void)?
    private let onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)?
    private var hasDismissed = false
    private var hasFailedToPresent = false
    private var hasDeliveredReward = false

    init(
        onDismiss: (@MainActor () -> Void)?,
        onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)?
    ) {
        self.onDismiss = onDismiss
        self.onPresentationFailed = onPresentationFailed
    }

    func consumeReward() -> Bool {
        guard !self.hasFailedToPresent, !self.hasDeliveredReward else { return false }
        self.hasDeliveredReward = true
        return true
    }

    func dismissed() {
        guard !self.hasFailedToPresent, !self.hasDismissed else { return }
        self.hasDismissed = true
        self.onDismiss?()
    }

    func notPresented(_ error: RewardedAdPromptError) {
        guard !self.hasFailedToPresent, !self.hasDismissed, !self.hasDeliveredReward else { return }
        self.hasFailedToPresent = true
        DispatchQueue.main.async {
            self.onPresentationFailed?(error)
        }
    }

}
#endif
