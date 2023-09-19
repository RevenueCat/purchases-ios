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
    private let _stubbedLastVerifiedTransaction: Atomic<StoreTransaction?> = .init(nil)
    private let _stubbedHasPendingConsumablePurchase: Atomic<Bool> = false

    var stubbedUnfinishedTransactions: [StoreTransaction] {
        get { return self._stubbedUnfinishedTransactions.value }
        set { self._stubbedUnfinishedTransactions.value = newValue }
    }

    var stubbedLastVerifiedTransaction: StoreTransaction? {
        get { return self._stubbedLastVerifiedTransaction.value }
        set { self._stubbedLastVerifiedTransaction.value = newValue }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] {
        get async {
            return self.stubbedUnfinishedTransactions
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func fetchLastVerifiedTransaction(completion: @escaping (RevenueCat.StoreTransaction?) -> Void) {
        completion(self.stubbedLastVerifiedTransaction)
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
