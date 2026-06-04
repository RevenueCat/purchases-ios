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
    /// If neither this nor an ``Offering`` is provided, the SDK will use the current offering
    /// identifier from the cache.
    @objc public let offeringId: String?

    /// The presented offering context (placement and targeting information) derived from the
    /// offering, if available.
    @_spi(Internal) public let presentedOfferingContext: PresentedOfferingContext?

    /// Designated initializer. Intended for use by hybrid SDKs that pass placement/targeting
    /// context through purchases-hybrid-common rather than via an ``Offering`` object.
    @_spi(Internal)
    public init(paywallId: String? = nil, offeringId: String?, presentedOfferingContext: PresentedOfferingContext?) {
        self.paywallId = paywallId
        self.offeringId = offeringId
        self.presentedOfferingContext = presentedOfferingContext
    }

    /// Creates parameters with only a paywall identifier.
    ///
    /// The SDK will use the current offering from the cache to derive the offering identifier
    /// and presented offering context.
    ///
    /// - Parameter paywallId: An optional identifier for the custom paywall being shown.
    @objc public convenience init(paywallId: String? = nil) {
        self.init(paywallId: paywallId, offeringId: nil, presentedOfferingContext: nil)
    }

    /// Creates parameters for a custom paywall impression with a string offering identifier.
    ///
    /// - Parameters:
    ///   - paywallId: An optional identifier for the custom paywall being shown.
    ///   - offeringId: An optional identifier for the offering associated with the custom paywall.
    ///     If `nil`, the SDK will use the current offering identifier from the cache.
    ///
    /// - Important: Prefer ``init(paywallId:offering:)`` when an ``Offering`` object is available.
    ///   Passing only a string identifier prevents the SDK from automatically deriving placement
    ///   and targeting context.
    @available(*, deprecated,
               // swiftlint:disable:next line_length
               message: "Pass an Offering object instead. Using an offering identifier string prevents the SDK from deriving placement and targeting context automatically.",
               renamed: "init(paywallId:offering:)")
    @objc public convenience init(paywallId: String? = nil, offeringId: String?) {
        self.init(paywallId: paywallId, offeringId: offeringId, presentedOfferingContext: nil)
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
    @objc public convenience init(paywallId: String? = nil, offering: Offering) {
        self.init(
            paywallId: paywallId,
            offeringId: offering.identifier,
            presentedOfferingContext: offering.presentedOfferingContext
        )
    }

}
