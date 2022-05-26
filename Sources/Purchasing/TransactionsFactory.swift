//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionsFactory.swift
//
//  Created by RevenueCat.
//

import Foundation

enum TransactionsFactory {

    static func nonSubscriptionTransactions(
        withSubscriptionsData subscriptionsData: [String: [CustomerInfoResponse.Transaction]]
    ) -> [StoreTransaction] {
        subscriptionsData
            .flatMap { (productID, transactions) -> [StoreTransaction] in
                transactions
                    .lazy
                    .compactMap { BackendParsedTransaction(with: $0, productID: productID) }
                    .map { StoreTransaction($0) }
            }
            .sorted { $0.purchaseDate < $1.purchaseDate }
    }

}

/// `StoreTransactionType` backed by data parsed from the server
private struct BackendParsedTransaction: StoreTransactionType {

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String
    let quantity: Int

    init?(with transaction: CustomerInfoResponse.Transaction, productID: String) {
        guard let transactionIdentifier = transaction.transactionIdentifier,
                let purchaseDate = transaction.purchaseDate else {
            Logger.error("Couldn't initialize Transaction. " +
                         "Reason: missing data: \(transaction).")
            return nil
        }

        self.transactionIdentifier = transactionIdentifier
        self.purchaseDate = purchaseDate
        self.productIdentifier = productID
        // Defaulting to `1` since multi-quantity purchases aren't currently supported.
        self.quantity = 1
    }

}
