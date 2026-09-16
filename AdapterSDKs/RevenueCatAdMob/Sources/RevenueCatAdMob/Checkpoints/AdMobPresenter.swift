//
//  AdMobPresenter.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import UIKit

/// Errors produced by ``AdMobPresenter`` before any format-specific presentation starts.
@available(iOS 15.0, *)
internal enum AdMobPresentationError: Error, CustomNSError {

    case unsupportedFormat(String)

    static let errorDomain = "RevenueCatAdMob.AdMobPresentationError"

    var errorCode: Int {
        switch self {
        case .unsupportedFormat: return 1
        }
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    var localizedDescription: String {
        switch self {
        case let .unsupportedFormat(adFormat):
            return "AdMobPresenter cannot present checkpoint ad steps with ad format '\(adFormat)'. " +
                "Supported formats: interstitial, rewarded, rewarded_interstitial."
        }
    }

}

/// Presents AdMob ads for checkpoint ad steps, choosing the loader that matches each step's ad format.
///
/// Register one instance on `Purchases.shared.adPresenter`. A resolved ad step then loads its ad
/// unit through the matching `loadAndTrack` entry point (so the usual RevenueCat ad events are tracked) and
/// presents it from the topmost view controller. Rewarded formats enable RevenueCat reward verification and
/// complete with `CheckpointAdOutcome.Rewarded` once the reward has been verified server-side.
///
/// AdMob ad units are format-locked, so an ad step whose format this presenter does not implement fails
/// immediately with an error in the `RevenueCatAdMob.AdMobPresentationError` domain rather than being loaded
/// through a loader that would only report a no-fill.
///
/// The checkpoint identifier is used as the tracking placement.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@MainActor
public final class AdMobPresenter: AdPresenter {

    /// Presentations stay alive until they complete: AdMob holds `fullScreenContentDelegate` weakly.
    private var activePresentations: Set<NSObject> = []

    private let makeInterstitialPresentation: @MainActor () -> InterstitialPresentation
    private let makeRewardedPresentation: @MainActor (RewardedPresentation.Format) -> RewardedPresentation

    /// Creates a presenter that loads and shows AdMob ads for checkpoint ad steps.
    public convenience init() {
        self.init(
            makeInterstitialPresentation: { InterstitialPresentation() },
            makeRewardedPresentation: { RewardedPresentation(format: $0) }
        )
    }

    init(
        makeInterstitialPresentation: @escaping @MainActor () -> InterstitialPresentation,
        makeRewardedPresentation: @escaping @MainActor (RewardedPresentation.Format) -> RewardedPresentation
    ) {
        self.makeInterstitialPresentation = makeInterstitialPresentation
        self.makeRewardedPresentation = makeRewardedPresentation
    }

    /// Loads and presents the ad for `params.adIdentifier` using the loader for `params.adFormat`, completing
    /// once the ad is dismissed (and any earned reward verified) or once it fails.
    public func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    ) {
        switch params.adFormat {
        case .interstitial:
            let presentation = self.makeInterstitialPresentation()
            let finish = self.track(presentation, completion: completion)
            presentation.start(
                adUnitID: params.adIdentifier,
                mediator: params.mediator,
                placement: params.checkpointIdentifier
            ) { finish($0.presentationResult) }

        case .rewarded, .rewardedInterstitial:
            let format: RewardedPresentation.Format = params.adFormat == .rewarded ? .rewarded : .rewardedInterstitial
            let presentation = self.makeRewardedPresentation(format)
            let finish = self.track(presentation, completion: completion)
            presentation.start(
                adUnitID: params.adIdentifier,
                mediator: params.mediator,
                placement: params.checkpointIdentifier
            ) { finish($0.presentationResult) }

        default:
            Logger.warn(CheckpointPresenterStrings.unsupported_format(adFormat: params.adFormat.rawValue))
            completion(.failed(error: AdMobPresentationError.unsupportedFormat(params.adFormat.rawValue) as NSError))
        }
    }

    // MARK: -

    private func track(
        _ presentation: NSObject,
        completion: @escaping AdPresentationCompletion
    ) -> @MainActor (AdPresentationResult) -> Void {
        self.activePresentations.insert(presentation)
        return { [weak self, weak presentation] result in
            if let presentation {
                self?.activePresentations.remove(presentation)
            }
            completion(result)
        }
    }

}

#endif
