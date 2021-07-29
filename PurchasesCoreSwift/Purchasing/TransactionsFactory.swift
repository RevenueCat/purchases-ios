//
//  PurchaserInfoHelper.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCTransactionsFactory) public class TransactionsFactory: NSObject {

    @objc public func nonSubscriptionTransactions(
        withSubscriptionsData subscriptionsData: [String: [[String: Any]]]) -> [Transaction] {
        nonSubscriptionTransactions(withSubscriptionsData: subscriptionsData)
    }

    func nonSubscriptionTransactions(withSubscriptionsData subscriptionsData: [String: [[String: Any]]],
                                     dateFormatter: DateFormatter = .iso8601SecondsDateFormatter) -> [Transaction] {
        subscriptionsData.flatMap { (productId: String, transactionData: [[String: Any]]) -> [Transaction] in
            transactionData.map {
                Transaction(with: $0, productId: productId, dateFormatter: dateFormatter)
            }.compactMap { $0 }
        }.sorted {
            $0.purchaseDate < $1.purchaseDate
        }
    }

}
