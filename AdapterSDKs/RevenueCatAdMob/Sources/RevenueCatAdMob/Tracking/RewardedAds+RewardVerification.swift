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
    /// When `rewardVerificationOutcome` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (enforced with a runtime precondition).
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String? = nil,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationOutcome: ((RewardVerificationOutcome) -> Void)? = nil
    ) {
        Tracking.Adapter.shared.fullScreenDelegateStore.retrieve(for: self)?.placement = placement
        RewardVerification.Present.present(
            capableAd: self,
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationOutcome: rewardVerificationOutcome,
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
    /// When `rewardVerificationOutcome` is non-`nil`, you must call ``enableRewardVerification()`` first
    /// (enforced with a runtime precondition).
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String? = nil,
        rewardVerificationStarted: (() -> Void)? = nil,
        rewardVerificationOutcome: ((RewardVerificationOutcome) -> Void)? = nil
    ) {
        Tracking.Adapter.shared.fullScreenDelegateStore.retrieve(for: self)?.placement = placement
        RewardVerification.Present.present(
            capableAd: self,
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationOutcome: rewardVerificationOutcome,
            performPresent: { wrapped in
                self.present(from: viewController, userDidEarnRewardHandler: wrapped)
            }
        )
    }
}

#endif
