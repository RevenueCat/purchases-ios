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
        _ placementOverride: String?,
        on fullScreenAd: AnyObject
    ) {
        if let trackingDelegate = Tracking.Adapter.shared.fullScreenDelegateStore.retrieve(for: fullScreenAd) {
            trackingDelegate.placement = placementOverride
        }
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedAd {

    /// Enables RevenueCat reward verification for this ad.
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
    /// (checked with a debug assertion).
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationResult:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult
        )
        self.present(
            from: viewController,
            userDidEarnRewardHandler: userDidEarnRewardHandler
        )
    }

    /// Presents the ad with optional reward-verification callbacks and an explicit placement for RevenueCat analytics.
    ///
    /// The placement passed here takes precedence over any placement from
    /// ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:)``.
    /// When `rewardVerificationResult` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (checked with a debug assertion).
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        Tracking.applyRewardVerificationPlacementOverride(
            placement,
            on: self
        )
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult
        )
        self.present(
            from: viewController,
            userDidEarnRewardHandler: userDidEarnRewardHandler
        )
    }
}

@available(iOS 15.0, *)
@_spi(Experimental) public extension GoogleMobileAds.RewardedInterstitialAd {

    /// Enables RevenueCat reward verification for this ad.
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
    /// (checked with a debug assertion).
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationResult:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult
        )
        self.present(
            from: viewController,
            userDidEarnRewardHandler: userDidEarnRewardHandler
        )
    }

    /// Presents the ad with optional reward-verification callbacks and an explicit placement for RevenueCat analytics.
    ///
    /// The placement passed here takes precedence over any placement from
    /// ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:)``.
    /// When `rewardVerificationResult` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (checked with a debug assertion).
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)? = nil
    ) {
        Tracking.applyRewardVerificationPlacementOverride(
            placement,
            on: self
        )
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationResult: rewardVerificationResult
        )
        self.present(
            from: viewController,
            userDidEarnRewardHandler: userDidEarnRewardHandler
        )
    }
}

@available(iOS 15.0, *)
internal extension RewardVerification.CapableAd {

    /// Returns the handler used by GoogleMobileAds `present` APIs while optionally dispatching
    /// RevenueCat reward-verification polling results.
    ///
    /// - Parameter poller: For unit tests; pass `nil` in production to use ``RewardVerification.Poller/makeDefault()``.
    @MainActor
    func createUserDidEarnRewardHandler(
        rewardVerificationStarted: (() -> Void)?,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)?,
        poller: RewardVerification.Poller? = nil
    ) -> (() -> Void) {
        if rewardVerificationResult != nil {
            assert(
                RewardVerification.Setup.verificationState(for: self) != nil,
                Strings.rewardVerificationResultRequiresEnable
            )
        }

        guard let state = RewardVerification.Setup.verificationState(for: self),
              let onResult = rewardVerificationResult else {
            return { rewardVerificationStarted?() }
        }

        let resolvedPoller = poller ?? .makeDefault()

        return {
            rewardVerificationStarted?()
            RewardVerification.Dispatcher.dispatch(
                clientTransactionID: state.clientTransactionID,
                state: state,
                poller: resolvedPoller,
                outcomeHandler: { internalOutcome in
                    onResult(RewardVerification.mapOutcome(internalOutcome))
                }
            )
        }
    }
}

#endif
