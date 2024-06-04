//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2StoreTransaction.swift
//
//  Created by Nacho Soto on 1/4/22.

import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
internal struct SK2StoreTransaction: StoreTransactionType {

    /// - Parameter environmentOverride: Overrides the environment from the StoreKit 2 transaction.
    /// Used to override the default `Xcode` environment when running tests.
    init(sk2Transaction: SK2Transaction,
         jwsRepresentation: String,
         environmentOverride: StoreEnvironment? = nil) {
        self.underlyingSK2Transaction = sk2Transaction

        self.productIdentifier = sk2Transaction.productID
        self.purchaseDate = sk2Transaction.purchaseDate
        self.transactionIdentifier = String(sk2Transaction.id)
        self.quantity = sk2Transaction.purchasedQuantity
        self.jwsRepresentation = jwsRepresentation
        self.environment = environmentOverride ?? .init(sk2Transaction: sk2Transaction)

        #if swift(>=5.9)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            self.storefront = .init(sk2Storefront: sk2Transaction.storefront)
        } else {
            self.storefront = nil
        }
        #else
        self.storefront = nil
        #endif
    }

    let underlyingSK2Transaction: SK2Transaction

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String
    let quantity: Int
    let storefront: Storefront?
    let jwsRepresentation: String?
    var environment: StoreEnvironment?

    var hasKnownPurchaseDate: Bool { return true }
    var hasKnownTransactionIdentifier: Bool { return true }

    func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        Async.call(with: completion) {
            await self.underlyingSK2Transaction.finish()
        }
    }

}
