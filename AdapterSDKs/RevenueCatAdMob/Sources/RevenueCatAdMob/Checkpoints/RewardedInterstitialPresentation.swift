//
//  RewardedInterstitialPresentation.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import UIKit

/// The subset of `GoogleMobileAds.RewardedInterstitialAd` the presentation needs, so tests can substitute a fake.
@available(iOS 15.0, *)
internal protocol RewardedInterstitialPresentableAd: AnyObject {

    @MainActor
    func enableRewardVerification()

    @MainActor
    func presentRewardedInterstitial(
        from viewController: UIViewController,
        rewardVerificationStarted: @escaping @MainActor () -> Void,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    )

}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RewardedInterstitialPresentableAd {

    func presentRewardedInterstitial(
        from viewController: UIViewController,
        rewardVerificationStarted: @escaping @MainActor () -> Void,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        self.present(
            from: viewController,
            rewardVerificationStarted: rewardVerificationStarted,
            rewardVerificationCompleted: rewardVerificationCompleted
        )
    }

}

/// Errors produced by ``AdMobRewardedInterstitialPresenter`` itself, as opposed to errors forwarded from AdMob.
@available(iOS 15.0, *)
internal enum RewardedInterstitialPresentationError: Error, CustomNSError {

    case unsupportedMediator(String)
    case noPresentationContext

    static let errorDomain = "RevenueCatAdMob.RewardedInterstitialPresentationError"

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
            return "AdMobRewardedInterstitialPresenter only presents AdMob ad units, but the checkpoint ad step " +
                "is configured for mediator '\(mediator)'."
        case .noPresentationContext:
            return "No view controller is available to present the rewarded interstitial ad from."
        }
    }

}

/// One checkpoint ad step: loads a rewarded interstitial ad, presents it with reward verification enabled, and
/// reports a single terminal outcome.
///
/// AdMob reports the earned reward while the ad is still on screen, and verification polling usually
/// outlives the dismissal. The outcome is therefore reported only once the ad is dismissed *and*, if
/// verification started, its result has arrived — so the checkpoint never resolves underneath a visible ad
/// and never resolves as merely ``Outcome/shown`` while a reward is still being verified.
@available(iOS 15.0, *)
@MainActor
internal final class RewardedInterstitialPresentation: NSObject, GoogleMobileAds.FullScreenContentDelegate {

    enum Outcome {

        case shown
        case rewarded(RevenueCat.AdReward, moreRewards: [RevenueCat.AdReward])
        case rewardVerificationFailed
        case failed(NSError)

        @MainActor
        var presentationResult: AdPresentationResult {
            switch self {
            case .shown:
                return .shown
            case let .rewarded(reward, moreRewards):
                return .rewarded(reward: reward, moreRewards: moreRewards)
            case .rewardVerificationFailed:
                return .rewardVerificationFailed
            case let .failed(error):
                return .failed(error: error)
            }
        }

    }

    typealias LoadAd = @MainActor (
        _ adUnitID: String,
        _ placement: String,
        _ delegate: GoogleMobileAds.FullScreenContentDelegate
    ) async throws -> any RewardedInterstitialPresentableAd

    typealias PresentingViewControllerProvider = @MainActor () -> UIViewController?

    private let loadAd: LoadAd
    private let presentingViewControllerProvider: PresentingViewControllerProvider
    private var completion: (@MainActor (Outcome) -> Void)?
    /// AdMob does not retain a presented rewarded interstitial ad on the caller's behalf.
    private var loadedAd: (any RewardedInterstitialPresentableAd)?
    private var adUnitID: String?

    private var isDismissed = false
    private var isAwaitingVerification = false
    private var verificationResult: RewardVerificationResult?

    init(
        loadAd: @escaping LoadAd = RewardedInterstitialPresentation.loadAndTrackRewardedInterstitial,
        presentingViewControllerProvider: @escaping PresentingViewControllerProvider
            = RewardedInterstitialPresentation.currentViewController
    ) {
        self.loadAd = loadAd
        self.presentingViewControllerProvider = presentingViewControllerProvider
    }

    func start(
        adUnitID: String,
        mediator: MediatorName,
        placement: String,
        completion: @escaping @MainActor (Outcome) -> Void
    ) {
        self.completion = completion
        self.adUnitID = adUnitID

        guard mediator == .adMob else {
            Logger.warn(
                CheckpointPresenterStrings.rewarded_interstitial_unsupported_mediator(mediator: mediator.rawValue)
            )
            self.finish(
                .failed(RewardedInterstitialPresentationError.unsupportedMediator(mediator.rawValue) as NSError)
            )
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let loadedAd: any RewardedInterstitialPresentableAd
            do {
                loadedAd = try await self.loadAd(adUnitID, placement, self)
            } catch {
                Logger.warn(
                    CheckpointPresenterStrings.rewarded_interstitial_load_failed(adUnitID: adUnitID, error: error)
                )
                self.finish(.failed(error as NSError))
                return
            }

            guard let viewController = self.presentingViewControllerProvider() else {
                Logger.warn(CheckpointPresenterStrings.rewarded_interstitial_no_presentation_context)
                self.finish(.failed(RewardedInterstitialPresentationError.noPresentationContext as NSError))
                return
            }

            self.loadedAd = loadedAd
            loadedAd.enableRewardVerification()
            loadedAd.presentRewardedInterstitial(
                from: viewController,
                rewardVerificationStarted: { [weak self] in
                    self?.isAwaitingVerification = true
                },
                rewardVerificationCompleted: { [weak self] result in
                    self?.verificationResult = result
                    self?.finishIfSettled()
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
        Logger.warn(CheckpointPresenterStrings.rewarded_interstitial_present_failed(error: error))
        self.finish(.failed(error as NSError))
    }

    // MARK: -

    private func finishIfSettled() {
        guard self.isDismissed else { return }

        guard self.isAwaitingVerification else {
            self.finish(.shown)
            return
        }

        guard let result = self.verificationResult else { return }

        if let reward = result.verifiedReward {
            self.finish(.rewarded(reward, moreRewards: result.moreRewards))
        } else {
            Logger.warn(
                CheckpointPresenterStrings.rewarded_interstitial_verification_failed(adUnitID: self.adUnitID ?? "")
            )
            self.finish(.rewardVerificationFailed)
        }
    }

    private func finish(_ outcome: Outcome) {
        guard let completion = self.completion else { return }
        self.completion = nil
        self.loadedAd = nil
        completion(outcome)
    }

    private static func loadAndTrackRewardedInterstitial(
        adUnitID: String,
        placement: String,
        delegate: GoogleMobileAds.FullScreenContentDelegate
    ) async throws -> any RewardedInterstitialPresentableAd {
        try await GoogleMobileAds.RewardedInterstitialAd.loadAndTrack(
            withAdUnitID: adUnitID,
            request: GoogleMobileAds.Request(),
            placement: placement,
            fullScreenContentDelegate: delegate
        )
    }

    private static func currentViewController() -> UIViewController? {
        let application = UIApplication.value(forKey: "sharedApplication") as? UIApplication
        return application?.currentPresentationViewController
    }

}

#endif
