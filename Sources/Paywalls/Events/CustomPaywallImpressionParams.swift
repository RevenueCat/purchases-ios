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
@_spi(Experimental) @objc(RCCustomPaywallImpressionParams)
public final class CustomPaywallImpressionParams: NSObject, Sendable {

    /// An optional identifier for the custom paywall being shown.
    @objc public let paywallId: String?

    /// An optional identifier for the offering associated with the custom paywall.
    /// If not provided, the SDK will use the current offering identifier from the cache.
    @objc public let offeringId: String?

    /// Creates parameters for a custom paywall impression.
    /// - Parameters:
    ///   - paywallId: An optional identifier for the custom paywall being shown.
    ///   - offeringId: An optional identifier for the offering associated with the custom paywall.
    ///     If not provided, the SDK will use the current offering identifier from the cache.
    @objc public init(paywallId: String? = nil, offeringId: String? = nil) {
        self.paywallId = paywallId
        self.offeringId = offeringId
    }

}
