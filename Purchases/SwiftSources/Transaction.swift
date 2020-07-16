//
//  Transaction.swift
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCTransaction) public class Transaction: NSObject {

    let transactionId: String
    let productId: String
    let purchaseDate: Date

    public init(transactionId: String, productId: String, purchaseDate: Date) {
        self.transactionId = transactionId
        self.productId = productId
        self.purchaseDate = purchaseDate
        super.init()
    }

}
