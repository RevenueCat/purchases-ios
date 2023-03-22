//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo+OfflineEntitlements.swift
//
//  Created by Nacho Soto on 3/21/23.

import Foundation

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension CustomerInfo {

    convenience init(
        from purchasedSK2Products: [PurchasedSK2Product],
        mapping: ProductEntitlementMapping,
        sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default
    ) {
        let content: CustomerInfoResponse = .init(
            subscriber: .init(
                originalAppUserId: IdentityManager.generateRandomID(),
                managementUrl: nil,
                originalApplicationVersion: nil,
                originalPurchaseDate: Date(),
                firstSeen: Date(),
                subscriptions: purchasedSK2Products
                    .dictionaryAllowingDuplicateKeys { $0.productIdentifier }
                    .mapValues { $0.subscription },
                nonSubscriptions: [:], // TODO:
                entitlements: Self.createEntitlements(with: purchasedSK2Products, mapping: mapping)
            ),
            requestDate: Date(), // TODO: ?
            rawData: [:] // TODO: ?
        )

        self.init(
            response: content,
            entitlementVerification: Self.verification,
            sandboxEnvironmentDetector: sandboxEnvironmentDetector
        )
    }

    private static func createEntitlements(
        with products: [PurchasedSK2Product],
        mapping: ProductEntitlementMapping
    ) -> [String: CustomerInfoResponse.Entitlement] {
        var result: [String: CustomerInfoResponse.Entitlement] = .init(minimumCapacity: products.count)

        for product in products {
            for entitlement in mapping.entitlements(for: product.productIdentifier) {
                result[entitlement] = product.entitlement
            }
        }

        return result
    }

    /// Purchases are verified with StoreKit 2.
    private static let verification: VerificationResult = .verified

}
