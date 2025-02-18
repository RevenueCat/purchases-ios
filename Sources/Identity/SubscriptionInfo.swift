//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionInfo.swift
//
//  Created by Cesar de la Vega on 21/11/24.

import Foundation

/// Subscription purchases of the Customer
@objc(RCSubscriptionInfo) public final class SubscriptionInfo: NSObject {

    /// The product identifier.
    @objc public let productIdentifier: ProductIdentifier

    /// Date when the last subscription period started.
    @objc public let purchaseDate: Date

    /// Date when this subscription first started. This property does not update with renewals.
    /// This property also does not update for product changes within a subscription group or 
    /// resubscriptions by lapsed subscribers.
    @objc public let originalPurchaseDate: Date?

    /// Date when the subscription expires/expired
    @objc public let expiresDate: Date?

    /// Store where the subscription was purchased.
    @objc public let store: Store

    /// Whether or not the purchase was made in sandbox mode.
    @objc public let isSandbox: Bool

    /// Date when RevenueCat detected that auto-renewal was turned off for this subsription.
    /// Note the subscription may still be active, check the ``expiresDate`` attribute.
    @objc public let unsubscribeDetectedAt: Date?

    /// Date when RevenueCat detected any billing issues with this subscription.
    /// If and when the billing issue gets resolved, this field is set to nil.
    /// Note the subscription may still be active, check the ``expiresDate`` attribute.
    @objc public let billingIssuesDetectedAt: Date?

    /// Date when any grace period for this subscription expires/expired.
    /// nil if the customer has never been in a grace period.
    @objc public let gracePeriodExpiresDate: Date?

    /// How the Customer received access to this subscription:
    /// - ``PurchaseOwnershipType/purchased``: The customer bought the subscription.
    /// - ``PurchaseOwnershipType/familyShared``: The Customer has access to the product via their family.
    @objc public let ownershipType: PurchaseOwnershipType

    /// Type of the current subscription period:
    /// - ``PeriodType/normal``: The product is in a normal period (default)
    /// - ``PeriodType/trial``: The product is in a free trial period
    /// - ``PeriodType/intro``: The product is in an introductory pricing period
    @objc public let periodType: PeriodType

    /// Date when RevenueCat detected a refund of this subscription.
    @objc public let refundedAt: Date?

    /// The transaction id in the store of the subscription.
    @objc public let storeTransactionId: String?

    /// Whether the subscription is currently active.
    @objc public let isActive: Bool

    /// Whether the subscription will renew at the next billing period.
    @objc public let willRenew: Bool

    /// Paid price for the subscription
    @objc public let price: ProductPaidPrice?

    init(productIdentifier: String,
         purchaseDate: Date,
         originalPurchaseDate: Date?,
         expiresDate: Date?,
         store: Store,
         isSandbox: Bool,
         unsubscribeDetectedAt: Date?,
         billingIssuesDetectedAt: Date?,
         gracePeriodExpiresDate: Date?,
         ownershipType: PurchaseOwnershipType,
         periodType: PeriodType,
         refundedAt: Date?,
         storeTransactionId: String?,
         requestDate: Date,
         price: ProductPaidPrice?) {
        self.productIdentifier = productIdentifier
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.expiresDate = expiresDate
        self.store = store
        self.isSandbox = isSandbox
        self.unsubscribeDetectedAt = unsubscribeDetectedAt
        self.billingIssuesDetectedAt = billingIssuesDetectedAt
        self.gracePeriodExpiresDate = gracePeriodExpiresDate
        self.ownershipType = ownershipType
        self.periodType = periodType
        self.refundedAt = refundedAt
        self.storeTransactionId = storeTransactionId
        self.isActive = CustomerInfo.isDateActive(expirationDate: expiresDate, for: requestDate)
        self.willRenew = EntitlementInfo.willRenewWithExpirationDate(expirationDate: expiresDate,
                                                                     store: store,
                                                                     unsubscribeDetectedAt: unsubscribeDetectedAt,
                                                                     billingIssueDetectedAt: billingIssuesDetectedAt,
                                                                     periodType: periodType)
        self.price = price

        super.init()
    }

    public override var description: String {
        return """
        SubscriptionInfo {
            purchaseDate: \(String(describing: purchaseDate)),
            originalPurchaseDate: \(String(describing: originalPurchaseDate)),
            expiresDate: \(String(describing: expiresDate)),
            store: \(store),
            isSandbox: \(isSandbox),
            unsubscribeDetectedAt: \(String(describing: unsubscribeDetectedAt)),
            billingIssuesDetectedAt: \(String(describing: billingIssuesDetectedAt)),
            gracePeriodExpiresDate: \(String(describing: gracePeriodExpiresDate)),
            ownershipType: \(ownershipType),
            periodType: \(String(describing: periodType)),
            refundedAt: \(String(describing: refundedAt)),
            storeTransactionId: \(String(describing: storeTransactionId)),
            isActive: \(isActive),
            willRenew: \(willRenew)
        }
        """
    }

}

extension SubscriptionInfo: Sendable {}
