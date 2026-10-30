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
/// can substitute a fake. Both AdMob types already expose these methods with matching signatures through
/// `RewardedAds+RewardVerification.swift`.
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

}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RewardedPresentableAd {}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RewardedPresentableAd {}

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

/// One checkpoint ad step: loads a rewarded or rewarded interstitial ad, presents it with reward
/// verification enabled, and reports a single terminal outcome.
///
/// AdMob reports the earned reward while the ad is still on screen, and verification polling usually
/// outlives the dismissal. The outcome is therefore reported only once the ad is dismissed *and*, if
/// verification started, its result has arrived — so the checkpoint never resolves underneath a visible ad
/// and never resolves while a reward is still being verified.
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
        case failed(NSError)

        /// A verified reward reaches the app through the refreshed customer info. A reward that failed
        /// verification is only logged: the customer watched the ad in full, so the checkpoint still passes
        /// rather than presenting an error for an ad that was shown.
        @MainActor
        var presentationResult: AdPresentationResult {
            switch self {
            case .shown:
                return .shown
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
                    self.isVerificationSettled = true
                    self.finishIfSettled()
                }
            )
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

    private func finishIfSettled() {
        guard self.isDismissed else { return }

        guard !self.isAwaitingVerification || self.isVerificationSettled else { return }

        self.finish(.shown)
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
