//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesWillPurchaseBeBlockedDueToRestoreBehaviorTests.swift
//
//  Created by Will Taylor on 2/4/26.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
// swiftlint:disable:next type_name
final class PurchasesWillPurchaseBeBlockedDueToRestoreBehaviorSK2Tests: BasePurchasesTests {

    override var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        self.setupPurchases()
    }

    func testWillPurchaseBeBlockedReturnsFalseWhenNoVerifiedTransaction() async throws {
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = nil

        let result = try await self.purchasesOrchestrator.willPurchaseBeBlockedDueToRestoreBehavior()

        expect(result) == false
        expect(self.backend.invokedWillPurchaseBeBlockedDueToRestoreBehavior) == false
    }

    func testWillPurchaseBeBlockedReturnsFalseWhenTransactionHasNoJWS() async throws {
        let transaction = StoreTransaction.from(transaction: MockStoreTransaction(jwsRepresentation: nil))
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction

        let result = try await self.purchasesOrchestrator.willPurchaseBeBlockedDueToRestoreBehavior()

        expect(result) == false
        expect(self.backend.invokedWillPurchaseBeBlockedDueToRestoreBehavior) == false
    }

    func testWillPurchaseBeBlockedUsesBackendResponse() async throws {
        let jws = "transaction-jws"
        let transaction = StoreTransaction.from(transaction: MockStoreTransaction(jwsRepresentation: jws))
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction
        self.backend.stubbedWillPurchaseBeBlockedDueToRestoreBehaviorResult = .success(
            .init(receiptBelongsToOtherSubscriber: true, transferIsAllowed: false)
        )

        let result = try await self.purchasesOrchestrator.willPurchaseBeBlockedDueToRestoreBehavior()

        expect(result) == true
        expect(self.backend.invokedWillPurchaseBeBlockedDueToRestoreBehaviorCount) == 1
        expect(self.backend.invokedWillPurchaseBeBlockedDueToRestoreBehaviorParameters?.appUserID)
            == Self.appUserID
        expect(self.backend.invokedWillPurchaseBeBlockedDueToRestoreBehaviorParameters?.transactionJWS) == jws
    }

    func testWillPurchaseBeBlockedReturnsFalseWhenTransferIsAllowed() async throws {
        let jws = "transaction-jws"
        let transaction = StoreTransaction.from(transaction: MockStoreTransaction(jwsRepresentation: jws))
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction
        self.backend.stubbedWillPurchaseBeBlockedDueToRestoreBehaviorResult = .success(
            .init(receiptBelongsToOtherSubscriber: true, transferIsAllowed: true)
        )

        let result = try await self.purchasesOrchestrator.willPurchaseBeBlockedDueToRestoreBehavior()

        expect(result) == false
    }

    func testWillPurchaseBeBlockedReturnsFalseWhenReceiptDoesNotBelongToOtherSubscriber() async throws {
        let jws = "transaction-jws"
        let transaction = StoreTransaction.from(transaction: MockStoreTransaction(jwsRepresentation: jws))
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction
        self.backend.stubbedWillPurchaseBeBlockedDueToRestoreBehaviorResult = .success(
            .init(receiptBelongsToOtherSubscriber: false, transferIsAllowed: false)
        )

        let result = try await self.purchasesOrchestrator.willPurchaseBeBlockedDueToRestoreBehavior()

        expect(result) == false
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
// swiftlint:disable:next type_name
final class PurchasesWillPurchaseBeBlockedDueToRestoreBehaviorSK1Tests: BasePurchasesTests {

    override var storeKitVersion: StoreKitVersion { .storeKit1 }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        self.setupPurchases()
    }

    func testWillPurchaseBeBlockedThrowsForStoreKit1() async {
        do {
            _ = try await self.purchasesOrchestrator.willPurchaseBeBlockedDueToRestoreBehavior()
            XCTFail("Expected error for StoreKit 1")
        } catch {
            // Expected
        }
    }

}
