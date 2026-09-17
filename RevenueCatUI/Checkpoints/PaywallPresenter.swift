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

/// Reports how a custom paywall presentation ended.
///
/// Call this once when the presentation ends. RevenueCat ignores later calls for the same checkpoint.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias PaywallPresentationCompletion = @MainActor (PaywallPresentationResult) -> Void

/// Presents a custom paywall for an offering selected by a checkpoint.
///
/// Set an instance on ``Purchases/paywallPresenter`` to use it for all checkpoint-selected offerings.
/// The presenter owns its UI and reports how the presentation ended; RevenueCat owns purchase synchronization and
/// determines which entitlements were obtained while the checkpoint was presented.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public protocol PaywallPresenter: AnyObject {

    /// Presents a checkpoint-selected offering and reports how the presentation ended through `completion`.
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
/// to override the global presenter for one checkpoint call. RevenueCat synchronizes purchases and determines which
/// entitlements were obtained after the presentation ends.
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
public struct PaywallPresentationParams {

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
    init(
        checkpointIdentifier: String,
        customVariables: [String: CustomVariableValue] = [:],
        offering: Offering
    ) {
        self.checkpointIdentifier = checkpointIdentifier
        self.customVariables = customVariables
        self.offering = offering
    }

}

/// Describes how a custom checkpoint paywall presentation ended.
///
/// After ``continued`` or ``closed``, RevenueCat synchronizes purchases and refreshes customer information before
/// completing the checkpoint. ``navigatedBack`` skips synchronization and does not invoke the checkpoint's passed
/// callback.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct PaywallPresentationResult: Hashable {

    private let rawValue: Int

    private init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The customer went through the custom paywall presentation and the checkpoint should continue: they purchased,
    /// restored, or chose to continue without purchasing.
    ///
    /// RevenueCat synchronizes purchases and refreshes customer information before completing the checkpoint.
    public static let continued = Self(rawValue: 0)

    /// The customer closed the custom paywall, or the presentation could not be completed.
    ///
    /// RevenueCat synchronizes purchases and refreshes customer information before completing the checkpoint.
    public static let closed = Self(rawValue: 1)

    /// The customer backed out of the paywall.
    ///
    /// RevenueCat does not synchronize purchases or invoke the checkpoint's passed callback, leaving the app at the
    /// point from which it presented the checkpoint.
    public static let navigatedBack = Self(rawValue: 2)

}
