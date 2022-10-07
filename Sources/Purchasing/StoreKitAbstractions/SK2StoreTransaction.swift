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

    init(sk2Transaction: SK2Transaction) {
        self.underlyingSK2Transaction = sk2Transaction

        self.productIdentifier = sk2Transaction.productID
        self.purchaseDate = sk2Transaction.purchaseDate
        self.transactionIdentifier = String(sk2Transaction.id)
        self.quantity = sk2Transaction.purchasedQuantity
    }

    let underlyingSK2Transaction: SK2Transaction

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String
    let quantity: Int

    func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        Async.call(with: completion) {
            await self.underlyingSK2Transaction.finish()
        }
    }

}

#if swift(<5.7)
// `@unchecked` because:
// - `Date` is not `Sendable` until Swift 5.7
// - `SK2Transaction` is not `Sendable` until Swift 5.7
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SK2StoreTransaction: @unchecked Sendable {}
#endif
