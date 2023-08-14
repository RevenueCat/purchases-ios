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

    /// The unique identifier for the transaction created by RevenueCat.
    @objc public let transactionIdentifier: String

    /// The unique identifier for the transaction created by the Store.
    @objc internal let storeTransactionIdentifier: String

    init?(with transaction: CustomerInfoResponse.Transaction, productID: String) {
        guard let transactionIdentifier = transaction.transactionIdentifier,
              let storeTransactionIdentifier = transaction.storeTransactionIdentifier,
              let purchaseDate = transaction.purchaseDate else {
            Logger.error("Couldn't initialize NonSubscriptionTransaction. " +
                         "Reason: missing data: \(transaction).")
            return nil
        }

        self.transactionIdentifier = transactionIdentifier
        self.storeTransactionIdentifier = storeTransactionIdentifier
        self.purchaseDate = purchaseDate
        self.productIdentifier = productID
    }

    public override var description: String {
        return """
        <\(String(describing: NonSubscriptionTransaction.self)):
            productIdentifier=\(self.productIdentifier)
            purchaseDate=\(self.purchaseDate)
            transactionIdentifier=\(self.transactionIdentifier)
            storeTransactionIdentifier=\(self.storeTransactionIdentifier)
        >
        """
    }

}

#if swift(>=5.7)
extension NonSubscriptionTransaction: Sendable {}
#else
// `@unchecked` because:
// - `Date` is not `Sendable` until Swift 5.7
extension NonSubscriptionTransaction: @unchecked Sendable {}
#endif
