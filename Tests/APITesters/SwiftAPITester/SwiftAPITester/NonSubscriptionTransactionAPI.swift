//
//  NonSubscriptionTransaction.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 6/23/22.
//

import Foundation
import RevenueCat

private var transaction: NonSubscriptionTransaction!

func checkNonSubscriptionTransactionAPI() {
    let _: String = transaction.productIdentifier
    let _: Date = transaction.purchaseDate
    let _: String = transaction.transactionIdentifier
}
