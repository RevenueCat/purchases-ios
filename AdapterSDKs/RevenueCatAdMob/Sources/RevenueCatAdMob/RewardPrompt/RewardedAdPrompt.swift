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

/// Displays a prompt for an already-loaded rewarded ad with RevenueCat reward verification.
///
/// The component renders your content immediately and reads reward configuration from the local cache
/// without starting or waiting for a fetch. It tracks a prompt-shown event when the content appears.
/// Call ``RewardedAdPromptContext/accept()``
/// to track acceptance and present the supplied ad.
///
/// When cached configuration is unavailable, the context's `rewardConfiguration` is `nil`.
/// This does not prevent accepting the offer. RevenueCat must be configured before using the prompt.
/// If the ad cannot be presented, `onResult` reports `.notPresented` with a presentation error.
///
/// A terminal result is delivered at most once, on the main actor. After the reward is earned,
/// `.verificationCompleted` is delivered when verification finishes, whether successful or not,
/// independently of ad dismissal.
/// `.dismissed` is delivered only if the ad closes before a reward is earned. The callback is not a signal
/// that the ad has closed; `.notPresented` may be delivered synchronously from `accept()`.
/// The `onResult` closure from the latest rendered offer is captured on acceptance and retained
/// for that ad's terminal outcome, even if the view updates afterward.
@available(iOS 15.0, *)
@MainActor
public struct RewardedAdPrompt<Content: View>: View {

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
    ///   - onResult: Handles the terminal result after acceptance.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptVerificationResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        fatalError("Implemented in the next stacked PR.")
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
    ///   - onResult: Handles the terminal result after acceptance.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedInterstitialAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptVerificationResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        fatalError("Implemented in the next stacked PR.")
    }

    /// The offer content until the prompt is accepted.
    public var body: some View {
        EmptyView()
    }

}

/// Displays a prompt for an already-loaded rewarded ad without RevenueCat reward verification.
///
/// The component renders your content immediately and reads reward configuration from the local cache
/// without starting or waiting for a fetch. It tracks a prompt-shown event when the content appears.
/// Call ``RewardedAdPromptContext/accept()``
/// to track acceptance and present the supplied ad.
///
/// The app is responsible for granting the reward when AdMob reports that it was earned.
/// Immediately before presentation, this component clears any existing per-ad server-side verification
/// options and RevenueCat verification state, including verification enabled before supplying the ad.
/// AdMob's dashboard-side callback configuration is not changed.
/// When cached configuration is unavailable, the context's `rewardConfiguration` is `nil`.
/// This does not prevent accepting the offer. RevenueCat must be configured before using the prompt.
/// If the ad cannot be presented, `onResult` reports `.notPresented` with a presentation error.
///
/// A terminal result is delivered at most once, on the main actor. `.rewardEarned` arrives when AdMob
/// reports the reward; the ad may still be visible. `.dismissed` is delivered only if the ad closes
/// before a reward is earned.
/// Later dismissal does not deliver a second result. The callback is not a signal that the ad has closed;
/// `.notPresented` may be delivered synchronously from `accept()`.
/// The `onResult` closure from the latest rendered offer is captured on acceptance and retained
/// for that ad's terminal outcome, even if the view updates afterward.
@available(iOS 15.0, *)
@MainActor
public struct RewardedAdPromptWithoutVerification<Content: View>: View {

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
    ///   - onResult: Handles the terminal result after acceptance.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptUnverifiedResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        fatalError("Implemented in the next stacked PR.")
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
    ///   - onResult: Handles the terminal result after acceptance.
    ///   - content: Offer content, with optional cached reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedInterstitialAd,
        placement: String? = nil,
        onResult: @escaping @MainActor (RewardedAdPromptUnverifiedResult) -> Void,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        fatalError("Implemented in the next stacked PR.")
    }

    /// The offer content until the prompt is accepted.
    public var body: some View {
        EmptyView()
    }

}

#endif
