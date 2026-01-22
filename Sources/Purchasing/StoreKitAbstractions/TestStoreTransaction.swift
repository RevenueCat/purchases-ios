//
//  TestStoreTransaction.swift
//  RevenueCat
//
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

/// Internal struct used to create `StoreTransaction` instances for testing purposes.
/// This allows developers to mock `StoreTransaction` objects in unit tests.
struct TestStoreTransaction: StoreTransactionType {

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String
    let quantity: Int
    let storefront: Storefront?

    var hasKnownPurchaseDate: Bool { return true }
    var hasKnownTransactionIdentifier: Bool { return true }

    let jwsRepresentation: String? = nil
    let environment: StoreEnvironment? = nil

    func finish(_ wrapper: any PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        // no-op
        completion()
    }

}
