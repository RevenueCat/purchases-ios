//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreKit2TransactionListenerDelegate.swift
//
//  Created by Nacho Soto on 11/14/22.

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class MockStoreKit2TransactionListenerDelegate: StoreKit2TransactionListenerDelegate {

    var invokedTransactionUpdated: Bool { return self._invokedTransactionUpdated.value }
    var updatedTransactions: [StoreTransactionType] { return self._updatedTransactions.value }
    var fakeHandlingDelay: DispatchTimeInterval {
        get { return self._fakeHandlingDelay.value }
        set { self._fakeHandlingDelay.value = newValue }
    }
    var receivedConcurrentRequest: Bool {
        return self._receivedConcurrentRequest.value
    }

    private let _invokedTransactionUpdated: Atomic<Bool> = false
    private let _updatedTransactions: Atomic<[StoreTransactionType]> = .init([])

    // Useful for detecting if this listener receives concurrent requests
    private let _fakeHandlingDelay: Atomic<DispatchTimeInterval> = .init(.never)
    private let _wasHandlingRequest: Atomic<Bool> = false
    private let _receivedConcurrentRequest: Atomic<Bool> = false

    func storeKit2TransactionListener(
        _ listener: StoreKit2TransactionListenerType,
        updatedTransaction transaction: StoreTransactionType
    ) async throws {
        if self._wasHandlingRequest.value {
            self._receivedConcurrentRequest.value = true
        }

        self._wasHandlingRequest.value = true
        defer { self._wasHandlingRequest.value = false }

        self._invokedTransactionUpdated.value = true
        self._updatedTransactions.value.append(transaction)

        try await Task.sleep(nanoseconds: self.fakeHandlingDelay.nanoseconds)
    }

}
