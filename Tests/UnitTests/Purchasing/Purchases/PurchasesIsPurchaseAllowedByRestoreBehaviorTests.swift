//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesIsPurchaseAllowedByRestoreBehaviorTests.swift
//
//  Created by Will Taylor on 2/4/26.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
// swiftlint:disable:next type_name
final class PurchasesIsPurchaseAllowedByRestoreBehaviorSK2Tests: BasePurchasesTests {

    override var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        self.setupPurchases()
    }

    func testIsPurchaseAllowedReturnsTrueWhenNoVerifiedTransaction() async throws {
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = nil

        let result = try await self.purchasesOrchestrator.isPurchaseAllowedByRestoreBehavior()

        expect(result) == true
        expect(self.backend.invokedIsPurchaseAllowedByRestoreBehavior) == false
    }

    func testIsPurchaseAllowedReturnsTrueWhenTransactionHasNoJWS() async throws {
        let transaction = StoreTransaction.from(transaction: MockStoreTransaction(jwsRepresentation: nil))
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction

        let result = try await self.purchasesOrchestrator.isPurchaseAllowedByRestoreBehavior()

        expect(result) == true
        expect(self.backend.invokedIsPurchaseAllowedByRestoreBehavior) == false
    }

    func testIsPurchaseAllowedUsesBackendResponse() async throws {
        let jws = "transaction-jws"
        let transaction = StoreTransaction.from(transaction: MockStoreTransaction(jwsRepresentation: jws))
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction
        self.backend.stubbedIsPurchaseAllowedByRestoreBehaviorResult = .success(
            .init(isPurchaseAllowedByRestoreBehavior: true)
        )

        let result = try await self.purchasesOrchestrator.isPurchaseAllowedByRestoreBehavior()

        expect(result) == true
        expect(self.backend.invokedIsPurchaseAllowedByRestoreBehaviorCount) == 1
        expect(self.backend.invokedIsPurchaseAllowedByRestoreBehaviorParameters?.appUserID)
            == Self.appUserID
        expect(self.backend.invokedIsPurchaseAllowedByRestoreBehaviorParameters?.transactionJWS) == jws
    }

    func testIsPurchaseAllowedReturnsFalseWhenNotAllowedByRestoreBehavior() async throws {
        let jws = "transaction-jws"
        let transaction = StoreTransaction.from(transaction: MockStoreTransaction(jwsRepresentation: jws))
        self.mockTransactionFetcher.stubbedFirstVerifiedTransaction = transaction
        self.backend.stubbedIsPurchaseAllowedByRestoreBehaviorResult = .success(
            .init(isPurchaseAllowedByRestoreBehavior: false)
        )

        let result = try await self.purchasesOrchestrator.isPurchaseAllowedByRestoreBehavior()

        expect(result) == false
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
// swiftlint:disable:next type_name
final class PurchasesIsPurchaseAllowedByRestoreBehaviorSK1Tests: BasePurchasesTests {

    override var storeKitVersion: StoreKitVersion { .storeKit1 }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        self.setupPurchases()
    }

    func testIsPurchaseAllowedThrowsForStoreKit1() async {
        do {
            _ = try await self.purchasesOrchestrator.isPurchaseAllowedByRestoreBehavior()
            XCTFail("Expected error for StoreKit 1")
        } catch {
            // Expected
        }
    }

}
