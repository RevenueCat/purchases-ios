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
        let transaction = try await self.createTransaction(productID: Self.consumable,
                                                           finished: false)
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
        _ = try await self.createTransaction(productID: Self.consumable, finished: true)

        let result = await self.fetcher.hasPendingConsumablePurchase
        expect(result) == false
    }

    func testHasPendingConsumablePurchase() async throws {
        _ = try await self.createTransaction(productID: Self.consumable, finished: false)

        let result = await self.fetcher.hasPendingConsumablePurchase
        expect(result) == true
    }

    // MARK: - firstVerifiedAutoRenewableTransaction

    func testHasFirstVerifiedAutoRenewableTransaction() async throws {
        let transaction = try await self.createTransaction(finished: true)
        let result = await self.fetcher.firstVerifiedAutoRenewableTransaction
        expect(result) == transaction
    }

    func testDoesNotHaveFirstVerifiedAutoRenewableTransaction() async throws {
        let result = await self.fetcher.firstVerifiedAutoRenewableTransaction
        expect(result) == nil
    }

    func testFirstVerifiedAutoRenewableTransactionDoesNotIncludeFinishedConsumableTransaction() async throws {
        _ = try await self.createTransaction(productID: Self.consumable, finished: true)
        let result = await self.fetcher.firstVerifiedAutoRenewableTransaction
        expect(result) == nil
    }

    func testHasVerifiedAutoRenewableTransactionDoesNotIncludeUnfinishedConsumableTransaction() async throws {
        _ = try await self.createTransaction(productID: Self.consumable, finished: false)
        let result = await self.fetcher.firstVerifiedAutoRenewableTransaction
        expect(result) == nil
    }

    // MARK: - firstVerifiedTransaction

    func testHasFirstVerifiedTransaction() async throws {
        let transaction = try await self.createTransaction(finished: true)
        let result = await self.fetcher.firstVerifiedTransaction
        expect(result) == transaction
    }

    func testDoesNotHaveFirstVerifiedTransaction() async throws {
        let result = await self.fetcher.firstVerifiedTransaction
        expect(result) == nil
    }

    func testFirstVerifiedTransactionDoesNotIncludeFinishedConsumableTransaction() async throws {
        _ = try await self.createTransaction(productID: Self.consumable, finished: true)
        let result = await self.fetcher.firstVerifiedTransaction
        expect(result) == nil
    }

    func testHasVerifiedTransactionIncludesUnfinishedConsumableTransaction() async throws {
        let transaction = try await self.createTransaction(productID: Self.consumable,
                                                           finished: false)
        let result = await self.fetcher.firstVerifiedTransaction
        expect(result) == transaction
    }

    // MARK: - receipt

    func testGeneratesReceipt() async throws {
        _ = try await self.createTransaction(productID: Self.product1,
                                             finished: false)
        let transaction = try await self.createTransaction(productID: Self.product2,
                                                           finished: false)
        let receipt = await self.fetcher.fetchReceipt(containing: transaction)
        expect(receipt.transactions).to(haveCount(2))
        expect(receipt.subscriptionStatusBySubscriptionGroupId).to(haveCount(2))
        expect(receipt.environment) == .xcode

        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            expect(receipt.bundleId) == Bundle.main.bundleIdentifier
            expect(receipt.originalApplicationVersion).notTo(beEmpty())
            expect(receipt.originalPurchaseDate).notTo(beNil())
        } else {
            // AppTransaction is not available on iOS 15
            expect(receipt.bundleId).to(beEmpty())
            expect(receipt.originalApplicationVersion).to(beNil())
            expect(receipt.originalPurchaseDate).to(beNil())

            self.logger.verifyMessageWasLogged(
                Strings.storeKit.sk2_app_transaction_unavailable,
                level: .warn
            )
        }
    }

    // MARK: - unverified transactions

    func testVerifiedTransactionHandlesUnverifiedTransactions() async throws {
        let transaction = try await self.simulateAnyPurchase()
        let error: StoreKit.VerificationResult<Transaction>.VerificationError = .invalidSignature
        let result: StoreKit.VerificationResult<Transaction> = .unverified(transaction.underlyingTransaction, error)

        expect(result.verifiedTransaction).to(beNil())

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.sk2_unverified_transaction(identifier: String(result.underlyingTransaction.id), error),
            level: .warn
        )
    }

    func testVerifiedStoreTransactionHandlesUnverifiedTransactions() async throws {
        let transaction = try await self.simulateAnyPurchase()
        let error: StoreKit.VerificationResult<Transaction>.VerificationError = .invalidSignature
        let result: StoreKit.VerificationResult<Transaction> = .unverified(transaction.underlyingTransaction, error)

        expect(result.verifiedStoreTransaction).to(beNil())

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.sk2_unverified_transaction(identifier: String(result.underlyingTransaction.id), error),
            level: .warn
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testVerifiedAppTransactionHandlesUnverifiedTransactions() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let transaction = try await StoreKit.AppTransaction.shared
        let error: StoreKit.VerificationResult<AppTransaction>.VerificationError = .invalidSignature
        let result: StoreKit.VerificationResult<AppTransaction> = .unverified(transaction.unsafePayloadValue, error)

        expect(result.verifiedAppTransaction).to(beNil())

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.sk2_unverified_transaction(identifier: transaction.unsafePayloadValue.bundleID, error),
            level: .warn
        )
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension StoreKit2TransactionFetcherTests {

    static let product1 = "com.revenuecat.monthly_4.99.1_week_intro"
    static let product2 = "com.revenuecat.annual_39.99_no_trial"
    static let consumable = "com.revenuecat.consumable"

}
