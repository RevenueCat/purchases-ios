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

@objc(RCSubscriptionInfo) public final class SubscriptionInfo: NSObject {

    @objc public let purchaseDate: Date
    @objc public let originalPurchaseDate: Date?
    @objc public let expiresDate: Date?
    @objc public let store: Store
    @objc public let isSandbox: Bool
    @objc public let unsubscribeDetectedAt: Date?
    @objc public let billingIssuesDetectedAt: Date?
    @objc public let gracePeriodExpiresDate: Date?
    @objc public let ownershipType: PurchaseOwnershipType
    @objc public let periodType: PeriodType
    @objc public let refundedAt: Date?
    @objc public let storeTransactionId: String?

    init(purchaseDate: Date,
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
         storeTransactionId: String?) {
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
            storeTransactionId: \(storeTransactionId)
        }
        """
    }

}

extension SubscriptionInfo: Sendable {}
