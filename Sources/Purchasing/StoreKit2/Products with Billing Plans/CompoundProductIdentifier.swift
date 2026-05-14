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
import StoreKit

/// Identifies a product that may represent a specific platform product plan.
///
/// StoreKit only knows about the base ``productIdentifier``. RevenueCat can also receive an optional
/// ``productPlanIdentifier`` from the backend to distinguish multiple SDK products backed by the same StoreKit
/// product, such as monthly billing plans.
///
/// SDK-facing compound product identifier strings use the format `{productIdentifier}` for products without specifying
/// a particular billing plan, and `{productIdentifier}:{productPlanIdentifier}` for products with a given plan.
/// For example, `com.revenuecat.subscription` identifies the StoreKit product itself, while
/// `com.revenuecat.subscription:monthly` identifies that StoreKit product with the `monthly` product plan.
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

    /// Creates a compound product identifier for a StoreKit 2 product.
    ///
    /// StoreKit 2 products are fetched by their base product identifier, so this initializer uses ``SK2Product/id``
    /// as ``productIdentifier`` and leaves ``productPlanIdentifier`` empty. Billing-plan-specific identifiers are
    /// added separately when backend product plan data is available.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    init(for sk2Product: SK2Product) {
        self.productIdentifier = sk2Product.id
        self.productPlanIdentifier = nil
    }

    /// Creates a compound product identifier from an SDK-facing product identifier string.
    ///
    /// Strings without a colon are treated as base product identifiers. Strings with one colon are split into a
    /// base product identifier and product plan identifier. Strings with more than one colon are invalid and will
    /// return nil.
    init?(compoundProductIdentifier: String) {
        let components = compoundProductIdentifier.components(separatedBy: ":")

        switch components.count {
        case 1:
            self.init(productIdentifier: compoundProductIdentifier, productPlanIdentifier: nil)

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
}

// MARK: - Computed Properties
extension CompoundProductIdentifier {
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

// MARK: - StoreKit Mappings
#if compiler(>=6.3.2)   // Billing plans were introduced in Xcode 26.5
extension CompoundProductIdentifier {
    /// The StoreKit 2 billing plan type represented by ``productPlanIdentifier``.
    ///
    /// Returns `nil` when there is no product plan identifier, or when the identifier does not map to a supported
    /// StoreKit billing plan type.
    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    var sk2BillingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType? {
        guard let productPlanIdentifier else {
            return nil
        }

        switch productPlanIdentifier {
        case BillingPlanType.monthly.value:
            return StoreKit.Product.SubscriptionInfo.BillingPlanType.monthly
        default:
            Logger.warn(
                StoreKitStrings.sk2_unrecognized_billing_plan_identifer(billingPlanIdentifier: productPlanIdentifier)
            )
            return nil
        }
    }
}
#endif
