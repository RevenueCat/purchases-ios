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

    /// The app user ID is captured once for this provider invocation.
    ///
    /// The enclosing ``DimensionResolver`` verifies it again after all providers finish, because the customer can
    /// change while CustomerInfo is being fetched or while another provider is suspended.
    func dimensions(at date: Date) async throws -> [String: DimensionValue] {
        let appUserID = self.currentAppUserIDProvider()

        var dimensions: [String: DimensionValue] = [
            "app_user_id": .string(appUserID)
        ]

        do {
            let customerInfo = try await self.customerInfoProvider(appUserID)
            if !customerInfo.originalAppUserId.isEmpty {
                dimensions["original_app_user_id"] = .string(customerInfo.originalAppUserId)
            }
            dimensions["first_seen_at"] = .date(customerInfo.firstSeen)
            dimensions.set("original_purchased_at", date: customerInfo.originalPurchaseDate)
            dimensions["purchases"] = .objectList(Self.purchases(from: customerInfo, at: date))
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
        let store: Store
        let values: [String: DimensionValue]
    }

    static func purchases(from customerInfo: CustomerInfo, at date: Date) -> [[String: DimensionValue]] {
        let subscriptions = customerInfo.subscriptionsByProductIdentifier.values
            .sorted { $0.productIdentifier < $1.productIdentifier }
            .map { subscription in
                DatedPurchase(
                    purchaseDate: subscription.purchaseDate,
                    store: subscription.store,
                    values: Self.values(for: subscription, at: date)
                )
            }

        let nonSubscriptions = customerInfo.nonSubscriptions.map { transaction in
            DatedPurchase(
                purchaseDate: transaction.purchaseDate,
                store: transaction.store,
                values: Self.values(for: transaction)
            )
        }

        // Purchases are sorted from newest to oldest. Equal dates preserve source order,
        // with subscriptions ordered by product before non-subscriptions.
        return (subscriptions + nonSubscriptions)
            .enumerated()
            .sorted {
                if $0.element.purchaseDate != $1.element.purchaseDate {
                    return $0.element.purchaseDate > $1.element.purchaseDate
                }

                return $0.offset < $1.offset
            }
            .map { indexedPurchase in
                let purchase = indexedPurchase.element
                var values = purchase.values
                if let store = purchase.store.dimensionValue {
                    values["store"] = .string(store)
                }
                return values
            }
    }

    static func entitlements(from customerInfo: CustomerInfo) -> [[String: DimensionValue]] {
        return customerInfo.entitlements.all.values
            .sorted { $0.identifier < $1.identifier }
            .map { entitlement in
                var values: [String: DimensionValue] = [
                    "identifier": .string(entitlement.identifier),
                    "product_identifier": .string(entitlement.productIdentifier),
                    "purchased_product_identifier": .string(
                        Self.purchasedProductIdentifier(
                            productIdentifier: entitlement.productIdentifier,
                            productPlanIdentifier: entitlement.productPlanIdentifier
                        )
                    ),
                    "period_type": .string(entitlement.periodType.dimensionValue),
                    "is_active": .bool(entitlement.isActive),
                    "is_sandbox": .bool(entitlement.isSandbox),
                    "will_renew": .bool(entitlement.willRenew)
                ]

                values.set("product_plan_identifier", string: entitlement.productPlanIdentifier)
                values.set("ownership_type", string: entitlement.ownershipType.dimensionValue)
                values.set("latest_purchased_at", date: entitlement.latestPurchaseDate)
                values.set("original_purchased_at", date: entitlement.originalPurchaseDate)
                values.set("expires_at", date: entitlement.expirationDate)
                values.set("unsubscribe_detected_at", date: entitlement.unsubscribeDetectedAt)
                values.set("billing_issue_detected_at", date: entitlement.billingIssueDetectedAt)
                values.set("store", string: entitlement.store.dimensionValue)

                return values
            }
    }

    static func values(for subscription: SubscriptionInfo, at date: Date) -> [String: DimensionValue] {
        let isInGracePeriod = subscription.gracePeriodExpiresDate.map { $0 > date } ?? false

        var values: [String: DimensionValue] = [
            "kind": .string("subscription"),
            "product_identifier": .string(subscription.productIdentifier),
            "purchased_product_identifier": .string(
                Self.purchasedProductIdentifier(
                    productIdentifier: subscription.productIdentifier,
                    productPlanIdentifier: subscription.productPlanIdentifier
                )
            ),
            "period_type": .string(subscription.periodType.dimensionValue),
            "status": .string(subscription.status(isInGracePeriod: isInGracePeriod)),
            "purchased_at": .date(subscription.purchaseDate),
            "is_active": .bool(subscription.isActive),
            "is_sandbox": .bool(subscription.isSandbox),
            "will_renew": .bool(subscription.willRenew),
            "is_in_grace_period": .bool(isInGracePeriod),
            "is_refunded": .bool(subscription.refundedAt != nil),
            "is_paused": .bool(subscription.autoResumeDate != nil)
        ]

        values.set("product_plan_identifier", string: subscription.productPlanIdentifier)
        values.set("store_transaction_id", string: subscription.storeTransactionId)
        values.set("display_name", string: subscription.displayName)
        values.set("ownership_type", string: subscription.ownershipType.dimensionValue)
        values.set(price: subscription.price)
        values.set("original_purchased_at", date: subscription.originalPurchaseDate)
        values.set("expires_at", date: subscription.expiresDate)
        values.set("unsubscribe_detected_at", date: subscription.unsubscribeDetectedAt)
        values.set("billing_issue_detected_at", date: subscription.billingIssuesDetectedAt)
        values.set("grace_period_expires_at", date: subscription.gracePeriodExpiresDate)
        values.set("refunded_at", date: subscription.refundedAt)
        values.set("auto_resume_at", date: subscription.autoResumeDate)

        return values
    }

    static func values(for transaction: NonSubscriptionTransaction) -> [String: DimensionValue] {
        var values: [String: DimensionValue] = [
            "kind": .string("non_subscription"),
            "product_identifier": .string(transaction.productIdentifier),
            "purchased_product_identifier": .string(transaction.productIdentifier),
            "transaction_identifier": .string(transaction.transactionIdentifier),
            "store_transaction_id": .string(transaction.storeTransactionIdentifier),
            "purchased_at": .date(transaction.purchaseDate),
            "is_sandbox": .bool(transaction.isSandbox)
        ]

        values.set("display_name", string: transaction.displayName)
        values.set(price: transaction.price)
        values.set("original_purchased_at", date: transaction.originalPurchaseDate)

        return values
    }

    static func purchasedProductIdentifier(
        productIdentifier: String,
        productPlanIdentifier: String?
    ) -> String {
        return CompoundProductIdentifier(
            productIdentifier: productIdentifier,
            productPlanIdentifier: productPlanIdentifier
        )?.compoundProductIdentifier ?? productIdentifier
    }

}

private extension SubscriptionInfo {

    func status(isInGracePeriod: Bool) -> String {
        if self.autoResumeDate != nil {
            return "paused"
        } else if isInGracePeriod {
            return "in_grace_period"
        } else if self.isActive, self.periodType == .trial {
            return "trialing"
        } else if self.isActive {
            return "active"
        } else {
            return "expired"
        }
    }

}

private extension PurchaseOwnershipType {

    var dimensionValue: String? {
        switch self {
        case .purchased: return "PURCHASED"
        case .familyShared: return "FAMILY_SHARED"
        case .unknown: return nil
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
        case .unknownStore: return "unknown"
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
