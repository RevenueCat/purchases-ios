//
//  RewardedPresentation.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) import RevenueCatUI
import UIKit

/// The subset of `GoogleMobileAds.RewardedAd` / `RewardedInterstitialAd` the presentation needs, so tests
/// can substitute a fake. Both AdMob types already expose the reward verification methods with matching
/// signatures through `RewardedAds+RewardVerification.swift`.
@available(iOS 15.0, *)
internal protocol RewardedPresentableAd: AnyObject {

    @MainActor
    func enableRewardVerification()

    @MainActor
    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)?,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    )

    /// Presents the ad without RevenueCat reward verification, reporting when AdMob gives the reward on the device.
    @MainActor
    func presentWithoutRewardVerification(
        from viewController: UIViewController,
        userDidEarnReward: @escaping @MainActor () -> Void
    )

}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RewardedPresentableAd {

    @MainActor
    func presentWithoutRewardVerification(
        from viewController: UIViewController,
        userDidEarnReward: @escaping @MainActor () -> Void
    ) {
        self.present(from: viewController, userDidEarnRewardHandler: {
            Tracking.Adapter.shared.trackRewardEarnedWithoutVerification(for: self)
            userDidEarnReward()
        })
    }

}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RewardedPresentableAd {

    @MainActor
    func presentWithoutRewardVerification(
        from viewController: UIViewController,
        userDidEarnReward: @escaping @MainActor () -> Void
    ) {
        self.present(from: viewController, userDidEarnRewardHandler: {
            Tracking.Adapter.shared.trackRewardEarnedWithoutVerification(for: self)
            userDidEarnReward()
        })
    }

}

/// Errors produced by ``RewardedPresentation`` itself, as opposed to errors forwarded from AdMob.
@available(iOS 15.0, *)
internal enum RewardedPresentationError: Error, CustomNSError {

    case unsupportedMediator(String)
    case noPresentationContext

    static let errorDomain = "RevenueCatAdMob.RewardedPresentationError"

    var errorCode: Int {
        switch self {
        case .unsupportedMediator: return 1
        case .noPresentationContext: return 2
        }
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    var localizedDescription: String {
        switch self {
        case let .unsupportedMediator(mediator):
            return "AdMob checkpoint presenters only present AdMob ad units, but the checkpoint ad step " +
                "is configured for mediator '\(mediator)'."
        case .noPresentationContext:
            return "No view controller is available to present the rewarded ad from."
        }
    }

}

/// One checkpoint ad step: loads a rewarded or rewarded interstitial ad, presents it with or without reward
/// verification, and reports a single terminal outcome.
///
/// AdMob reports the earned reward while the ad is still on screen, and verification polling usually
/// outlives the dismissal. The outcome is therefore reported only once the ad is dismissed *and*, if
/// verification started, its result has arrived — so the checkpoint never resolves underneath a visible ad
/// and never resolves while a reward is still being verified.
///
/// The checkpoint passes only on an earned reward: one RevenueCat verified or, without reward verification,
/// one AdMob reported on the device, for which RevenueCat grants nothing. Closing the ad early, or a reward that
/// fails verification, keeps the customer in front of the checkpoint like a dismissed paywall would.
@available(iOS 15.0, *)
@MainActor
internal final class RewardedPresentation: NSObject, GoogleMobileAds.FullScreenContentDelegate {

    /// AdMob ad units are format-locked, so the format decides which `loadAndTrack` entry point is used.
    enum Format {

        case rewarded
        case rewardedInterstitial

        var adFormat: RevenueCat.AdFormat {
            switch self {
            case .rewarded: return .rewarded
            case .rewardedInterstitial: return .rewardedInterstitial
            }
        }

        fileprivate var defaultLoadAd: LoadAd {
            switch self {
            case .rewarded: return RewardedPresentation.loadAndTrackRewarded
            case .rewardedInterstitial: return RewardedPresentation.loadAndTrackRewardedInterstitial
            }
        }

    }

    enum Outcome {

        case shown
        case rewardNotEarned
        case failed(NSError)

        /// A verified reward reaches the app through the refreshed customer info. A reward that failed
        /// verification is logged and gates like an unearned one: the ad was shown, so it is not an error to
        /// present, but nothing was granted, so the checkpoint must not pass.
        @MainActor
        var presentationResult: AdPresentationResult {
            switch self {
            case .shown:
                return .shown
            case .rewardNotEarned:
                return .rewardNotEarned
            case let .failed(error):
                return .failed(error: error)
            }
        }

    }

    typealias LoadAd = @MainActor (
        _ adUnitID: String,
        _ placement: String,
        _ delegate: GoogleMobileAds.FullScreenContentDelegate
    ) async throws -> any RewardedPresentableAd

    typealias PresentingViewControllerProvider = @MainActor () -> UIViewController?

