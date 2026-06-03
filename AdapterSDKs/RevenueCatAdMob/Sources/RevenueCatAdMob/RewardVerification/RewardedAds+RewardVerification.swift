//
//  RewardedAds+RewardVerification.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) @_spi(Experimental) import RevenueCat

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
    /// - `rewardVerificationCompleted` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationCompleted:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationCompleted: rewardVerificationCompleted
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
    /// - `rewardVerificationCompleted` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        Tracking.setShowTimePlacement(placement, on: self)
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationCompleted: rewardVerificationCompleted
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
    /// - `rewardVerificationCompleted` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    ///
    /// To override the placement used for RevenueCat analytics at show time, use
    /// ``present(from:placement:rewardVerificationStarted:rewardVerificationCompleted:)`` instead of this method.
    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationCompleted: rewardVerificationCompleted
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
    /// - `rewardVerificationCompleted` runs later with the final verification outcome.
    ///   When verification returns `.verified(.virtualCurrency(...))`, this API automatically invalidates
    ///   RevenueCat virtual currencies cache before delivering the callback.
    @MainActor
    func present(
        from viewController: UIViewController,
        placement: String?,
        rewardVerificationStarted: (@MainActor () -> Void)? = nil,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        Tracking.setShowTimePlacement(placement, on: self)
        let userDidEarnRewardHandler = self.createUserDidEarnRewardHandler(
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationCompleted: rewardVerificationCompleted
        )
        self.present(
            from: viewController,
            userDidEarnRewardHandler: userDidEarnRewardHandler
        )
    }
}

@available(iOS 15.0, *)
internal extension RewardVerification.CapableAd {

    /// Returns the handler used by GoogleMobileAds `present` APIs, delivering the core SDK's
    /// reward-verification result through the one-shot guard on the main actor.
    ///
    /// - Parameter pollRewardVerification: For unit tests; pass `nil` in production to use
    ///   `Purchases.shared.pollRewardVerification(clientTransactionID:)`. Virtual-currency cache
    ///   invalidation happens inside the core call.
    @MainActor
    func createUserDidEarnRewardHandler(
        rewardVerificationStarted: (@MainActor () -> Void)?,
        rewardVerificationCompleted: (@MainActor (RewardVerificationResult) -> Void)?,
        pollRewardVerification: (@Sendable (String) async -> RewardVerificationResult)? = nil
    ) -> (() -> Void) {
        let state = RewardVerification.Setup.verificationState(for: self)

        if rewardVerificationCompleted != nil, state == nil {
            Logger.warn(RewardVerificationStrings.result_callback_missing_verification_state)
            assert(
                state != nil,
                RewardVerificationStrings.result_callback_requires_enable.description
            )
        }

        return {
            rewardVerificationStarted?()

            guard let rewardVerificationCompleted else {
                return
            }

            guard let state else {
                rewardVerificationCompleted(.failed)
                return
            }

            let poll = pollRewardVerification ?? { clientTransactionID in
                await Purchases.shared.pollRewardVerification(clientTransactionID: clientTransactionID)
            }

            RewardVerification.Dispatcher.dispatch(
                clientTransactionID: state.clientTransactionID,
                state: state,
                pollRewardVerification: poll,
                resultHandler: { result in rewardVerificationCompleted(result) }
            )
        }
    }
}

#endif
