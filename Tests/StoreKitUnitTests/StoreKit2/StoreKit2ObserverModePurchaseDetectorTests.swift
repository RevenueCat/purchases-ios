//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ObserverModePurchaseDetectorTests.swift
//
//  Created by Will Taylor on 5/1/24.

import Foundation

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
// swiftlint:disable type_name
class StoreKit2ObserverModePurchaseDetectorTests: StoreKitConfigTestCase {

    private let appUserID = "mockAppUserID"
    private var deviceCache: MockDeviceCache!

    private var observerModePurchaseDetector: StoreKit2ObserverModePurchaseDetector!

    override func setUp() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        deviceCache = .init()
    }

    func testDetectUnobservedTransactionsDoesntCallDelegateWith0Transactions() async {
        let allTransactionsProvider = MockAllTransactionsProvider(mockedTransactions: [])

        let delegate = MockStoreKit2ObserverModePurchaseDetectorDelegate()

        observerModePurchaseDetector = .init(
            deviceCache: deviceCache,
            allTransactionsProvider: allTransactionsProvider
        )

        await observerModePurchaseDetector.detectUnobservedTransactions(delegate: delegate)

        expect(delegate.handleSK2ObserverModeTransactionCalled) == false

        expect(self.deviceCache.invokedReadCachedSyncedSK2ObserverModeTransactionIDs) == false
        expect(self.deviceCache.invokedRegisterNewSyncedSK2ObserverModeTransactionID) == false
    }

    func testDetectUnobservedTransactionsCallsDelegateUnobservedTransactions() async throws {
        let txn1 = try await self.simulateAnyPurchase(finishTransaction: true)
        let allTransactionsProvider = MockAllTransactionsProvider(mockedTransactions: [txn1])
        let delegate = MockStoreKit2ObserverModePurchaseDetectorDelegate()

        observerModePurchaseDetector = .init(
            deviceCache: deviceCache,
            allTransactionsProvider: allTransactionsProvider
        )

        await observerModePurchaseDetector.detectUnobservedTransactions(delegate: delegate)

        // Validate calls to delegate
        expect(delegate.handleSK2ObserverModeTransactionCalled) == true
        expect(delegate.handleSK2ObserverModeTransactionCount) == 1
        guard let delegateInvocation = delegate.handleSK2ObserverModeTransactionInvocations.first else {
            fail("No delegate invocations were found.")
            return
        }
        expect(delegateInvocation.verifiedTransaction) == txn1.verifiedTransaction
        expect(delegateInvocation.jwsRepresentation) == txn1.jwsRepresentation

        // Validate cache state
        expect(self.deviceCache.invokedReadCachedSyncedSK2ObserverModeTransactionIDs) == true
        expect(self.deviceCache.invokedRegisterNewSyncedSK2ObserverModeTransactionID) == true
    }

    // Since the transaction is cached when it is detected for the first time, we don't expect
    // the delegate to be called again for this transaction in the future.
    func testDetectUnobservedTransactionsCallsDelegateOncePerUnobservedTransactions() async throws {
        let txn1 = try await self.simulateAnyPurchase(finishTransaction: true)
        let allTransactionsProvider = MockAllTransactionsProvider(mockedTransactions: [txn1])
        let delegate = MockStoreKit2ObserverModePurchaseDetectorDelegate()

        observerModePurchaseDetector = .init(
            deviceCache: deviceCache,
            allTransactionsProvider: allTransactionsProvider
        )

        await observerModePurchaseDetector.detectUnobservedTransactions(delegate: delegate)
        await observerModePurchaseDetector.detectUnobservedTransactions(delegate: delegate)

        // Validate calls to delegate
        expect(delegate.handleSK2ObserverModeTransactionCalled) == true
        expect(delegate.handleSK2ObserverModeTransactionCount) == 1
        guard let delegateInvocation = delegate.handleSK2ObserverModeTransactionInvocations.first else {
            fail("No delegate invocations were found.")
            return
        }
        expect(delegateInvocation.verifiedTransaction) == txn1.verifiedTransaction
        expect(delegateInvocation.jwsRepresentation) == txn1.jwsRepresentation

        // Validate cache state
        expect(self.deviceCache.invokedReadCachedSyncedSK2ObserverModeTransactionIDs) == true
        expect(self.deviceCache.invokedRegisterNewSyncedSK2ObserverModeTransactionID) == true
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
// Unchecked since it's a mock
final class MockStoreKit2ObserverModePurchaseDetectorDelegate: StoreKit2ObserverModePurchaseDetectorDelegate,
                                                               @unchecked Sendable {

    var handleSK2ObserverModeTransactionCalled = false
    var handleSK2ObserverModeTransactionCount = 0
    var handleSK2ObserverModeTransactionInvocations: [HandleSK2ObserverModeTransactionInvocation] = []
    struct HandleSK2ObserverModeTransactionInvocation {
        let verifiedTransaction: Transaction
        let jwsRepresentation: String
    }

    func handleSK2ObserverModeTransaction(verifiedTransaction: Transaction, jwsRepresentation: String) async throws {
        handleSK2ObserverModeTransactionCalled = true
        handleSK2ObserverModeTransactionCount += 1
        handleSK2ObserverModeTransactionInvocations.append(.init(verifiedTransaction: verifiedTransaction,
                                                                 jwsRepresentation: jwsRepresentation))
    }

}
