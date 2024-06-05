//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2TransactionFetcher.swift
//
//  Created by Nacho Soto on 5/23/23.

import Foundation
@testable import RevenueCat

final class MockStoreKit2TransactionFetcher: StoreKit2TransactionFetcherType {

    private let _stubbedUnfinishedTransactions: Atomic<[StoreTransaction]> = .init([])
    private let _stubbedFirstVerifiedTransaction: Atomic<StoreTransaction?> = .init(nil)
    private let _stubbedFirstVerifiedAutoRenewableTransaction: Atomic<StoreTransaction?> = .init(nil)
    private let _stubbedHasPendingConsumablePurchase: Atomic<Bool> = false
    private let _stubbedReceipt: Atomic<StoreKit2Receipt?> = .init(nil)

    var stubbedUnfinishedTransactions: [StoreTransaction] {
        get { return self._stubbedUnfinishedTransactions.value }
        set { self._stubbedUnfinishedTransactions.value = newValue }
    }

    var stubbedFirstVerifiedTransaction: StoreTransaction? {
        get { return self._stubbedFirstVerifiedTransaction.value }
        set { self._stubbedFirstVerifiedTransaction.value = newValue }
    }

    var stubbedReceipt: StoreKit2Receipt? {
        get { return self._stubbedReceipt.value }
        set { self._stubbedReceipt.value = newValue }
    }

    var stubbedFirstVerifiedAutoRenewableTransaction: StoreTransaction? {
        get { return self._stubbedFirstVerifiedAutoRenewableTransaction.value }
        set { self._stubbedFirstVerifiedAutoRenewableTransaction.value = newValue }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] {
        get async {
            return self.stubbedUnfinishedTransactions
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func fetchReceipt(containing transaction: StoreTransactionType) async -> StoreKit2Receipt {
        return self.stubbedReceipt!
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedTransaction: RevenueCat.StoreTransaction? {
        get async {
            self.stubbedFirstVerifiedTransaction
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedAutoRenewableTransaction: RevenueCat.StoreTransaction? {
        get async {
            self.stubbedFirstVerifiedAutoRenewableTransaction
        }
    }

    // MARK: -

    var stubbedHasPendingConsumablePurchase: Bool {
        get { return self._stubbedHasPendingConsumablePurchase.value }
        set { self._stubbedHasPendingConsumablePurchase.value = newValue }
    }

    var hasPendingConsumablePurchase: Bool {
        return self.stubbedHasPendingConsumablePurchase
    }

}
