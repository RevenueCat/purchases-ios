//
//  InterstitialPresentation.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import UIKit

/// The subset of `GoogleMobileAds.InterstitialAd` the presentation needs, so tests can substitute a fake.
@available(iOS 15.0, *)
internal protocol InterstitialPresentableAd: AnyObject {

    @MainActor
    func presentInterstitial(from viewController: UIViewController)

}

@available(iOS 15.0, *)
extension GoogleMobileAds.InterstitialAd: InterstitialPresentableAd {

    func presentInterstitial(from viewController: UIViewController) {
        self.present(from: viewController)
    }

}

/// Errors produced by ``AdMobInterstitialPresenter`` itself, as opposed to errors forwarded from AdMob.
@available(iOS 15.0, *)
internal enum InterstitialPresentationError: Error, CustomNSError {

    case unsupportedMediator(String)
    case noPresentationContext

    static let errorDomain = "RevenueCatAdMob.InterstitialPresentationError"

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
            return "AdMobInterstitialPresenter only presents AdMob ad units, but the checkpoint ad step " +
                "is configured for mediator '\(mediator)'."
        case .noPresentationContext:
            return "No view controller is available to present the interstitial ad from."
        }
    }

}

/// One checkpoint ad step: loads an interstitial, presents it, and reports a single terminal outcome.
///
/// Acts as the `FullScreenContentDelegate` handed to `loadAndTrack`, so the tracking wrapper still
/// reports AdMob events while this object maps the dismissal or presentation failure to an ``Outcome``.
@available(iOS 15.0, *)
@MainActor
internal final class InterstitialPresentation: NSObject, GoogleMobileAds.FullScreenContentDelegate {

    enum Outcome {

        case shown
        case failed(NSError)

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
    ) async throws -> any InterstitialPresentableAd

    typealias PresentingViewControllerProvider = @MainActor () -> UIViewController?

    private let loadAd: LoadAd
    private let presentingViewControllerProvider: PresentingViewControllerProvider
    private var completion: (@MainActor (Outcome) -> Void)?
    /// AdMob does not retain a presented interstitial on the caller's behalf.
    private var loadedAd: (any InterstitialPresentableAd)?

    init(
        loadAd: @escaping LoadAd = InterstitialPresentation.loadAndTrackInterstitial,
        presentingViewControllerProvider: @escaping PresentingViewControllerProvider
            = InterstitialPresentation.currentViewController
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

        guard mediator == .adMob else {
            Logger.warn(CheckpointPresenterStrings.interstitial_unsupported_mediator(mediator: mediator.rawValue))
            self.finish(.failed(InterstitialPresentationError.unsupportedMediator(mediator.rawValue) as NSError))
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let loadedAd: any InterstitialPresentableAd
            do {
                loadedAd = try await self.loadAd(adUnitID, placement, self)
            } catch {
                Logger.warn(CheckpointPresenterStrings.interstitial_load_failed(adUnitID: adUnitID, error: error))
                self.finish(.failed(error as NSError))
                return
            }

            guard let viewController = self.presentingViewControllerProvider() else {
                Logger.warn(CheckpointPresenterStrings.interstitial_no_presentation_context)
                self.finish(.failed(InterstitialPresentationError.noPresentationContext as NSError))
                return
            }

            self.loadedAd = loadedAd
            loadedAd.presentInterstitial(from: viewController)
        }
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.finish(.shown)
    }

    func ad(
        _ presentingAd: any GoogleMobileAds.FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        Logger.warn(CheckpointPresenterStrings.interstitial_present_failed(error: error))
        self.finish(.failed(error as NSError))
    }

    // MARK: -

    private func finish(_ outcome: Outcome) {
        guard let completion = self.completion else { return }
        self.completion = nil
        self.loadedAd = nil
        completion(outcome)
    }

    private static func loadAndTrackInterstitial(
        adUnitID: String,
        placement: String,
        delegate: GoogleMobileAds.FullScreenContentDelegate
    ) async throws -> any InterstitialPresentableAd {
        try await GoogleMobileAds.InterstitialAd.loadAndTrack(
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
