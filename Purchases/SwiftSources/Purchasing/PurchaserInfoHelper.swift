//
//  PurchaserInfoHelper.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc public class PurchaserInfoHelper: NSObject {

    @objc public class func initNonSubscriptionTransactions(with data: [String: [[String: Any]]], dateFormatter: DateFormatter) -> [Transaction] {
        data.flatMap { (productId: String, transactionData: [[String: Any]]) -> [Transaction] in
            transactionData.map {
                Transaction(with: $0, productId: productId, dateFormatter: dateFormatter)
            }
        }.sorted {
            $0.purchaseDate < $1.purchaseDate
        }
    }

}
