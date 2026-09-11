//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Reports the terminal outcome of a custom paywall presentation.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias PaywallPresentationCompletion = @MainActor (PaywallPresentationResult) -> Void

/// Presents a custom paywall for an offering selected by a checkpoint.
///
/// Set an instance on ``Purchases/checkpointPaywallPresenter`` to use it for all checkpoint-selected offerings.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol PaywallPresenter: AnyObject {

    /// Presents a checkpoint-selected offering and reports one terminal result through `completion`.
    ///
    /// The checkpoint remains pending until `completion` is called. Only the first reported result is used;
    /// later calls are ignored.
    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    )

}

/// Presents a checkpoint-selected offering using a custom paywall.
///
/// The checkpoint remains pending until the completion closure is called. Only the first reported result is used;
/// later calls are ignored. Pass this closure to ``Purchases/checkpoint(_:customVariables:paywallPresenter:_:)``
/// to override the global presenter for one checkpoint call.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias PaywallPresentationHandler = @MainActor (
    PaywallPresentationParams,
    @escaping PaywallPresentationCompletion
) -> Void

/// Context for a custom checkpoint paywall presentation.
///
/// This separate type keeps the presenter's method signature extensible as presentation context grows.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class PaywallPresentationParams {

    /// The identifier of the checkpoint that selected this offering.
    public let checkpointIdentifier: String

    /// The custom variables supplied to the checkpoint.
    public let customVariables: [String: CustomVariableValue]

    /// The offering for which to present the paywall.
    public let offering: Offering

    /// Creates presentation context for an offering selected by a checkpoint.
    ///
    /// - Parameters:
    ///   - checkpointIdentifier: The identifier of the checkpoint that selected the offering.
    ///   - customVariables: The custom variables supplied to the checkpoint.
    ///   - offering: The offering for which to present the paywall.
    public init(
        checkpointIdentifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        offering: Offering
    ) {
        self.checkpointIdentifier = checkpointIdentifier
        self.customVariables = customVariables
        self.offering = offering
    }

}

/// A terminal result reported by a custom checkpoint paywall presenter.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class PaywallPresentationResult {

    /// The customer purchased through the custom paywall.
    public static let purchased = PaywallPresentationResult()

    /// The customer closed the paywall. A soft checkpoint may continue after this result.
    public static let closed = PaywallPresentationResult()

    /// The customer navigated back from the paywall. The checkpoint should not invoke its passed callback.
    public static let navigatedBack = PaywallPresentationResult()

    /// The customer continued without purchasing, so RevenueCat should advance the remaining checkpoint flow.
    public static let continuedWithoutPurchasing = PaywallPresentationResult()

    private init() {}

}
