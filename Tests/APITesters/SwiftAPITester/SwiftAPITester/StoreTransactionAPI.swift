//
//  StoreTransactionAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import StoreKit

import RevenueCat

private var transaction: StoreTransaction!
func checkStoreTransactionAPI() {
    let _: String = transaction.productIdentifier
    let _: Date = transaction.purchaseDate
    let _: String = transaction.transactionIdentifier
    let _: Int = transaction.quantity
    let _: RevenueCat.Storefront? = transaction.storefront

    let _: SKPaymentTransaction? = transaction.sk1Transaction

    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let _: StoreKit.Transaction? = transaction.sk2Transaction
    }
}
