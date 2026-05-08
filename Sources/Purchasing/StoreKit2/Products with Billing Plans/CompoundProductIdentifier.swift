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
//  Created by Will Taylor on 5/8/2026.
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

    init?(productIdentifier: String, productPlanIdentifier: String?) {
        guard !productIdentifier.isEmpty else {
            return nil
        }

        self.productIdentifier = productIdentifier
        self.productPlanIdentifier = productPlanIdentifier?.isEmpty == true ? nil : productPlanIdentifier
    }

    /// Creates a compound product identifier from an SDK-facing product identifier string.
    ///
    /// Strings without a colon are treated as base product identifiers. Strings with one colon are split into a
    /// base product identifier and product plan identifier. Strings with more than one colon are invalid and will
    /// return nil.
    init?(productIdentifier: String) {
        let components = productIdentifier.components(separatedBy: ":")

        switch components.count {
        case 1:
            self.init(productIdentifier: productIdentifier, productPlanIdentifier: nil)

        case 2:
            let productPlanIdentifier = components[1].isEmpty ? nil : components[1]

            self.init(
                productIdentifier: components[0],
                productPlanIdentifier: productPlanIdentifier
            )

        default:
            return nil
        }
    }

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
