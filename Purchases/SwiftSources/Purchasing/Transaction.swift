//
//  Transaction.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCTransaction) public class Transaction: NSObject {

    required override init() { fatalError("init() has not been implemented") }

    let revenueCatId: String
    let productId: String
    let purchaseDate: Date

    init(transactionId: String, productId: String, purchaseDate: Date) {
        self.revenueCatId = transactionId
        self.productId = productId
        self.purchaseDate = purchaseDate
        super.init()
    }

    internal init(with data: [String: Any], productId: String, dateFormatter: DateFormatter) {
        guard let revenueCatId = data["id"] as? String,
              let dateString = data["purchase_date"] as? String,
              let purchaseDate = dateFormatter.date(from: dateString) else {
            fatalError("couldn't initialize Transaction from dictionary. Reason: unexpected format. Dictionary: \(data).")
        }

        self.revenueCatId = revenueCatId
        self.purchaseDate = purchaseDate
        self.productId = productId
        super.init()
    }

}
