//
//  SimulatedStoreTransaction.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 30/7/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

struct SimulatedStoreTransaction: StoreTransactionType, Equatable {

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String

    var hasKnownPurchaseDate: Bool { return true }
    var hasKnownTransactionIdentifier: Bool { return true }
    var quantity: Int { return 1 }

    let storefront: Storefront?

    let jwsRepresentation: String?

    let environment: StoreEnvironment? = nil
    let reason: TransactionReason? = nil
    let revocationDate: Date? = nil
    let revocationReason: RevocationReason? = nil

    func finish(_ wrapper: any PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        // no-op
        completion()
    }

}
