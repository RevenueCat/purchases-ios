//
//  AdMobInterstitialPresenter.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import UIKit

/// Presents an AdMob interstitial ad when a checkpoint resolves to an ad step.
///
/// Register an instance on `Purchases.shared.adPresenter` so a resolved ad step loads the
/// configured ad unit through `InterstitialAd.loadAndTrack` (so the usual RevenueCat ad events are
/// tracked) and presents it from the topmost view controller.
///
/// The checkpoint identifier is used as the tracking placement. Failures are reported as `NSError`s in
/// the `RevenueCatAdMob.InterstitialPresentationError` domain, or as the underlying AdMob error.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@MainActor
public final class AdMobInterstitialPresenter: AdPresenter {

    /// Presentations stay alive until they complete: AdMob holds `fullScreenContentDelegate` weakly.
    private var activePresentations: Set<InterstitialPresentation> = []

    /// Creates a presenter that loads and shows AdMob interstitials for checkpoint ad steps.
    public init() {}

    /// Loads and presents the interstitial for `params.adIdentifier`, completing once it is dismissed or fails.
    public func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    ) {
        let presentation = InterstitialPresentation()
        self.activePresentations.insert(presentation)

        presentation.start(
            adUnitID: params.adIdentifier,
            mediator: params.mediator,
            placement: params.checkpointIdentifier
        ) { [weak self, weak presentation] outcome in
            if let presentation {
                self?.activePresentations.remove(presentation)
            }
            completion(outcome.presentationResult)
        }
    }

}

#endif
