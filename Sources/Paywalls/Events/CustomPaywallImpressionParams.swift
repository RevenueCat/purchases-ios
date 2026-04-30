//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPaywallImpressionParams.swift
//
//  Created by Rick van der Linden on 11/03/2026.

import Foundation

/// Parameters for tracking a custom paywall impression event.
@objc(RCCustomPaywallImpressionParams)
public final class CustomPaywallImpressionParams: NSObject, Sendable {

    /// An optional identifier for the custom paywall being shown.
    @objc public let paywallId: String?

    /// An optional identifier for the offering associated with the custom paywall.
    /// If not provided, the SDK will use the current offering identifier from the cache.
    @objc public let offeringId: String?

    /// The offering associated with the custom paywall.
    ///
    /// When provided, the SDK will derive the presented offering context (placement and targeting
    /// information) from this offering. If neither `offering` nor `offeringId` is provided, the SDK
    /// will use the current offering from the cache.
    @objc public let offering: Offering?

    /// Creates parameters for a custom paywall impression with string identifiers.
    ///
    /// Use this initializer when the ``Offering`` object is not available at call time.
    ///
    /// - Parameters:
    ///   - paywallId: An optional identifier for the custom paywall being shown.
    ///   - offeringId: An optional identifier for the offering associated with the custom paywall.
    ///     If `nil`, the SDK will use the current offering identifier from the cache.
    @objc public init(paywallId: String? = nil, offeringId: String?) {
        self.paywallId = paywallId
        self.offeringId = offeringId
        self.offering = nil
    }

    /// Creates parameters with only a paywall identifier.
    ///
    /// The SDK will use the current offering from the cache to derive the offering identifier
    /// and presented offering context.
    ///
    /// - Parameter paywallId: An optional identifier for the custom paywall being shown.
    @objc public convenience init(paywallId: String? = nil) {
        self.init(paywallId: paywallId, offeringId: nil)
    }

    /// Creates parameters for a custom paywall impression from the offering it was obtained from.
    ///
    /// Use this initializer when presenting a paywall for an offering that is not the current
    /// offering (for example, a placement-resolved offering). The SDK will derive both the offering
    /// identifier and the presented offering context (placement and targeting information) from
    /// the provided offering.
    ///
    /// - Parameters:
    ///   - paywallId: An optional identifier for the custom paywall being shown.
    ///   - offering: The offering associated with the custom paywall.
    @objc public init(paywallId: String? = nil, offering: Offering) {
        self.paywallId = paywallId
        self.offeringId = offering.identifier
        self.offering = offering
    }

}
