//
//  RewardedAdPrompt.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
import RevenueCat
import SwiftUI
import UIKit

/// Displays a prompt for an already-loaded rewarded ad with RevenueCat reward verification.
///
/// The component reads cached reward configuration and passes it to your content through the context
/// for immediate rendering.
/// No network fetch is started or awaited. It tracks a prompt-shown event when the content appears.
/// Call ``RewardedAdPromptContext/accept()``
/// to track acceptance and present the supplied ad.
///
/// Reward configuration is prefetched automatically. If it is not cached yet or could not be loaded,
/// the context's `rewardConfiguration` is `nil`. Your content can show a generic offer without reward
/// details, or omit the offer UI.
///
/// After acceptance, `onResult` delivers at most one terminal result on the main actor:
///
/// - `.verificationCompleted`: The ad was dismissed and RevenueCat verification finished,
///   successfully or not. Verification begins when the reward is earned; delivery waits for both.
/// - `.dismissed`: The ad closed before a reward was earned.
/// - `.notPresented`: No presentation controller is attached to the prompt's window,
///   or AdMob failed to present the ad. Inspect `presentationError`. Delivery is deferred
///   to the main queue, after `accept()` returns.
@available(iOS 15.0, *)
@MainActor
public struct RewardedAdPrompt<Content: View>: View {

    private let prompt: RewardedAdPromptView<Content>

    /// Creates a prompt for an already-loaded rewarded ad.
    ///
    /// - Parameters:
    ///   - session: Optional tracking session. Reuse one to avoid counting repeated SwiftUI
    ///     appearances as separate prompt impressions. A replacement takes effect on the next appearance,
    ///     without emitting an event or resetting presentation state. When omitted, the default session
    ///     stays stable for the view's lifetime.
    ///   - ad: The loaded, unconsumed ad. Use `loadAndTrack` to retain RevenueCat ad tracking.
    ///     The prompt takes over its full-screen delegate when accepted, preserving the tracking wrapper.
    ///     Do not present the same ad elsewhere. Supplying a different ad instance resets presentation state
    ///     automatically, without changing the tracking session you provide.
    ///   - placement: Optional placement label for prompt analytics. The value recorded for the shown
    ///     event is retained for acceptance; changing the label alone does not start a new session.
    ///   - onResult: Handles the terminal result after acceptance. Updating this closure affects only
    ///     future acceptances, not an offer already accepted.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptVerificationResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        self.prompt = .init(
            session: session,
            rewardedAd: rewardedAd,
            placement: placement,
            resultDispatcherFactory: {
                VerifiedRewardResultDispatcher(onResult: onResult)
            },
            content: content
        )
    }

    /// Creates a prompt for an already-loaded rewarded interstitial ad.
    ///
    /// - Parameters:
    ///   - session: Optional tracking session. Reuse one to avoid counting repeated SwiftUI
    ///     appearances as separate prompt impressions. A replacement takes effect on the next appearance,
    ///     without emitting an event or resetting presentation state. When omitted, the default session
    ///     stays stable for the view's lifetime.
    ///   - ad: The loaded, unconsumed ad. Use `loadAndTrack` to retain RevenueCat ad tracking.
    ///     The prompt takes over its full-screen delegate when accepted, preserving the tracking wrapper.
    ///     Do not present the same ad elsewhere. Supplying a different ad instance resets presentation state
    ///     automatically, without changing the tracking session you provide.
    ///   - placement: Optional placement label for prompt analytics. The value recorded for the shown
    ///     event is retained for acceptance; changing the label alone does not start a new session.
    ///   - onResult: Handles the terminal result after acceptance. Updating this closure affects only
    ///     future acceptances, not an offer already accepted.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedInterstitialAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptVerificationResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        self.prompt = .init(
            session: session,
            rewardedAd: rewardedAd,
            placement: placement,
            resultDispatcherFactory: {
                VerifiedRewardResultDispatcher(onResult: onResult)
            },
            content: content
        )
    }

    /// The offer content until the prompt is accepted.
    public var body: some View {
        self.prompt
    }

}

/// Displays a prompt for an already-loaded rewarded ad without RevenueCat reward verification.
///
/// The component reads cached reward configuration and passes it to your content through the context
/// for immediate rendering.
/// No network fetch is started or awaited. It tracks a prompt-shown event when the content appears.
/// Call ``RewardedAdPromptContext/accept()``
/// to track acceptance and present the supplied ad.
///
/// The app is responsible for granting the reward when AdMob reports that it was earned.
///
/// Reward configuration is prefetched automatically. If it is not cached yet or could not be loaded,
/// the context's `rewardConfiguration` is `nil`. Your content can show a generic offer without reward
/// details, or omit the offer UI.
///
/// After acceptance, `onResult` delivers at most one terminal result on the main actor:
///
/// - `.rewardEarned`: The ad was dismissed after AdMob reported that the reward was earned.
///   The app is responsible for granting the reward.
/// - `.dismissed`: The ad closed before a reward was earned.
/// - `.notPresented`: No presentation controller is attached to the prompt's window,
///   or AdMob failed to present the ad. Inspect `presentationError`. Delivery is deferred
///   to the main queue, after `accept()` returns.
@available(iOS 15.0, *)
@MainActor
public struct RewardedAdPromptWithoutVerification<Content: View>: View {

