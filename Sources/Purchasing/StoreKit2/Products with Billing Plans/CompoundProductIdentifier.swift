//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompoundProductIdentifier.swift
//
//  Created by RevenueCat.
//

import Foundation

/// Identifies a product that may represent a specific platform product plan.
///
/// StoreKit only knows about the base ``productIdentifier``. RevenueCat can also receive an optional
/// ``productPlanIdentifier`` from the backend to distinguish multiple SDK products backed by the same StoreKit
/// product, such as monthly and up-front billing plans.
internal struct CompoundProductIdentifier: Hashable {

    /// The base product identifier.
    let productIdentifier: String

    /// The optional product plan identifier.
    let productPlanIdentifier: String?

    /// The identifier that should be requested from StoreKit.
    ///
    /// StoreKit only knows about the base product identifier, so planned products are deduplicated by this value
    /// before fetching product data.
    var storeKitProductIdentifier: String {
        return self.productIdentifier
    }

    /// The SDK-facing compound identifier for caching and lookup.
    ///
    /// Products without a billing plan use the base product identifier. Products with a billing plan use
    /// `{productIdentifier}:{productPlanIdentifier}` so two SDK products that share a StoreKit product can still
    /// be represented independently.
    var compoundProductIdentifier: String {
        guard let productPlanIdentifier else {
            return self.productIdentifier
        }

        return "\(self.productIdentifier):\(productPlanIdentifier)"
    }

}
