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

class TransactionsFactory {

    func nonSubscriptionTransactions(withSubscriptionsData subscriptionsData: [String: [[String: Any]]],
                                     dateFormatter: DateFormatterType) -> [Transaction] {
        subscriptionsData.flatMap { (productId: String, transactionData: [[String: Any]]) -> [Transaction] in
            transactionData.map {
                Transaction(with: $0, productId: productId, dateFormatter: dateFormatter)
            }.compactMap { $0 }
        }.sorted {
            $0.purchaseDate < $1.purchaseDate
        }
    }

}
