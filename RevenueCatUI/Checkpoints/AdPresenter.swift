//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdPresenter.swift
//

import Foundation
@_spi(Internal) import RevenueCat

/// Reports the terminal outcome of a custom ad presentation.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias AdPresentationCompletion = @MainActor (AdPresentationResult) -> Void

/// Presents an ad for an ad unit selected by a checkpoint.
///
/// Set an instance on ``Purchases/adPresenter`` to use it for all checkpoint-selected ad steps.
/// This is a separate presenter from ``PaywallPresenter``: an ad step never selects an offering, and
/// presenting one does not necessarily involve any RevenueCat-managed UI.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol AdPresenter: AnyObject {

    /// Presents a checkpoint-selected ad and reports one terminal result through `completion`.
    ///
    /// The checkpoint remains pending until `completion` is called. Only the first reported result is used;
    /// later calls are ignored.
    func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    )

}

/// Context for a custom checkpoint ad presentation.
///
/// This separate type keeps the presenter's method signature extensible as presentation context grows.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class AdPresentationParams {

    /// The identifier of the checkpoint that selected this ad step.
    public let checkpointIdentifier: String

    /// The custom variables supplied to the checkpoint.
    public let customVariables: [String: CustomVariableValue]

    /// The ad unit identifier configured for the checkpoint-selected ad step.
    public let adUnitId: String

    /// The mediation network configured to serve ``adUnitId``.
    public let mediator: MediatorName

    /// The ad format ``adUnitId`` was created for, which decides how the presenter loads and shows it.
    public let adFormat: AdFormat

    /// Creates presentation context for an ad step selected by a checkpoint.
    ///
    /// - Parameters:
    ///   - checkpointIdentifier: The identifier of the checkpoint that selected the ad step.
    ///   - customVariables: The custom variables supplied to the checkpoint.
    ///   - adUnitId: The ad unit identifier configured for the ad step.
    ///   - mediator: The mediation network configured to serve `adUnitId`.
    ///   - adFormat: The ad format `adUnitId` was created for.
    public init(
        checkpointIdentifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        adUnitId: String,
        mediator: MediatorName,
        adFormat: AdFormat
    ) {
        self.checkpointIdentifier = checkpointIdentifier
        self.customVariables = customVariables
        self.adUnitId = adUnitId
        self.mediator = mediator
        self.adFormat = adFormat
    }

}

/// A terminal result reported by a custom checkpoint ad presenter.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class AdPresentationResult {

    /// The ad was shown and dismissed, with no reward earned.
    public static let shown = AdPresentationResult(outcome: CheckpointAdOutcome.Shown.shared)

    /// The customer earned the ad's reward and RevenueCat verified it.
    public static func rewarded(reward: AdReward, moreRewards: [AdReward] = []) -> AdPresentationResult {
        return AdPresentationResult(outcome: CheckpointAdOutcome.Rewarded(reward: reward, moreRewards: moreRewards))
    }

    /// The customer earned the ad's reward, but RevenueCat could not verify it, so nothing was granted.
    public static let rewardVerificationFailed = AdPresentationResult(
        outcome: CheckpointAdOutcome.RewardVerificationFailed.shared
    )

    /// The ad could not be shown, for example because it failed to load or the mediator had no fill.
    public static func failed(error: PublicError) -> AdPresentationResult {
        return AdPresentationResult(outcome: CheckpointAdOutcome.Failed(error: error))
    }

    let outcome: CheckpointAdOutcome

    private init(outcome: CheckpointAdOutcome) {
        self.outcome = outcome
    }

}
