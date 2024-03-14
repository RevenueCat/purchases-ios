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

extension CustomerInfo {

    typealias OfflineCreator = ([PurchasedSK2Product],
                                ProductEntitlementMapping,
                                String) -> CustomerInfo

    convenience init(
        from purchasedSK2Products: [PurchasedSK2Product],
        mapping: ProductEntitlementMapping,
        userID: String,
        sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default
    ) {
        let subscriber = CustomerInfoResponse.Subscriber(
            originalAppUserId: userID,
            managementUrl: SystemInfo.appleSubscriptionsURL,
            originalApplicationVersion: SystemInfo.buildVersion,
            originalPurchaseDate: Date(),
            firstSeen: Date(),
            subscriptions: purchasedSK2Products
                .dictionaryAllowingDuplicateKeys { $0.productIdentifier }
                .mapValues { $0.subscription },
            nonSubscriptions: [:],
            entitlements: Self.createEntitlements(with: purchasedSK2Products, mapping: mapping)
        )

        let content: CustomerInfoResponse = .init(
            subscriber: subscriber,
            requestDate: Date(),
            rawData: (try? subscriber.asDictionary()) ?? [:]
        )

        self.init(
            response: content,
            entitlementVerification: Self.verification,
            sandboxEnvironmentDetector: sandboxEnvironmentDetector
        )
    }

}

// MARK: - Private

private extension CustomerInfo {

    static func createEntitlements(
        with products: [PurchasedSK2Product],
        mapping: ProductEntitlementMapping
    ) -> [String: CustomerInfoResponse.Entitlement] {
        func shouldOverride(prior: CustomerInfoResponse.Entitlement,
                            new: CustomerInfoResponse.Entitlement) -> Bool {
            guard let priorExpiration = prior.expiresDate else {
                // Prior entitlement is lifetime
                return false
            }

            guard let newExpiration = new.expiresDate else {
                // New entitlement is lifetime
                return true
            }

            return newExpiration > priorExpiration
        }

        var result: [String: CustomerInfoResponse.Entitlement] = .init(minimumCapacity: products.count)

        for product in products {
            for entitlement in mapping.entitlements(for: product.productIdentifier) {
                if let priorEntitlement = result[entitlement],
                   !shouldOverride(prior: priorEntitlement, new: product.entitlement) {
                    continue
                }

                result[entitlement] = product.entitlement
            }
        }

        return result
    }

    /// Purchases are verified with StoreKit 2.
    private static let verification: VerificationResult = .verifiedOnDevice

}

internal extension CustomerInfo {

    var isComputedOffline: Bool {
        return self.entitlements.verification == .verifiedOnDevice
    }

}
