//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2TransactionFetcherTests.swift
//
//  Created by Nacho Soto on 5/24/23.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
@MainActor
class StoreKit2TransactionFetcherTests: StoreKitConfigTestCase {

    private var fetcher: StoreKit2TransactionFetcher!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.fetcher = .init()
    }

    // MARK: - unfinishedVerifiedTransactions

    func testNoUnfinishedVerifiedTransactions() async {
        let transactions = await self.fetcher.unfinishedVerifiedTransactions
        expect(transactions).to(beEmpty())
    }

    func testOneUnfinishedVerifiedTransaction() async throws {
        let transaction = try await self.createTransaction(finished: false)
        let result = await self.fetcher.unfinishedVerifiedTransactions

        expect(result) == [transaction]
    }

    func testOneUnfinishedConsumablePurchase() async throws {
        let transaction = try await self.createTransactionForConsumableProduct(finished: false)
        let result = await self.fetcher.unfinishedVerifiedTransactions

        expect(result) == [transaction]
    }

    func testMultipleUnfinishedVerifiedTransaction() async throws {
        let transaction1 = try await self.createTransaction(productID: Self.product1, finished: false)
        let transaction2 = try await self.createTransaction(productID: Self.product2, finished: false)

        let result = await self.fetcher.unfinishedVerifiedTransactions
        expect(result).to(haveCount(2))
        expect(result).to(contain([transaction1, transaction2]))
    }

    func testFiltersOutFinishedTransaction() async throws {
        _ = try await self.createTransaction(productID: Self.product1, finished: true)
        let transaction = try await self.createTransaction(productID: Self.product2, finished: false)

        let result = await self.fetcher.unfinishedVerifiedTransactions
        expect(result) == [transaction]
    }

    // MARK: - hasPendingConsumablePurchase

    func testHasNoPendingConsumablePurchase() async throws {
        let result = await self.fetcher.hasPendingConsumablePurchase
        expect(result) == false
    }

    func testHasNoPendingConsumablePurchaseWithNormalProduct() async throws {
        _ = try await self.createTransaction(finished: false)

        let result = await self.fetcher.hasPendingConsumablePurchase
        expect(result) == false
    }

    func testHasNoPendingConsumablePurchaseWithFinishedConsumable() async throws {
        _ = try await self.createTransactionForConsumableProduct(finished: true)

        let result = await self.fetcher.hasPendingConsumablePurchase
        expect(result) == false
    }

    func testHasPendingConsumablePurchase() async throws {
        _ = try await self.createTransactionForConsumableProduct(finished: false)

        let result = await self.fetcher.hasPendingConsumablePurchase
        expect(result) == true
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension StoreKit2TransactionFetcherTests {

    func createTransaction(
        productID: String? = nil,
        finished: Bool
    ) async throws -> StoreTransaction {
        return StoreTransaction(
            sk2Transaction: try await self.simulateAnyPurchase(productID: productID,
                                                               finishTransaction: finished)
        )
    }

    func createTransactionForConsumableProduct(finished: Bool) async throws -> StoreTransaction {
        return try await self.createTransaction(productID: Self.consumable, finished: finished)
    }

    static let product1 = "com.revenuecat.monthly_4.99.1_week_intro"
    static let product2 = "com.revenuecat.annual_39.99_no_trial"
    static let consumable = "com.revenuecat.consumable"

}
