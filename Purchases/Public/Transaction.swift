//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Transaction.swift
//
//  Created by RevenueCat.
//

import Foundation

@objc(RCTransaction) public class Transaction: NSObject {

    @objc public let revenueCatId: String
    @objc public let productId: String
    @objc public let purchaseDate: Date

    @objc public init(transactionId: String, productId: String, purchaseDate: Date) {
        self.revenueCatId = transactionId
        self.productId = productId
        self.purchaseDate = purchaseDate
    }

    internal init?(with serverResponse: [String: Any], productId: String, dateFormatter: DateFormatterType) {
        guard let revenueCatId = serverResponse["id"] as? String,
              let dateString = serverResponse["purchase_date"] as? String,
              let purchaseDate = dateFormatter.date(from: dateString) else {
            Logger.error("Couldn't initialize Transaction from dictionary. " +
                         "Reason: unexpected format. Dictionary: \(serverResponse).")
            return nil
        }

        self.revenueCatId = revenueCatId
        self.purchaseDate = purchaseDate
        self.productId = productId
    }

}
