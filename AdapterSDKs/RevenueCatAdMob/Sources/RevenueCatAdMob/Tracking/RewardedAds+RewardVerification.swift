//
//  RewardedAds+RewardVerification.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat

@available(iOS 15.0, *)
internal extension Tracking {

    @MainActor
    static func applyRewardVerificationPlacementOverride(
        _ placementOverride: RewardVerificationPlacementOverride,
        on fullScreenAd: AnyObject
    ) {
        if let trackingDelegate = Tracking.Adapter.shared.fullScreenDelegateStore.retrieve(for: fullScreenAd) {
            trackingDelegate.placement = RewardVerificationPlacementResolver.resolvedPlacement(
                currentPlacement: trackingDelegate.placement,
                override: placementOverride
            )
        }
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedAd {

    /// Configures RevenueCat reward verification for this ad (SSV payload + per-ad state).
    ///
    /// Call after the ad has loaded and before presenting it when you will use reward-verification APIs.
    /// If the RevenueCat SDK is not configured, this method does nothing.
    @MainActor
    func enableRewardVerification() {
        RewardVerification.Setup.install(on: self)
    }

    /// Presents the ad with optional reward-verification callbacks.
    ///
    /// When `rewardVerificationResult` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (enforced with a runtime precondition).
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationResult:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        Tracking.applyRewardVerificationPlacementOverride(
            .keepLoadTimePlacement,
            on: self
        )
        RewardVerification.Present.present(
            capableAd: self,
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult,
            performPresent: { wrapped in
                self.present(from: viewController, userDidEarnRewardHandler: wrapped)
            }
        )
    }

    /// Presents the ad with optional reward-verification callbacks and an explicit placement for RevenueCat analytics.
    ///
    /// The placement passed here takes precedence over any placement from
    /// ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:)``.
    /// When `rewardVerificationResult` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (enforced with a runtime precondition).
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        Tracking.applyRewardVerificationPlacementOverride(
            .override(placement),
            on: self
        )
        RewardVerification.Present.present(
            capableAd: self,
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult,
            performPresent: { wrapped in
                self.present(from: viewController, userDidEarnRewardHandler: wrapped)
            }
        )
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedInterstitialAd {

    /// Configures RevenueCat reward verification for this ad (SSV payload + per-ad state).
    ///
    /// Call after the ad has loaded and before presenting it when you will use reward-verification APIs.
    /// If the RevenueCat SDK is not configured, this method does nothing.
    @MainActor
    func enableRewardVerification() {
        RewardVerification.Setup.install(on: self)
    }

    /// Presents the ad with optional reward-verification callbacks.
    ///
    /// When `rewardVerificationResult` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (enforced with a runtime precondition).
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationResult:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        Tracking.applyRewardVerificationPlacementOverride(
            .keepLoadTimePlacement,
            on: self
        )
        RewardVerification.Present.present(
            capableAd: self,
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult,
            performPresent: { wrapped in
                self.present(from: viewController, userDidEarnRewardHandler: wrapped)
            }
        )
    }

    /// Presents the ad with optional reward-verification callbacks and an explicit placement for RevenueCat analytics.
    ///
    /// The placement passed here takes precedence over any placement from
    /// ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:)``.
    /// When `rewardVerificationResult` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (enforced with a runtime precondition).
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        Tracking.applyRewardVerificationPlacementOverride(
            .override(placement),
            on: self
        )
        RewardVerification.Present.present(
            capableAd: self,
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult,
            performPresent: { wrapped in
                self.present(from: viewController, userDidEarnRewardHandler: wrapped)
            }
        )
    }
}

#endif
