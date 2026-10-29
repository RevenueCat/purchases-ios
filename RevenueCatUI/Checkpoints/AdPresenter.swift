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
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias AdPresentationCompletion = @MainActor (AdPresentationResult) -> Void

/// Presents an ad for an ad step selected by a checkpoint.
///
/// Set an instance on ``Purchases/adPresenter`` to use it for all checkpoint-selected ad steps.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol AdPresenter: AnyObject {

    /// Presents an ad and reports result through `completion`.
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
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct AdPresentationParams {

    /// The identifier of the checkpoint that selected this ad step.
    public let checkpointIdentifier: String

    /// Identifies the ad to load for the checkpoint-selected ad step, in whatever form ``mediator`` expects
    /// (an AdMob ad unit id, for example).
    public let adIdentifier: String

    /// The mediation network configured to serve ``adIdentifier``.
    public let mediator: MediatorName

    /// The ad format ``adIdentifier`` was created for, which decides how the presenter loads and shows it.
    public let adFormat: AdFormat

    /// Creates presentation context for an ad step selected by a checkpoint.
    ///
    /// - Parameters:
    ///   - checkpointIdentifier: The identifier of the checkpoint that selected the ad step.
    ///   - adIdentifier: The identifier of the ad configured for the ad step.
    ///   - mediator: The mediation network configured to serve `adIdentifier`.
    ///   - adFormat: The ad format `adIdentifier` was created for.
    @_spi(Internal) public init(
        checkpointIdentifier: String,
        adIdentifier: String,
        mediator: MediatorName,
        adFormat: AdFormat
    ) {
        self.checkpointIdentifier = checkpointIdentifier
        self.adIdentifier = adIdentifier
        self.mediator = mediator
        self.adFormat = adFormat
    }

}

/// A terminal result reported by a custom checkpoint ad presenter.
///
/// Whatever a shown ad granted, such as a verified reward, reaches the app through the checkpoint's
/// ``CheckpointResult`` like the outcome of any other flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AdPresentationResult: Equatable, Sendable {

    /// The ad was shown and dismissed.
    public static let shown = AdPresentationResult(error: nil)

    /// The ad could not be shown, for example because it failed to load or the mediator had no fill.
    public static func failed(error: PublicError) -> AdPresentationResult {
        return AdPresentationResult(error: error)
    }

    let error: PublicError?

    private init(error: PublicError?) {
        self.error = error
    }

}
