//
//  AdMobRewardedPresenter.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import UIKit

/// Presents an AdMob rewarded ad when a checkpoint resolves to an ad step, and reports the verified reward.
///
/// Register an instance on `Purchases.shared.checkpointAdPresenter` so a resolved ad step loads the
/// configured ad unit through `RewardedAd.loadAndTrack` (so the usual RevenueCat ad events are tracked),
/// enables RevenueCat reward verification, and presents it from the topmost view controller. Once the
/// customer earns the reward, RevenueCat verifies it server-side and grants the configured virtual
/// currency or entitlement before the checkpoint completes with `CheckpointAdOutcome.Rewarded`.
///
/// The checkpoint identifier is used as the tracking placement. Failures are reported as `NSError`s in
/// the `RevenueCatAdMob.RewardedPresentationError` domain, or as the underlying AdMob error.
@_spi(CheckpointsInternal)
@available(iOS 15.0, *)
@MainActor
public final class AdMobRewardedPresenter: AdPresenter {

    /// Presentations stay alive until they complete: AdMob holds `fullScreenContentDelegate` weakly.
    private var activePresentations: Set<RewardedPresentation> = []

    /// Creates a presenter that loads and shows AdMob rewarded ads for checkpoint ad steps.
    public init() {}

    /// Loads and presents the rewarded ad for `params.adUnitId`, completing once it is dismissed and any
    /// earned reward has been verified, or once it fails.
    public func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    ) {
        let presentation = RewardedPresentation()
        self.activePresentations.insert(presentation)

        presentation.start(
            adUnitID: params.adUnitId,
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
