//
//  RewardedAdPromptWithoutVerification.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
import RevenueCat
import SwiftUI

/// Displays a prompt for an already-loaded rewarded ad without RevenueCat reward verification.
///
/// The component renders your content immediately and tracks a prompt-shown event when it appears.
/// Call ``RewardedAdPromptUnverifiedContext/accept()``
/// to track acceptance and present the supplied ad.
///
/// The app defines the offer and is responsible for granting its own reward when AdMob reports
/// that it was earned. This component does not load or expose RevenueCat reward configuration.
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
    ///   - content: App-defined offer content, with an action to accept the offer.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptUnverifiedResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptUnverifiedContext) -> Content
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
    ///   - content: App-defined offer content, with an action to accept the offer.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedInterstitialAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptUnverifiedResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptUnverifiedContext) -> Content
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

#endif
