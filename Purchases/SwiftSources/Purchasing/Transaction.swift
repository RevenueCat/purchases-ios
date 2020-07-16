//
//  Transaction.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCTransaction) public class Transaction: NSObject {

    let revenuecatId: String
    let productId: String
    let purchaseDate: Date

    internal init(transactionId: String, productId: String, purchaseDate: Date) {
        self.revenuecatId = transactionId
        self.productId = productId
        self.purchaseDate = purchaseDate
        super.init()
    }

    internal init(with data: Dictionary<String, Any>, productId: String, dateFormatter: DateFormatter) {
        self.revenuecatId = data["id"] as! String
        self.productId = productId
        let dateString = data["purchase_date"] as! String
        self.purchaseDate = dateFormatter.date(from: dateString)!
        super.init()
    }

}
