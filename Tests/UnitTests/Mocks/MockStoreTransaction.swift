//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreTransaction.swift
//
//  Created by Nacho Soto on 11/14/22.

@testable import RevenueCat
import StoreKit

final class MockStoreTransaction: StoreTransactionType {

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String
    let quantity: Int
    let storefront: RevenueCat.Storefront?

    init() {
        self.productIdentifier = UUID().uuidString
        self.purchaseDate = Date()
        self.transactionIdentifier = UUID().uuidString
        self.quantity = 1
        self.storefront = nil
    }

    private let _hasKnownPurchaseDate: Atomic<Bool> = true
    var hasKnownPurchaseDate: Bool {
        get { return self._hasKnownPurchaseDate.value }
        set { self._hasKnownPurchaseDate.value = newValue }
    }

    private let _finishInvoked: Atomic<Bool> = false
    var finishInvoked: Bool { return self._finishInvoked.value }

    private let _onFinishInvoked: Atomic<(() -> Void)?> = nil
    var onFinishInvoked: (() -> Void)? {
        get { return self._onFinishInvoked.value }
        set { self._onFinishInvoked.value = newValue }
    }

    func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        self._finishInvoked.value = true
        self.onFinishInvoked?()

        completion()
    }

}

#if swift(<5.7)
// `@unchecked` because:
// - `Date` is not `Sendable` until Swift 5.7
extension MockStoreTransaction: @unchecked Sendable {}
#endif
