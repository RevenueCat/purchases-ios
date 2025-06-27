//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Transaction.swift
//
//  Created by Facundo Menzella on 12/5/25.

import Foundation
@_spi(Internal) import RevenueCat

protocol Transaction {

    var productIdentifier: String { get }
    var store: Store { get }
    var type: TransactionType { get }
    var isCancelled: Bool { get }
    var managementURL: URL? { get }
    var price: ProductPaidPrice? { get }
    var periodType: PeriodType { get }
    var purchaseDate: Date { get }
    var unsubscribeDetectedAt: Date? { get }
    var billingIssuesDetectedAt: Date? { get }
    var gracePeriodExpiresDate: Date? { get }
    var refundedAtDate: Date? { get }
    var storeIdentifier: String? { get }
    var identifier: String? { get }
    var isSandbox: Bool { get }
    var originalPurchaseDate: Date? { get }
    var isSubscrition: Bool { get }
}

enum TransactionType {

    case subscription(
        isActive: Bool,
        willRenew: Bool,
        expiresDate: Date?,
        isTrial: Bool,
        ownershipType: PurchaseOwnershipType
    )
    case nonSubscription
}

@_spi(Internal) extension RevenueCat.SubscriptionInfo: Transaction {

    var type: TransactionType {
        .subscription(
            isActive: isActive,
            willRenew: willRenew,
            expiresDate: expiresDate,
            isTrial: periodType == .trial,
            ownershipType: ownershipType
        )
    }

    var isCancelled: Bool {
        unsubscribeDetectedAt != nil && !willRenew
    }

    var refundedAtDate: Date? {
        refundedAt
    }

    var storeIdentifier: String? {
        storeTransactionId
    }

    var identifier: String? {
        nil
    }

    var isSubscrition: Bool {
        true
    }
}

extension NonSubscriptionTransaction: Transaction {

    var type: TransactionType {
        .nonSubscription
    }

    var isCancelled: Bool {
        false
    }

    var managementURL: URL? {
        nil
    }

    var periodType: PeriodType {
        .normal
    }

    var unsubscribeDetectedAt: Date? {
        nil
    }

    var billingIssuesDetectedAt: Date? {
        nil
    }

    var gracePeriodExpiresDate: Date? {
        nil
    }

    var refundedAtDate: Date? {
        nil
    }

    var storeIdentifier: String? {
        storeTransactionIdentifier
    }

    var identifier: String? {
        transactionIdentifier
    }

    var originalPurchaseDate: Date? {
        nil
    }

    var isSubscrition: Bool {
        false
    }
}
