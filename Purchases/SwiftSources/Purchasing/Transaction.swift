//
//  Transaction.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCTransaction) public class Transaction: NSObject {

    @available(*, unavailable, message: "Use init(transactionId, productId, purchaseDate) instead")
    override init() {
        fatalError("init() has not been implemented")
    }

    let revenueCatId: String
    let productId: String
    let purchaseDate: Date

    init(transactionId: String, productId: String, purchaseDate: Date) {
        self.revenueCatId = transactionId
        self.productId = productId
        self.purchaseDate = purchaseDate
        super.init()
    }

    init(with serverResponse: [String: Any], productId: String, dateFormatter: DateFormatter) {
        guard let revenueCatId = serverResponse["id"] as? String,
              let dateString = serverResponse["purchase_date"] as? String,
              let purchaseDate = dateFormatter.date(from: dateString) else {
            fatalError("""
                       Couldn't initialize Transaction from dictionary. 
                       Reason: unexpected format. Dictionary: \(serverResponse).
                       """)
        }

        self.revenueCatId = revenueCatId
        self.purchaseDate = purchaseDate
        self.productId = productId
        super.init()
    }

}
