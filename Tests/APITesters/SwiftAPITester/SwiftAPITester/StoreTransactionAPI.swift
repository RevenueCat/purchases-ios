//
//  StoreTransactionAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import StoreKit

import RevenueCat

private  var transaction: StoreTransaction!
func checkStoreTransactionAPI() {
    let productIdentifier: String = transaction.productIdentifier
    let purchaseDate: Date = transaction.purchaseDate
    let transactionIdentifier: String = transaction.transactionIdentifier
    let quantity: Int = transaction.quantity

    let sk1: SKPaymentTransaction? = transaction.sk1Transaction
    let sk2: StoreKit.Transaction? = transaction.sk2Transaction

    print(
        productIdentifier,
        purchaseDate,
        transactionIdentifier,
        quantity,
        sk1!,
        sk2!
    )
}
