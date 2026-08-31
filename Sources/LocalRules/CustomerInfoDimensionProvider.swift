//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoDimensionProvider.swift
//
//  Created by Rick van der Linden on 8/31/26.
//

import Foundation

/// Supplies CustomerInfo dimensions to the local rules engine.
struct CustomerInfoDimensionProvider: DimensionProvider {

    let name = "customer_info"

    private let currentAppUserIDProvider: @Sendable () -> String
    private let customerInfoProvider: @Sendable (String) async throws -> CustomerInfo

    init(
        currentAppUserIDProvider: @escaping @Sendable () -> String,
        customerInfoProvider: @escaping @Sendable (String) async throws -> CustomerInfo
    ) {
        self.currentAppUserIDProvider = currentAppUserIDProvider
        self.customerInfoProvider = customerInfoProvider
    }

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        let appUserID = self.currentAppUserIDProvider()
        guard !appUserID.isEmpty else { return [:] }

        var dimensions: [String: DimensionValue] = [
            "app_user_id": .string(appUserID)
        ]

        do {
            let customerInfo = try await self.customerInfoProvider(appUserID)
            if !customerInfo.originalAppUserId.isEmpty {
                dimensions["original_app_user_id"] = .string(customerInfo.originalAppUserId)
            }
            dimensions["purchases"] = .objectList(Self.purchases(from: customerInfo))
            dimensions["entitlements"] = .objectList(Self.entitlements(from: customerInfo))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // The current app user ID is still useful when CustomerInfo is temporarily unavailable.
            Logger.warn(Strings.remoteConfig.customerInfoUnavailable(error))
        }

        return dimensions
    }

}

private extension CustomerInfoDimensionProvider {

    struct DatedPurchase {

        let purchaseDate: Date
        let productIdentifier: String
        let store: Store
        let values: [String: DimensionValue]
    }

    static func purchases(from customerInfo: CustomerInfo) -> [[String: DimensionValue]] {
        let subscriptions = customerInfo.subscriptionsByProductIdentifier.values.map { subscription in
            DatedPurchase(
                purchaseDate: subscription.purchaseDate,
                productIdentifier: subscription.productIdentifier,
                store: subscription.store,
                values: [
                    "kind": .string("subscription"),
                    "is_active": .bool(subscription.isActive),
                    "is_sandbox": .bool(subscription.isSandbox),
                    "product_identifier": .string(subscription.productIdentifier),
                    "period_type": .string(subscription.periodType.dimensionValue)
                ]
            )
        }

        let nonSubscriptions = customerInfo.nonSubscriptions.map { transaction in
            DatedPurchase(
                purchaseDate: transaction.purchaseDate,
                productIdentifier: transaction.productIdentifier,
                store: transaction.store,
                // `is_active` and `period_type` describe subscription state and do not have
                // meaningful equivalents for a non-subscription transaction.
                values: [
                    "kind": .string("non_subscription"),
                    "is_sandbox": .bool(transaction.isSandbox),
                    "product_identifier": .string(transaction.productIdentifier)
                ]
            )
        }

        return (subscriptions + nonSubscriptions)
            .sorted {
                if $0.purchaseDate != $1.purchaseDate {
                    return $0.purchaseDate > $1.purchaseDate
                }

                return $0.productIdentifier < $1.productIdentifier
            }
            .map { purchase in
                guard let store = purchase.store.dimensionValue else { return purchase.values }

                var values = purchase.values
                values["store"] = .string(store)
                return values
            }
    }

    static func entitlements(from customerInfo: CustomerInfo) -> [[String: DimensionValue]] {
        return customerInfo.entitlements.all.values
            .sorted { $0.identifier < $1.identifier }
            .map { entitlement in
                [
                    "identifier": .string(entitlement.identifier),
                    "is_active": .bool(entitlement.isActive),
                    "is_sandbox": .bool(entitlement.isSandbox)
                ]
            }
    }

}

private extension Store {

    var dimensionValue: String? {
        switch self {
        case .appStore: return "app_store"
        case .macAppStore: return "mac_app_store"
        case .playStore: return "play_store"
        case .stripe: return "stripe"
        case .promotional: return "promotional"
        case .unknownStore: return nil
        case .amazon: return "amazon"
        case .rcBilling: return "rc_billing"
        case .external: return "external"
        case .paddle: return "paddle"
        case .testStore: return "test_store"
        case .galaxy: return "galaxy"
        }
    }

}

private extension PeriodType {

    var dimensionValue: String {
        switch self {
        case .normal: return "normal"
        case .intro: return "intro"
        case .trial: return "trial"
        case .prepaid: return "prepaid"
        }
    }

}
