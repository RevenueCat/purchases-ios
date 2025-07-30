//
//  TestStoreTransaction.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 30/7/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

struct TestStoreTransaction: StoreTransactionType {

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String

    var hasKnownPurchaseDate: Bool { return true}
    var hasKnownTransactionIdentifier: Bool { return true }

    let quantity: Int

    let storefront: Storefront?

    let jwsRepresentation: String?

    let environment: StoreEnvironment? = nil

    func finish(_ wrapper: any PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        // no-op
        completion()
    }

}
