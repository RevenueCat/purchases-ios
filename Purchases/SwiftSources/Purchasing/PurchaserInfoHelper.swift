//
//  PurchaserInfoHelper.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc public class PurchaserInfoHelper: NSObject {

    @objc public class func initNonSubscriptionTransactions(with data: Dictionary<String, Array<Dictionary<String, Any>>>, dateFormatter: DateFormatter) -> Array<Transaction> {
        data.flatMap { (productId: String, transactionData: Array<Dictionary<String, Any>>) -> Array<Transaction> in
            transactionData.map { Transaction(with: $0, productId: productId, dateFormatter: dateFormatter) }
        }.sorted { $0.purchaseDate < $1.purchaseDate }
    }

}
