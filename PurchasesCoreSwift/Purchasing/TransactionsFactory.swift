//
//  PurchaserInfoHelper.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCTransactionsFactory) public class TransactionsFactory: NSObject {
    
    @objc public func nonSubscriptionTransactions(withSubscriptionsData subscriptionsData: [String: [[String: Any]]],
                                                  dateFormatter: DateFormatter) -> [Transaction] {
        subscriptionsData.flatMap { (productId: String, transactionData: [[String: Any]]) -> [Transaction] in
            transactionData.map {
                Transaction(with: $0, productId: productId, dateFormatter: dateFormatter)
            }
        }.sorted {
            $0.purchaseDate < $1.purchaseDate
        }
    }
    
}