    private let format: Format
    private let loadAd: LoadAd
    private let presentingViewControllerProvider: PresentingViewControllerProvider
    private var completion: (@MainActor (Outcome) -> Void)?
    /// AdMob does not retain a presented rewarded ad on the caller's behalf.
    private var loadedAd: (any RewardedPresentableAd)?

    private var isDismissed = false
    private var isAwaitingVerification = false
    private var isVerificationSettled = false
    private var isRewardEarned = false

    init(
        format: Format,
        loadAd: LoadAd? = nil,
        presentingViewControllerProvider: @escaping PresentingViewControllerProvider
            = RewardedPresentation.currentViewController
    ) {
        self.format = format
        self.loadAd = loadAd ?? format.defaultLoadAd
        self.presentingViewControllerProvider = presentingViewControllerProvider
    }

    func start(
        adUnitID: String,
        mediator: MediatorName,
        placement: String,
        rewardVerificationEnabled: Bool,
        completion: @escaping @MainActor (Outcome) -> Void
    ) {
        self.completion = completion

        guard mediator == .adMob else {
            Logger.warn(CheckpointPresenterStrings.rewarded_unsupported_mediator(
                adFormat: self.format.adFormat,
                mediator: mediator.rawValue
            ))
            self.finish(.failed(RewardedPresentationError.unsupportedMediator(mediator.rawValue) as NSError))
            return
        }

        Task { @MainActor in
            let loadedAd: any RewardedPresentableAd
            do {
                loadedAd = try await self.loadAd(adUnitID, placement, self)
            } catch {
                Logger.warn(CheckpointPresenterStrings.rewarded_load_failed(
                    adFormat: self.format.adFormat,
                    adUnitID: adUnitID,
                    error: error
                ))
                self.finish(.failed(error as NSError))
                return
            }

            guard let viewController = self.presentingViewControllerProvider() else {
                Logger.warn(
                    CheckpointPresenterStrings.rewarded_no_presentation_context(adFormat: self.format.adFormat)
                )
                self.finish(.failed(RewardedPresentationError.noPresentationContext as NSError))
                return
            }

            self.loadedAd = loadedAd
            if rewardVerificationEnabled {
                self.presentWithRewardVerification(loadedAd, from: viewController, adUnitID: adUnitID)
            } else {
                loadedAd.presentWithoutRewardVerification(from: viewController) { [weak self] in
                    self?.isRewardEarned = true
                }
            }
        }
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.isDismissed = true
        self.finishIfSettled()
    }

    func ad(
        _ presentingAd: any GoogleMobileAds.FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        Logger.warn(
            CheckpointPresenterStrings.rewarded_present_failed(adFormat: self.format.adFormat, error: error)
        )
        self.finish(.failed(error as NSError))
    }

    // MARK: -

    private func presentWithRewardVerification(
        _ loadedAd: any RewardedPresentableAd,
        from viewController: UIViewController,
        adUnitID: String
    ) {
        loadedAd.enableRewardVerification()
        loadedAd.present(
            from: viewController,
            rewardVerificationStarted: { [weak self] in
                self?.isAwaitingVerification = true
            },
            rewardVerificationCompleted: { [weak self] result in
                guard let self else { return }
                if result.verifiedReward == nil {
                    Logger.warn(CheckpointPresenterStrings.rewarded_verification_failed(
                        adFormat: self.format.adFormat,
                        adUnitID: adUnitID
                    ))
                }
                // Non-nil means verification succeeded; a verified result with nothing granted
                // still passes, like client-reported mode.
                self.isRewardEarned = result.verifiedReward != nil
                self.isVerificationSettled = true
                self.finishIfSettled()
            }
        )
    }

    private func finishIfSettled() {
        guard self.isDismissed else { return }

        guard !self.isAwaitingVerification || self.isVerificationSettled else { return }

        self.finish(self.isRewardEarned ? .shown : .rewardNotEarned)
    }

    private func finish(_ outcome: Outcome) {
        guard let completion = self.completion else { return }
        self.completion = nil
        self.loadedAd = nil
        completion(outcome)
    }

    private static func loadAndTrackRewarded(
        adUnitID: String,
        placement: String,
        delegate: GoogleMobileAds.FullScreenContentDelegate
    ) async throws -> any RewardedPresentableAd {
        try await GoogleMobileAds.RewardedAd.loadAndTrack(
            withAdUnitID: adUnitID,
            request: GoogleMobileAds.Request(),
            placement: placement,
            fullScreenContentDelegate: delegate
        )
    }

    private static func loadAndTrackRewardedInterstitial(
        adUnitID: String,
        placement: String,
        delegate: GoogleMobileAds.FullScreenContentDelegate
    ) async throws -> any RewardedPresentableAd {
        try await GoogleMobileAds.RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: adUnitID,
            request: GoogleMobileAds.Request(),
            placement: placement,
            fullScreenContentDelegate: delegate
        )
    }

    private static func currentViewController() -> UIViewController? {
        UIApplication.extensionSafeApplication?.currentPresentationViewController
    }

}

#endif
