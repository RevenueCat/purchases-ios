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
    /// To override the placement used for RevenueCat analytics at show time, use the
    /// `placement:` variant of `presentAndTrack(from:...)` instead.
    @MainActor
    func presentAndTrack(
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
    func presentAndTrack(
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
    /// To override the placement used for RevenueCat analytics at show time, use the
    /// `placement:` variant of `presentAndTrack(from:...)` instead.
    @MainActor
    func presentAndTrack(
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
    func presentAndTrack(
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

    /// Returns the handler used by GoogleMobileAds `present` APIs while optionally dispatching
    /// RevenueCat reward-verification polling results.
    ///
    /// - Parameter poller: For unit tests; pass `nil` in production to use ``RewardVerification.Poller/makeDefault()``.
    /// - Parameter tracker: For unit tests; defaults to the shared adapter tracker.
    @MainActor
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func createUserDidEarnRewardHandler(
        rewardVerificationStarted: (@MainActor () -> Void)?,
        rewardVerificationCompleted: (@MainActor (RewardVerificationResult) -> Void)?,
        poller: RewardVerification.Poller? = nil,
        tracker: Tracking.Tracker = Tracking.Adapter.shared.tracker,
        invalidateVirtualCurrenciesCache: @escaping @MainActor () -> Void
            = RewardVerification.SideEffects.invalidateVirtualCurrenciesCacheIfConfigured
    ) -> (() -> Void) {
        let state = RewardVerification.Setup.verificationState(for: self)

        if rewardVerificationCompleted != nil, state == nil {
            Logger.warn(RewardVerificationStrings.result_callback_missing_verification_state)
            assert(
                state != nil,
                RewardVerificationStrings.result_callback_requires_enable.description
            )
        }

        let rewardVerificationEnabled = (state != nil)

        return { [weak self] in
            guard let self else { return }
            let impressionId = state?.impressionId ?? self.impressionId
            self.fireEarnedUnverifiedEvent(
                tracker: tracker,
                impressionId: impressionId,
                rewardVerificationEnabled: rewardVerificationEnabled
            )

            rewardVerificationStarted?()

            guard let rewardVerificationCompleted else {
                return
            }

            guard let state else {
                rewardVerificationCompleted(.failed)
                return
            }

            let networkName = self.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName
            let placement = Tracking.Adapter.shared.fullScreenDelegateStore.retrieve(for: self)?.placement
            let adFormat = self.rewardedAdFormat
            let adUnitId = self.adUnitID
            let resolvedPoller = poller ?? .makeDefault()
            RewardVerification.Dispatcher.dispatch(
                clientTransactionID: state.clientTransactionID,
                state: state,
                poller: resolvedPoller,
                outcomeHandler: { internalOutcome in
                    if tracker.isConfigured {
                        switch internalOutcome {
                        case .verified(let reward):
                            tracker.trackAdRewardVerified(.init(
                                networkName: networkName,
                                mediatorName: .adMob,
                                adFormat: adFormat,
                                placement: placement,
                                adUnitId: adUnitId,
                                impressionId: impressionId,
                                reward: reward
                            ))
                        case .failed(let reason):
                            let failureReason: RevenueCat.AdRewardFailureReason
                            switch reason {
                            case .timeout: failureReason = .timeout
                            case .backendError: failureReason = .backendError
                            case .unknown: failureReason = .unknown
                            }
                            tracker.trackAdRewardFailedToVerify(.init(
                                networkName: networkName,
                                mediatorName: .adMob,
                                adFormat: adFormat,
                                placement: placement,
                                adUnitId: adUnitId,
                                impressionId: impressionId,
                                failureReason: failureReason
                            ))
                        }
                    }
                    if case .verified(let reward) = internalOutcome, reward.virtualCurrency != nil {
                        invalidateVirtualCurrenciesCache()
                    }
                    rewardVerificationCompleted(RewardVerification.mapOutcome(internalOutcome))
                }
            )
        }
    }
}

// MARK: - Internal outcome -> presentation result

@available(iOS 15.0, *)
internal extension RewardVerification {

    static func mapOutcome(_ outcome: Outcome) -> RewardVerificationResult {
        switch outcome {
        case .verified(let reward):
            return .verified(reward)
        case .failed:
            return .failed
        }
    }
}

#endif
