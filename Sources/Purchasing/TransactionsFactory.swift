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
    ) -> [NonSubscriptionTransaction] {
        subscriptionsData
            .flatMap { (productID, transactions) -> [NonSubscriptionTransaction] in
                transactions
                    .lazy
                    .compactMap { NonSubscriptionTransaction(with: $0, productID: productID) }
            }
            .sorted { $0.purchaseDate < $1.purchaseDate }
    }

}
