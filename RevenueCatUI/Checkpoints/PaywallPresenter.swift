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
/// Set an instance on ``Purchases/checkpointPaywallPresenter`` to use it for all checkpoint-selected offerings.
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

/// Describes how a custom checkpoint paywall presentation ended.
///
/// After ``purchased``, ``closed``, or ``continued``, RevenueCat synchronizes purchases and refreshes
/// customer information before completing the checkpoint. ``navigatedBack`` skips synchronization and does not invoke
/// the checkpoint's passed callback.
@_spi(CheckpointsInternal)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public final class PaywallPresentationResult {

    /// The customer purchased or restored from the custom paywall and completed the presentation.
    ///
    /// RevenueCat synchronizes purchases and refreshes customer information before completing the checkpoint.
    public static let purchased = PaywallPresentationResult(kind: .purchased)

    /// The customer left through a close action.
    ///
    /// The customer passes the checkpoint. RevenueCat still synchronizes purchases before invoking the checkpoint's
    /// passed callback, so a purchase completed during the presentation can be reflected in its result.
    public static let closed = PaywallPresentationResult(kind: .closed)

    /// The customer backed out of the paywall.
    ///
    /// RevenueCat does not synchronize purchases or invoke the checkpoint's passed callback, leaving the app at the
    /// point from which it presented the checkpoint.
    public static let navigatedBack = PaywallPresentationResult(kind: .navigatedBack)

    /// The customer chose to continue.
    ///
    /// This behaves like ``closed`` today. It remains distinct so a future multi-step checkpoint can continue after
    /// the custom paywall instead of ending the presentation. RevenueCat synchronizes purchases before completing the
    /// checkpoint.
    public static let continued = PaywallPresentationResult(kind: .continued)

    enum Kind {
        case purchased
        case closed
        case navigatedBack
        case continued
    }

    let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
    }

}
