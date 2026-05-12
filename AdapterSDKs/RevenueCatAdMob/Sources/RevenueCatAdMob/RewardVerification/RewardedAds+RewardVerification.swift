//
//  RewardedAds+RewardVerification.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat

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

    /// Presents the ad with a required reward-verification result callback.
    ///
    /// You must call ``enableRewardVerification()`` before presenting
    /// (checked with a debug assertion).
    ///
    /// Callback timing:
    /// - `rewardVerificationStarted` runs when the AdMob SDK invokes the reward callback and verification begins.
    /// - `rewardVerificationResult` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationResult:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationResult: @escaping @MainActor (RewardVerificationResult) -> Void
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

    /// Presents the ad with a required reward-verification result callback
    /// and an explicit placement for RevenueCat analytics.
    ///
    /// The placement passed here takes precedence over any placement from
    /// ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:)``.
    /// You must call ``enableRewardVerification()`` before presenting
    /// (checked with a debug assertion).
    ///
    /// Callback timing:
    /// - `rewardVerificationStarted` runs when the AdMob SDK invokes the reward callback and verification begins.
    /// - `rewardVerificationResult` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationResult: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        Tracking.setShowTimePlacement(placement, on: self)
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

    /// Presents the ad with a required reward-verification result callback.
    ///
    /// You must call ``enableRewardVerification()`` before presenting
    /// (checked with a debug assertion).
    ///
    /// Callback timing:
    /// - `rewardVerificationStarted` runs when the AdMob SDK invokes the reward callback and verification begins.
    /// - `rewardVerificationResult` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationResult:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationResult: @escaping @MainActor (RewardVerificationResult) -> Void
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

    /// Presents the ad with a required reward-verification result callback
    /// and an explicit placement for RevenueCat analytics.
    ///
    /// The placement passed here takes precedence over any placement from
    /// ``loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:paidEventHandler:)``.
    /// You must call ``enableRewardVerification()`` before presenting
    /// (checked with a debug assertion).
    ///
    /// Callback timing:
    /// - `rewardVerificationStarted` runs when the AdMob SDK invokes the reward callback and verification begins.
    /// - `rewardVerificationResult` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationResult: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        Tracking.setShowTimePlacement(placement, on: self)
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
        rewardVerificationStarted: (@MainActor () -> Void)?,
        rewardVerificationResult: (@MainActor (RewardVerificationResult) -> Void)?,
        poller: RewardVerification.Poller? = nil
        invalidateVirtualCurrenciesCache: @escaping @MainActor () -> Void
            = RewardVerification.SideEffects.invalidateVirtualCurrenciesCacheIfConfigured
    ) -> (() -> Void) {
        let state = RewardVerification.Setup.verificationState(for: self)

        if rewardVerificationResult != nil, state == nil {
            Logger.warn(RewardVerificationStrings.result_callback_missing_verification_state)
            assert(
                state != nil,
                RewardVerificationStrings.result_callback_requires_enable.description
            )
        }

        return {
            rewardVerificationStarted?()

            guard let rewardVerificationResult else {
                return
            }

            guard let state else {
                rewardVerificationResult(.failed)
                return
            }

            let resolvedPoller = poller ?? .makeDefault()
            RewardVerification.Dispatcher.dispatch(
                clientTransactionID: state.clientTransactionID,
                state: state,
                poller: resolvedPoller,
                outcomeHandler: { internalOutcome in
                    if case .verified(.virtualCurrency) = internalOutcome {
                        invalidateVirtualCurrenciesCache()
                    }
                    rewardVerificationResult(RewardVerification.mapOutcome(internalOutcome))
                }
            )
        }
    }
}

// MARK: - Internal outcome -> presentation result

@available(iOS 15.0, *)
internal extension RewardVerification {
    static func mapVerifiedReward(_ reward: RevenueCat.VerifiedReward) -> RevenueCatAdMob.VerifiedReward {
        switch reward {
        case .virtualCurrency(let item):
            return .virtualCurrency(code: item.code, amount: item.amount)
        case .noReward:
            return .noReward
        case .unsupportedReward:
            return .unsupportedReward
        }
    }

    static func mapOutcome(_ outcome: Outcome) -> RewardVerificationResult {
        switch outcome {
        case .verified(let reward):
            return .verified(self.mapVerifiedReward(reward))
        case .failed:
            return .failed
        }
    }
}

#endif