    private let prompt: RewardedAdPromptView<Content>

    /// Creates a prompt for an already-loaded rewarded ad.
    ///
    /// - Parameters:
    ///   - session: Optional tracking session. Reuse one to avoid counting repeated SwiftUI
    ///     appearances as separate prompt impressions. A replacement takes effect on the next appearance,
    ///     without emitting an event or resetting presentation state. When omitted, the default session
    ///     stays stable for the view's lifetime.
    ///   - ad: The loaded, unconsumed ad. Use `loadAndTrack` to retain RevenueCat ad tracking.
    ///     The prompt takes over its full-screen delegate when accepted, preserving the tracking wrapper.
    ///     Do not present the same ad elsewhere. Supplying a different ad instance resets presentation state
    ///     automatically, without changing the tracking session you provide.
    ///   - placement: Optional placement label for prompt analytics. The value recorded for the shown
    ///     event is retained for acceptance; changing the label alone does not start a new session.
    ///   - onResult: Handles the terminal result after acceptance. Updating this closure affects only
    ///     future acceptances, not an offer already accepted.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptUnverifiedResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        self.prompt = .init(
            session: session,
            rewardedAd: rewardedAd,
            placement: placement,
            resultDispatcherFactory: {
                UnverifiedRewardResultDispatcher(onResult: onResult)
            },
            content: content
        )
    }

    /// Creates a prompt for an already-loaded rewarded interstitial ad.
    ///
    /// - Parameters:
    ///   - session: Optional tracking session. Reuse one to avoid counting repeated SwiftUI
    ///     appearances as separate prompt impressions. A replacement takes effect on the next appearance,
    ///     without emitting an event or resetting presentation state. When omitted, the default session
    ///     stays stable for the view's lifetime.
    ///   - ad: The loaded, unconsumed ad. Use `loadAndTrack` to retain RevenueCat ad tracking.
    ///     The prompt takes over its full-screen delegate when accepted, preserving the tracking wrapper.
    ///     Do not present the same ad elsewhere. Supplying a different ad instance resets presentation state
    ///     automatically, without changing the tracking session you provide.
    ///   - placement: Optional placement label for prompt analytics. The value recorded for the shown
    ///     event is retained for acceptance; changing the label alone does not start a new session.
    ///   - onResult: Handles the terminal result after acceptance. Updating this closure affects only
    ///     future acceptances, not an offer already accepted.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedInterstitialAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptUnverifiedResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        self.prompt = .init(
            session: session,
            rewardedAd: rewardedAd,
            placement: placement,
            resultDispatcherFactory: {
                UnverifiedRewardResultDispatcher(onResult: onResult)
            },
            content: content
        )
    }

    /// The offer content until the prompt is accepted.
    public var body: some View {
        self.prompt
    }

}

@available(iOS 15.0, *)
@MainActor
private struct RewardedAdPromptView<Content: View>: View {

    @Environment(\.rewardedAdPromptDependencies) private var dependencies

    let session: RewardedAdPromptSession?
    let rewardedAd: any RewardedAdPromptAd
    let placement: String?
    let resultDispatcherFactory: @MainActor () -> any RewardedAdPromptResultDispatching
    let content: (RewardedAdPromptContext) -> Content

    var body: some View {
        RewardedAdPromptStateView(
            session: self.session,
            ad: self.rewardedAd,
            placement: self.placement,
            resultDispatcherFactory: self.resultDispatcherFactory,
            dependencies: self.dependencies ?? .live,
            content: self.content
        )
        .id(ObjectIdentifier(self.rewardedAd))
    }

}

@available(iOS 15.0, *)
@MainActor
private struct RewardedAdPromptStateView<Content: View>: View {

    @StateObject private var model: RewardedAdPromptModel

    private let content: (RewardedAdPromptContext) -> Content
    private let resultDispatcherFactory: @MainActor () -> any RewardedAdPromptResultDispatching
    private let session: RewardedAdPromptSession?
    private let placement: String?

    init(
        session: RewardedAdPromptSession?,
        ad rewardedAd: any RewardedAdPromptAd,
        placement: String?,
        resultDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptResultDispatching,
        dependencies: RewardedAdPromptDependencies,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        self._model = StateObject(wrappedValue: RewardedAdPromptModel(
            session: session,
            ad: rewardedAd,
            placement: placement,
            resultDispatcherFactory: resultDispatcherFactory,
            dependencies: dependencies
        ))
        self.content = content
        self.resultDispatcherFactory = resultDispatcherFactory
        self.session = session
        self.placement = placement
    }

    var body: some View {
        Group {
            if let context = self.model.context(resultDispatcherFactory: self.resultDispatcherFactory) {
                self.content(context)
                    .onAppear {
                        self.model.refreshCachedRewardsIfNeeded()
                        self.model.promptDidAppear(session: self.session, placement: self.placement)
                    }
            }
        }
        .background {
            RewardedAdPromptPresentationAnchor { viewController in
                self.model.setPresentationAnchor(viewController)
            }
            .frame(width: 0, height: 0)
        }
    }

}

#endif
