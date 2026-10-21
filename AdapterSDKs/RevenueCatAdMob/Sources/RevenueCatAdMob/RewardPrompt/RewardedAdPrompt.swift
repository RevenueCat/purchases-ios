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
/// The component renders your content immediately, then resolves reward configuration asynchronously
/// and updates the context without blocking the main thread. It tracks a prompt-shown event when the content appears.
/// Call ``RewardedAdPromptContext/accept()``
/// to track acceptance and present the supplied ad.
///
/// While reward configuration is loading, or if it could not be loaded, the context's
/// `rewardConfiguration` is `nil`. Your content can show a generic offer without reward details,
/// or omit the offer UI.
///
/// After acceptance, callbacks run on the main actor, each at most once per presentation:
///
/// - `onVerificationCompleted`: RevenueCat verification finished, successfully or not.
///   Verification begins when AdMob reports an earned reward; delivery does not wait for dismissal.
/// - `onDismiss`: The ad closed. Dismissal does not indicate whether a reward was earned
///   and does not prevent a later reward callback.
/// - `onPresentationFailed`: No presentation controller is attached to the prompt's window,
///   or AdMob failed to present the ad. Delivery is deferred until after `accept()` returns.
///
/// Reward callbacks may arrive before or after dismissal, including for mediated ads.
/// Closing without earning a reward invokes only `onDismiss`. Accepted presentations retain
/// their callbacks even if the prompt is removed or updated.
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
    ///   - onVerificationCompleted: Handles the RevenueCat verification outcome, including failures,
    ///     independently of dismissal.
    ///   - onDismiss: Optional notification that the ad closed. A reward callback can still arrive later.
    ///   - onPresentationFailed: Optional presentation-error handler, deferred until after `accept()` returns.
    ///   - content: Offer content, with optional reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedAd,
        placement: String? = nil,
        onVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void,
        onDismiss: (@MainActor () -> Void)? = nil,
        onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)? = nil,
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
    ///   - onVerificationCompleted: Handles the RevenueCat verification outcome, including failures,
    ///     independently of dismissal.
    ///   - onDismiss: Optional notification that the ad closed. A reward callback can still arrive later.
    ///   - onPresentationFailed: Optional presentation-error handler, deferred until after `accept()` returns.
    ///   - content: Offer content, with optional reward configuration.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedInterstitialAd,
        placement: String? = nil,
        onVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void,
        onDismiss: (@MainActor () -> Void)? = nil,
        onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)? = nil,
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
