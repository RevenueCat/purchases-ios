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
/// After acceptance, callbacks run on the main actor, each at most once per presentation:
///
/// - `onRewardEarned`: AdMob reported an earned reward. The app grants the reward;
///   delivery does not wait for dismissal.
/// - `onDismiss`: The ad closed. Dismissal does not indicate whether a reward was earned
///   and does not prevent a later reward callback.
/// - `onPresentationFailed`: No presentation controller is attached to the prompt's window,
///   or AdMob failed to present the ad. Delivery is deferred until after `accept()` returns.
///
/// Reward callbacks may arrive before or after dismissal, including for mediated ads.
/// Closing without earning a reward invokes only `onDismiss`. Accepted presentations retain
/// their callbacks even if the prompt is removed or updated.
///
/// For example, given an ad preloaded with `loadAndTrack` and an app-defined `retryLevel()` action:
///
/// ```swift
/// RewardedAdPromptWithoutVerification(
///     ad: loadedAd,
///     onRewardEarned: {
///         retryLevel()
///     }
/// ) { context in
///     Button("Watch an ad to retry the level", action: context.accept)
/// }
/// ```
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
    ///   - onRewardEarned: Grants the app-defined reward when AdMob reports it was earned,
    ///     independently of dismissal.
    ///   - onDismiss: Optional notification that the ad closed. A reward callback can still arrive later.
    ///   - onPresentationFailed: Optional presentation-error handler, deferred until after `accept()` returns.
    ///   - content: App-defined offer content, with an action to accept the offer.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedAd,
        placement: String? = nil,
        onRewardEarned: @escaping @MainActor () -> Void,
        onDismiss: (@MainActor () -> Void)? = nil,
        onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)? = nil,
        @ViewBuilder content: @escaping (RewardedAdPromptUnverifiedContext) -> Content
    ) {
        self.prompt = .init(
            session: session,
            rewardedAd: rewardedAd,
            placement: placement,
            loadsRewardConfiguration: false,
            callbackDispatcherFactory: {
                UnverifiedRewardCallbackDispatcher(
                    onRewardEarned: onRewardEarned,
                    onDismiss: onDismiss,
                    onPresentationFailed: onPresentationFailed
                )
            },
            content: { context in
                content(RewardedAdPromptUnverifiedContext(acceptAction: context.accept))
            }
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
    ///   - onRewardEarned: Grants the app-defined reward when AdMob reports it was earned,
    ///     independently of dismissal.
    ///   - onDismiss: Optional notification that the ad closed. A reward callback can still arrive later.
    ///   - onPresentationFailed: Optional presentation-error handler, deferred until after `accept()` returns.
    ///   - content: App-defined offer content, with an action to accept the offer.
    public init(
        session: RewardedAdPromptSession? = nil,
        ad rewardedAd: GoogleMobileAds.RewardedInterstitialAd,
        placement: String? = nil,
        onRewardEarned: @escaping @MainActor () -> Void,
        onDismiss: (@MainActor () -> Void)? = nil,
        onPresentationFailed: (@MainActor (RewardedAdPromptError) -> Void)? = nil,
        @ViewBuilder content: @escaping (RewardedAdPromptUnverifiedContext) -> Content
    ) {
        self.prompt = .init(
            session: session,
            rewardedAd: rewardedAd,
            placement: placement,
            loadsRewardConfiguration: false,
            callbackDispatcherFactory: {
                UnverifiedRewardCallbackDispatcher(
                    onRewardEarned: onRewardEarned,
                    onDismiss: onDismiss,
                    onPresentationFailed: onPresentationFailed
                )
            },
            content: { context in
                content(RewardedAdPromptUnverifiedContext(acceptAction: context.accept))
            }
        )
    }

    /// The offer content until the prompt is accepted.
    public var body: some View {
        self.prompt
    }

}

#endif
