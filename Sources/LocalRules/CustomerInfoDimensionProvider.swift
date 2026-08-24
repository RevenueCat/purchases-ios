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
//  Created by Facundo Menzella on 20/8/26.
//

import Foundation

/// Reads the customer info a snapshot describes.
protocol CustomerInfoDimensionSource: Sendable {

    func customerInfo(appUserID: String) async throws -> CustomerInfo
}

extension CustomerInfoManager: CustomerInfoDimensionSource {

    func customerInfo(appUserID: String) async throws -> CustomerInfo {
        return try await self.customerInfo(appUserID: appUserID, fetchPolicy: .default)
    }
}

/// Supplies the current customer's purchases and entitlements to the local rules engine.
///
/// Every fact is exposed as it comes, without interpretation, so a rule authored
/// in the dashboard decides for itself what makes a customer match.
struct CustomerInfoDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.customerInfo

    private let customerInfoProvider: any CustomerInfoDimensionSource

    init(customerInfoProvider: any CustomerInfoDimensionSource) {
        self.customerInfoProvider = customerInfoProvider
    }

    /// The customer comes from `context` rather than from the current user, so the purchases
    /// below and the ID they are reported under always describe the same customer, however long
    /// the read suspends for.
    func dimensions(in context: DimensionContext) async throws -> [String: DimensionValue] {
        var dimensions = try await self.customerInfoDimensions(in: context)
        // Reported even when the read failed, so a rule targeting only the ID still resolves.
        dimensions.put(Self.appUserIDKey, string: context.appUserID)
        return dimensions
    }

    /// A customer info that cannot be read contributes no dimensions rather than failing the whole
    /// snapshot. A rule then sees a customer with nothing, so an absence rule matches: see
    /// `anUnreadableCustomerInfoLetsAbsenceRulesMatch`. Cancellation is not a failure and propagates.
    private func customerInfoDimensions(
        in context: DimensionContext
    ) async throws -> [String: DimensionValue] {
        do {
            return Self.dimensions(
                of: try await self.customerInfoProvider.customerInfo(appUserID: context.appUserID),
                at: context.date
            )
        } catch let error as CancellationError {
            throw error
        } catch {
            Logger.warn(Strings.remoteConfig.customerInfoUnavailable(error))
            return [:]
        }
    }

}

// MARK: - Records

private extension CustomerInfoDimensionProvider {

    static func dimensions(of customerInfo: CustomerInfo, at date: Date) -> [String: DimensionValue] {
        var dimensions: [String: DimensionValue] = [:]
        dimensions.put(Self.originalAppUserIDKey, string: customerInfo.originalAppUserId)
        dimensions.put(Self.firstSeenAtKey, date: customerInfo.firstSeen)
        // The date the backend last answered, which is when it last saw this customer through this device.
        dimensions.put(Self.lastSeenAtKey, date: customerInfo.requestDate)
        dimensions.put(Self.originalPurchasedAtKey, date: customerInfo.originalPurchaseDate)
        dimensions[Self.purchasesKey] = .objectList(Self.purchaseRecords(of: customerInfo, at: date))
        dimensions[Self.entitlementsKey] = .objectList(Self.entitlementRecords(of: customerInfo))
        return dimensions
    }

