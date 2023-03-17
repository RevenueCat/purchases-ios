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
        // TODO: ?
        let verification: VerificationResult = .verified

        let entitlements: [String: CustomerInfoResponse.Entitlement] = purchasedSK2Products
            .dictionaryWithKeys { mapping.entitlements(for: $0.productIdentifier).first! } // TODO: 
            .mapValues { $0.entitlement }

        let content: CustomerInfoResponse = .init(
            subscriber: .init(
                originalAppUserId: IdentityManager.generateRandomID(),
                managementUrl: nil,
                originalApplicationVersion: nil,
                originalPurchaseDate: Date(),
                firstSeen: Date(),
                subscriptions: purchasedSK2Products
                    .dictionaryWithKeys { $0.productIdentifier }
                    .mapValues { $0.subscription },
                nonSubscriptions: [:], // TODO:
                entitlements: entitlements
            ),
            requestDate: Date(), // TODO: ?
            rawData: [:] // TODO: ?
        )

        self.init(
            response: content,
            entitlementVerification: verification,
            sandboxEnvironmentDetector: sandboxEnvironmentDetector
        )
    }

}
