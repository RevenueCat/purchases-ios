//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK1StoreTransaction.swift
//
//  Created by Nacho Soto on 1/4/22.

import StoreKit

internal struct SK1StoreTransaction: StoreTransactionType {

    init(sk1Transaction: SK1Transaction) {
        self.underlyingSK1Transaction = sk1Transaction

        self.productIdentifier = sk1Transaction.productIdentifier ?? ""
        self.purchaseDate = sk1Transaction.purchaseDate
        self.transactionIdentifier = sk1Transaction.transactionID
        self.quantity = sk1Transaction.quantity
    }

    let underlyingSK1Transaction: SK1Transaction

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String
    let quantity: Int

}

extension SKPaymentTransaction {

    var productIdentifier: String? {
        guard let payment = self.maybePayment else { return nil }

        guard let productIdentifier = payment.productIdentifier as String?,
              !productIdentifier.isEmpty else {
                  Logger.appleWarning(Strings.purchase.skpayment_missing_product_identifier)
                  return nil
              }

        return productIdentifier
    }

    fileprivate var purchaseDate: Date {
        guard let date = self.transactionDate else {
            Logger.appleWarning(Strings.purchase.sktransaction_missing_transaction_date)

            return Date(timeIntervalSince1970: 0)
        }

        return date
    }

    fileprivate var transactionID: String {
        guard let identifier = self.transactionIdentifier else {
            Logger.appleWarning(Strings.purchase.sktransaction_missing_transaction_identifier)

            return UUID().uuidString
        }

        return identifier
    }

    fileprivate var quantity: Int {
        return self.maybePayment?.quantity ?? 1
    }

    /// Considering issue https://github.com/RevenueCat/purchases-ios/issues/279, sometimes `payment`
    /// and `productIdentifier` can be `nil`, in this case, they must be treated as nullable.
    /// Due of that an optional reference is created so that the compiler would allow us to check for nullability.
    private var maybePayment: SKPayment? {
        guard let payment = self.payment as SKPayment? else {
            Logger.appleWarning(Strings.purchase.skpayment_missing_from_skpaymenttransaction)
            return nil
        }

        return payment
    }
}
