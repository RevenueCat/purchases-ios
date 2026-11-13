//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointResults.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// The result of completing a checkpoint flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct FlowResult: Sendable {

    /// Active entitlements present after the flow that were not active before it was presented.
    ///
    /// The SDK compares the customer information delivered with the result against the one read before presenting
    /// the flow.
    public let obtainedEntitlements: Set<ObtainedEntitlement>

    /// Products newly observed after the flow completed, among those its offerings sell.
    ///
    /// The SDK compares the purchase dates in the customer information delivered with the result against the ones
    /// read before presenting the flow: a renewal or a repeat purchase counts.
    public let obtainedProducts: Set<ObtainedProduct>

    init(
        obtainedEntitlements: Set<ObtainedEntitlement>,
        obtainedProducts: Set<ObtainedProduct>
    ) {
        self.obtainedEntitlements = obtainedEntitlements
        self.obtainedProducts = obtainedProducts
    }

    /// Returns the entitlement with `identifier` that was obtained while the flow was presented.
    public func obtainedEntitlement(_ identifier: String) -> ObtainedEntitlement? {
        return self.obtainedEntitlements.first { $0.entitlementInfo.identifier == identifier }
    }

    /// Returns whether the entitlement with `identifier` was obtained while the flow was presented.
    public func didObtainEntitlement(_ identifier: String) -> Bool {
        return self.obtainedEntitlement(identifier) != nil
    }

    /// Returns the product with `identifier` that was newly observed after the flow completed.
    ///
    /// `identifier` is the product's store identifier. When more than one billing plan of a product was obtained,
    /// the plain identifier returns the up-front plan; suffix it with `:` and the billing plan type
    /// (`"com.app.annual:monthly"`) to select another.
    public func obtainedProduct(_ identifier: String) -> ObtainedProduct? {
        return self.obtainedProducts.first { $0.product.id == identifier }
            ?? self.obtainedProducts.first { $0.product.productIdentifier == identifier }
    }

    /// Returns whether the product with `identifier` was newly observed after the flow completed. See
    /// ``obtainedProduct(_:)`` for the identifier's format.
    public func didObtainProduct(_ identifier: String) -> Bool {
        return self.obtainedProduct(identifier) != nil
    }

}

/// An active entitlement reported after completing a checkpoint flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ObtainedEntitlement: Hashable, Sendable {

    /// Information about the active entitlement reported after the flow.
    public let entitlementInfo: EntitlementInfo

    init(entitlementInfo: EntitlementInfo) {
        self.entitlementInfo = entitlementInfo
    }

    /// Returns whether two obtained entitlements represent the same entitlement identifier.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.entitlementInfo.identifier == rhs.entitlementInfo.identifier
    }

    /// Hashes the entitlement identifier.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.entitlementInfo.identifier)
    }

}

/// A product newly observed after completing a checkpoint flow.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ObtainedProduct: Hashable, Sendable {

    /// The product observed after completing the flow.
    public let product: StoreProduct

    init(product: StoreProduct) {
        self.product = product
    }

    /// Returns whether two obtained products represent the same product and billing plan.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.product.id == rhs.product.id
    }

    /// Hashes the product identifier and billing plan.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.product.id)
    }

}

extension CustomerInfo {

    var activeEntitlementIdentifiers: Set<String> {
        return Set(self.entitlements.active.keys)
    }

    func obtainedEntitlements(
        comparedTo initialActiveEntitlementIdentifiers: Set<String>?
    ) -> [EntitlementInfo] {
        guard let initialActiveEntitlementIdentifiers else {
            return Array(self.entitlements.active.values)
        }

        return self.entitlements.active.values.filter { entitlement in
            return !initialActiveEntitlementIdentifiers.contains(entitlement.identifier)
        }
    }

    func grantsNewEntitlements(
        comparedTo initialActiveEntitlementIdentifiers: Set<String>?
    ) -> Bool {
        return !self.obtainedEntitlements(comparedTo: initialActiveEntitlementIdentifiers).isEmpty
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func obtainedProducts(
        comparedTo initialCustomerInfo: CustomerInfo?,
        from availableProducts: [StoreProduct]
    ) -> [ObtainedProduct] {
        let productsByIdentifier = Dictionary(
            availableProducts.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return productsByIdentifier.values.compactMap { product in
            let identifier = product.id
            guard let purchaseDate = self.purchaseDate(forProductIdentifier: identifier),
                  purchaseDate != initialCustomerInfo?.purchaseDate(forProductIdentifier: identifier) else {
                return nil
            }

            return ObtainedProduct(product: product)
        }
    }

}
