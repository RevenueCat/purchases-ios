//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NonPurchaseTransaction.swift
//
//  Created by Nacho Soto on 6/23/22.

import Foundation

/// Information that represents a non-subscription purchase made by a user.
/// 
/// This can be one of these types of product:
/// - Consumables
/// - Non-consumables
/// - Non-renewing subscriptions
@objc(RCNonSubscriptionTransaction)
public final class NonSubscriptionTransaction: NSObject {

    /// The product identifier.
    @objc public let productIdentifier: String

    /// The date that App Store charged the user’s account.
    @objc public let purchaseDate: Date

    /// Date of the original store transaction. Earlier than ``purchaseDate`` on a restore.
    /// `nil` when the store never reported one.
    @objc public let originalPurchaseDate: Date?

    /// The unique identifier for the transaction created by RevenueCat.
    @objc public let transactionIdentifier: String

    /// The unique identifier for the transaction created by the Store.
    @objc public let storeTransactionIdentifier: String

    /// The ``Store`` where this transaction was performed.
    @objc public let store: Store

    /// Paid price for the subscription
    @objc public let price: ProductPaidPrice?

    /// Whether or not the purchase was made in sandbox mode.
    @objc public let isSandbox: Bool

    /// The display name of the product as configured in the RevenueCat dashboard.
    @objc public let displayName: String?

    init?(with transaction: CustomerInfoResponse.Transaction, productID: String) {
        guard let transactionIdentifier = transaction.transactionIdentifier,
              let storeTransactionIdentifier = transaction.storeTransactionIdentifier else {
            Logger.error("Couldn't initialize NonSubscriptionTransaction. " +
                         "Reason: missing data: \(transaction).")
            return nil
        }

        self.transactionIdentifier = transactionIdentifier
        self.storeTransactionIdentifier = storeTransactionIdentifier
        self.purchaseDate = transaction.purchaseDate
        self.originalPurchaseDate = transaction.originalPurchaseDate
        self.displayName = transaction.displayName
        self.productIdentifier = productID
        self.store = transaction.store
        self.price = transaction.price.map { ProductPaidPrice(currency: $0.currency, amount: $0.amount) }
        self.isSandbox = transaction.isSandbox
    }

    public override var description: String {
        return """
        <\(String(describing: NonSubscriptionTransaction.self)):
            productIdentifier=\(self.productIdentifier)
            purchaseDate=\(self.purchaseDate)
            originalPurchaseDate=\(String(describing: self.originalPurchaseDate))
            displayName=\(self.displayName ?? "null")
            transactionIdentifier=\(self.transactionIdentifier)
            storeTransactionIdentifier=\(self.storeTransactionIdentifier)
        >
        """
    }

}

extension NonSubscriptionTransaction: Sendable {}
