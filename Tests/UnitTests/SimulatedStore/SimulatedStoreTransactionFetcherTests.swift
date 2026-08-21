//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimulatedStoreTransactionFetcherTests.swift

import Nimble
@testable import RevenueCat
import XCTest

class SimulatedStoreTransactionFetcherTests: TestCase {

    private var fetcher: SimulatedStoreTransactionFetcher!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.fetcher = SimulatedStoreTransactionFetcher()
    }

    func testUnfinishedVerifiedTransactionsIsEmpty() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let transactions = await self.fetcher.unfinishedVerifiedTransactions
            expect(transactions).to(beEmpty())
        }
    }

    func testHasPendingConsumablePurchaseIsFalse() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let hasPending = await self.fetcher.hasPendingConsumablePurchase
            expect(hasPending) == false
        }
    }

    func testFirstVerifiedAutoRenewableTransactionIsNil() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let transaction = await self.fetcher.firstVerifiedAutoRenewableTransaction
            expect(transaction).to(beNil())
        }
    }

    func testFirstVerifiedTransactionIsNil() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let transaction = await self.fetcher.firstVerifiedTransaction
            expect(transaction).to(beNil())
        }
    }

    func testOldestVerifiedTransactionIsNil() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let transaction = await self.fetcher.oldestVerifiedTransaction
            expect(transaction).to(beNil())
        }
    }

    func testAppTransactionJWSAsyncIsNil() async throws {
        let jws = await self.fetcher.appTransactionJWS
        expect(jws).to(beNil())
    }

    func testAppTransactionJWSCompletionHandlerIsNil() throws {
        let expectation = self.expectation(description: "appTransactionJWS completion called")
        var receivedJWS: String?
        var receivedNonNil = false

        self.fetcher.appTransactionJWS { jws in
            receivedJWS = jws
            receivedNonNil = jws != nil
            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1)
        expect(receivedJWS).to(beNil())
        expect(receivedNonNil) == false
    }

    func testFetchReceiptReturnsEmptyReceiptAndLogsWarning() async throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let receipt = await self.fetcher.fetchReceipt(containing: MockStoreTransaction())

            expect(receipt.transactions).to(beEmpty())
            expect(receipt.subscriptionStatusBySubscriptionGroupId).to(beEmpty())
            expect(receipt.bundleId).to(beEmpty())
            expect(receipt.originalApplicationVersion).to(beNil())
            expect(receipt.originalPurchaseDate).to(beNil())
            self.logger.verifyMessageWasLogged(
                Strings.purchase.simulated_store_unexpected_receipt_fetch,
                level: .warn
            )
        }
    }

}
