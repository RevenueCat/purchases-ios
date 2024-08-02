//
//  StoreTransactionAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import StoreKit

import RevenueCat_CustomEntitlementComputation

private  var transaction: StoreTransaction!
func checkStoreTransactionAPI() {
    let productIdentifier: String = transaction.productIdentifier
    let purchaseDate: Date = transaction.purchaseDate
    let transactionIdentifier: String = transaction.transactionIdentifier
    let quantity: Int = transaction.quantity

    let sk1: SKPaymentTransaction? = transaction.sk1Transaction
    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let sk2: StoreKit.Transaction? = transaction.sk2Transaction
        print(sk2!)
    }

    print(
        productIdentifier,
        purchaseDate,
        transactionIdentifier,
        quantity,
        sk1!
    )
}