    /// Newest first, so `purchases.0` is the most recent purchase of any kind and a rule about it
    /// needs no iteration. Subscriptions are ordered by product before the merge, so purchases
    /// sharing a date still come out in a defined order.
    static func purchaseRecords(of customerInfo: CustomerInfo, at date: Date) -> [[String: DimensionValue]] {
        let subscriptions = customerInfo.subscriptionsByProductIdentifier.values
            .sorted { $0.productIdentifier < $1.productIdentifier }
            .map { Self.record(of: $0, at: date) }
        // `CustomerInfo` builds these from a dictionary and orders them by date alone, so two bought
        // at the same instant arrive in no set order. Ordered here so the merge below is repeatable.
        let transactions = customerInfo.nonSubscriptions
            .sorted { lhs, rhs in
                guard lhs.productIdentifier == rhs.productIdentifier else {
                    return lhs.productIdentifier < rhs.productIdentifier
                }
                return lhs.transactionIdentifier < rhs.transactionIdentifier
            }
            .map { Self.record(of: $0) }

        // Ties break on the position built above rather than on `sorted` being stable, which it does
        // not promise to be.
        return (subscriptions + transactions)
            .enumerated()
            .sorted { lhs, rhs in
                let lhsDate = lhs.element.date(for: Self.purchasedAtKey) ?? .distantPast
                let rhsDate = rhs.element.date(for: Self.purchasedAtKey) ?? .distantPast
                guard lhsDate == rhsDate else { return lhsDate > rhsDate }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    static func entitlementRecords(of customerInfo: CustomerInfo) -> [[String: DimensionValue]] {
        return customerInfo.entitlements.all.values
            .sorted { $0.identifier < $1.identifier }
            .map { Self.record(of: $0) }
    }

    static func record(of subscription: SubscriptionInfo, at date: Date) -> [String: DimensionValue] {
        var record: [String: DimensionValue] = [:]
        record.put(Self.kindKey, string: Self.subscriptionKind)
        record.put(Self.productIdentifierKey, string: subscription.productIdentifier)
        record.put(Self.productPlanIdentifierKey, string: subscription.productPlanIdentifier)
        record.put(
            Self.purchasedProductIdentifierKey,
            string: Self.purchasedProductIdentifier(
                productIdentifier: subscription.productIdentifier,
                productPlanIdentifier: subscription.productPlanIdentifier
            )
        )
        record.put(Self.storeTransactionIDKey, string: subscription.storeTransactionId)
        record.put(Self.displayNameKey, string: subscription.displayName)
        record.put(Self.storeKey, string: subscription.store.name)
        record.put(Self.ownershipTypeKey, string: subscription.ownershipType.dimensionValue)
        record.put(Self.periodTypeKey, string: subscription.periodType.dimensionValue)
        record.put(Self.statusKey, string: Self.status(of: subscription, at: date))
        record.put(price: subscription.price)
        record.put(Self.purchasedAtKey, date: subscription.purchaseDate)
        record.put(Self.originalPurchasedAtKey, date: subscription.originalPurchaseDate)
        record.put(Self.expiresAtKey, date: subscription.expiresDate)
        record.put(Self.unsubscribeDetectedAtKey, date: subscription.unsubscribeDetectedAt)
        record.put(Self.billingIssueDetectedAtKey, date: subscription.billingIssuesDetectedAt)
        record.put(Self.gracePeriodExpiresAtKey, date: subscription.gracePeriodExpiresDate)
        record.put(Self.refundedAtKey, date: subscription.refundedAt)
        record.put(Self.autoResumeAtKey, date: subscription.autoResumeDate)
        record.put(Self.isSandboxKey, bool: subscription.isSandbox)
        record.put(Self.isActiveKey, bool: subscription.isActive)
        record.put(Self.willRenewKey, bool: subscription.willRenew)
        // The store keeps serving a subscription while a billing issue is retried and `isActive` does
        // not cover that, so `{"or": [isActive, isInGracePeriod]}` is the still-being-served test.
        record.put(Self.isInGracePeriodKey, bool: Self.isInGracePeriod(subscription, at: date))
        record.put(Self.isRefundedKey, bool: subscription.refundedAt != nil)
        // A resume date is only ever set while a subscription is paused, so having one *is* being paused.
        record.put(Self.isPausedKey, bool: subscription.autoResumeDate != nil)
        return record
    }

    static func record(of transaction: NonSubscriptionTransaction) -> [String: DimensionValue] {
        var record: [String: DimensionValue] = [:]
        record.put(Self.kindKey, string: Self.nonSubscriptionKind)
        record.put(Self.productIdentifierKey, string: transaction.productIdentifier)
        // A one-time purchase has no billing plan, so the two forms of the identifier are the same one.
        record.put(Self.purchasedProductIdentifierKey, string: transaction.productIdentifier)
        record.put(Self.transactionIdentifierKey, string: transaction.transactionIdentifier)
        record.put(Self.storeTransactionIDKey, string: transaction.storeTransactionIdentifier)
        record.put(Self.displayNameKey, string: transaction.displayName)
        record.put(Self.storeKey, string: transaction.store.name)
        record.put(price: transaction.price)
        record.put(Self.purchasedAtKey, date: transaction.purchaseDate)
        record.put(Self.originalPurchasedAtKey, date: transaction.originalPurchaseDate)
        record.put(Self.isSandboxKey, bool: transaction.isSandbox)
        return record
    }

    static func record(of entitlement: EntitlementInfo) -> [String: DimensionValue] {
        var record: [String: DimensionValue] = [:]
        record.put(Self.identifierKey, string: entitlement.identifier)
        record.put(Self.productIdentifierKey, string: entitlement.productIdentifier)
        record.put(Self.productPlanIdentifierKey, string: entitlement.productPlanIdentifier)
        record.put(
            Self.purchasedProductIdentifierKey,
            string: Self.purchasedProductIdentifier(
                productIdentifier: entitlement.productIdentifier,
                productPlanIdentifier: entitlement.productPlanIdentifier
            )
        )
        record.put(Self.storeKey, string: entitlement.store.name)
        record.put(Self.ownershipTypeKey, string: entitlement.ownershipType.dimensionValue)
        record.put(Self.periodTypeKey, string: entitlement.periodType.dimensionValue)
        record.put(Self.latestPurchasedAtKey, date: entitlement.latestPurchaseDate)
        record.put(Self.originalPurchasedAtKey, date: entitlement.originalPurchaseDate)
        record.put(Self.expiresAtKey, date: entitlement.expirationDate)
        record.put(Self.unsubscribeDetectedAtKey, date: entitlement.unsubscribeDetectedAt)
        record.put(Self.billingIssueDetectedAtKey, date: entitlement.billingIssueDetectedAt)
        record.put(Self.isSandboxKey, bool: entitlement.isSandbox)
        record.put(Self.isActiveKey, bool: entitlement.isActive)
        record.put(Self.willRenewKey, bool: entitlement.willRenew)
        return record
    }

}

// MARK: - Derived values

private extension CustomerInfoDimensionProvider {

    /// The billing plan is part of what was bought and is the form the dashboard lists a subscription
    /// under, so it is spelled out rather than left for a rule to concatenate.
    static func purchasedProductIdentifier(
        productIdentifier: String,
        productPlanIdentifier: String?
    ) -> String? {
        return CompoundProductIdentifier(
            productIdentifier: productIdentifier,
            productPlanIdentifier: productPlanIdentifier
        )?.compoundProductIdentifier
    }

    /// Where the customer is in this subscription's lifecycle, so a rule doesn't assemble it from
    /// dates. Most specific first: paused whatever the dates say, then a grace period the store is
    /// still serving through, then the trial or renewal it interrupted.
    ///
    /// `in_billing_retry` and `incomplete` are never reported: once a grace period is over this
    /// device only sees that access lapsed, so a rule needing that reads `billingIssueDetectedAt`.
    static func status(of subscription: SubscriptionInfo, at date: Date) -> String {
        if subscription.autoResumeDate != nil {
            return Self.pausedStatus
        } else if Self.isInGracePeriod(subscription, at: date) {
            return Self.inGracePeriodStatus
        } else if subscription.isActive, subscription.periodType == .trial {
            return Self.trialingStatus
        } else if subscription.isActive {
            return Self.activeStatus
        } else {
            return Self.expiredStatus
        }
    }

    /// The store keeps serving a subscription while a billing issue is retried. Shared by
    /// `isInGracePeriod` and `status` so the two always agree.
    static func isInGracePeriod(_ subscription: SubscriptionInfo, at date: Date) -> Bool {
        guard let gracePeriodExpiresDate = subscription.gracePeriodExpiresDate else { return false }
        return gracePeriodExpiresDate > date
    }

}

private extension PurchaseOwnershipType {

    /// Not a value to compare against: an unknown ownership type is the absence of one.
    var dimensionValue: String? {
        switch self {
        case .purchased: return "PURCHASED"
        case .familyShared: return "FAMILY_SHARED"
        case .unknown: return nil
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

// MARK: - Keys

private extension CustomerInfoDimensionProvider {

    static let appUserIDKey = "appUserId"
    static let entitlementsKey = "entitlements"
    static let firstSeenAtKey = "firstSeenAt"
    static let lastSeenAtKey = "lastSeenAt"
    static let originalAppUserIDKey = "originalAppUserId"
    static let purchasesKey = "purchases"

    static let autoResumeAtKey = "autoResumeAt"
    static let billingIssueDetectedAtKey = "billingIssueDetectedAt"
    static let displayNameKey = "displayName"
    static let expiresAtKey = "expiresAt"
    static let gracePeriodExpiresAtKey = "gracePeriodExpiresAt"
    static let identifierKey = "identifier"
    static let isActiveKey = "isActive"
    static let isInGracePeriodKey = "isInGracePeriod"
    static let isPausedKey = "isPaused"
    static let isRefundedKey = "isRefunded"
    static let isSandboxKey = "isSandbox"
    static let kindKey = "kind"
    static let latestPurchasedAtKey = "latestPurchasedAt"
    static let originalPurchasedAtKey = "originalPurchasedAt"
    static let ownershipTypeKey = "ownershipType"
    static let periodTypeKey = "periodType"
    static let priceAmountMicrosKey = "priceAmountMicros"
    static let priceCurrencyKey = "priceCurrency"
    static let productIdentifierKey = "productIdentifier"
    static let productPlanIdentifierKey = "productPlanIdentifier"
    static let purchasedAtKey = "purchasedAt"
    static let purchasedProductIdentifierKey = "purchasedProductIdentifier"
    static let refundedAtKey = "refundedAt"
    static let statusKey = "status"
    static let storeKey = "store"
    static let storeTransactionIDKey = "storeTransactionId"
    static let transactionIdentifierKey = "transactionIdentifier"
    static let unsubscribeDetectedAtKey = "unsubscribeDetectedAt"
    static let willRenewKey = "willRenew"

    static let nonSubscriptionKind = "nonSubscription"
    static let subscriptionKind = "subscription"

    static let activeStatus = "active"
    static let expiredStatus = "expired"
    static let inGracePeriodStatus = "in_grace_period"
    static let pausedStatus = "paused"
    static let trialingStatus = "trialing"

}

// MARK: - Building records

private extension Dictionary where Key == String, Value == DimensionValue {

    /// Omits empty and missing values: an absent dimension is a non-match rather than an error.
    mutating func put(_ key: String, string: String?) {
        guard let string, !string.isEmpty else { return }
        self[key] = .string(string)
    }

    mutating func put(_ key: String, date: Date?) {
        guard let date else { return }
        self[key] = .date(date)
    }

    mutating func put(_ key: String, bool: Bool) {
        self[key] = .bool(bool)
    }

    /// Prices reach the engine as whole millionths of a currency unit, so a rule compares them
    /// without carrying a fractional amount's rounding.
    ///
    /// The formatted price is deliberately left out: it is rendered in the device's locale, so it is
    /// not something a rule authored once can compare against.
    mutating func put(price: ProductPaidPrice?) {
        guard let price else { return }
        self[CustomerInfoDimensionProvider.priceAmountMicrosKey] = .int(Int64((price.amount * 1_000_000).rounded()))
        self.put(CustomerInfoDimensionProvider.priceCurrencyKey, string: price.currency)
    }

    func date(for key: String) -> Date? {
        guard case .date(let date) = self[key] else { return nil }
        return date
    }

}
