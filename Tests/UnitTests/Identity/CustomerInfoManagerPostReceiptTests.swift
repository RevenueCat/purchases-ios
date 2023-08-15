//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoManagerFetchInfoAndPostReceiptTests.swift
//
//  Created by Nacho Soto on 5/24/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class CustomerInfoManagerPostReceiptTests: BaseCustomerInfoManagerTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testDoesNotTryToPostUnfinishedTransactionIfNoneExist() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = []
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        let result = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                                                  isAppBackgrounded: false)
        expect(result) === self.mockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.randomDelay) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == false
    }

    func testReturnsFailureIfPostingReceiptFails() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .failure(
            .networkError(.serverDown())
        )

        do {
            _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                                             isAppBackgrounded: false)
            fail("Expected error")
        } catch let BackendError.networkError(networkError) {
            expect(networkError.isServerDown) == true

            expect(self.mockBackend.invokedGetSubscriberData) == false
            expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testPostsSingleTransaction() async throws {
        let transaction = Self.createTransaction()

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [transaction]
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                                                isAppBackgrounded: false)
        expect(info) === self.mockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberData) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true

        let parameters = try XCTUnwrap(self.mockTransactionPoster.invokedHandlePurchasedTransactionParameters.value)

        expect(parameters.transaction as? StoreTransaction) === transaction
        expect(parameters.data.appUserID) == Self.appUserID
        expect(parameters.data.presentedOfferingID).to(beNil())
        expect(parameters.data.unsyncedAttributes).to(beEmpty())
        expect(parameters.data.source.isRestore) == false
        expect(parameters.data.source.initiationSource) == .queue
    }

    func testFetchesCustomerInfoIfTransactionWasAlreadyPosted() async throws {
        let transaction = Self.createTransaction()

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [transaction]
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .alreadyPosted
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                                                isAppBackgrounded: false)
        expect(info) == self.mockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberData) == true
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true

        let parameters = try XCTUnwrap(self.mockTransactionPoster.invokedHandlePurchasedTransactionParameters.value)

        expect(parameters.transaction as? StoreTransaction) === transaction
        expect(parameters.data.appUserID) == Self.appUserID
        expect(parameters.data.presentedOfferingID).to(beNil())
        expect(parameters.data.unsyncedAttributes).to(beEmpty())
        expect(parameters.data.source.isRestore) == false
        expect(parameters.data.source.initiationSource) == .queue
    }

    func testFetchesCustomerInfoIfTransactionWasAlreadyPostedButNoCachedCustomerInfo() async throws {
        let transaction = Self.createTransaction()

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [transaction]
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .alreadyPosted

        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                                                isAppBackgrounded: false)
        expect(info) === self.mockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberData) == true
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true

        let parameters = try XCTUnwrap(self.mockTransactionPoster.invokedHandlePurchasedTransactionParameters.value)

        expect(parameters.transaction as? StoreTransaction) === transaction
        expect(parameters.data.appUserID) == Self.appUserID
        expect(parameters.data.presentedOfferingID).to(beNil())
        expect(parameters.data.unsyncedAttributes).to(beEmpty())
        expect(parameters.data.source.isRestore) == false
        expect(parameters.data.source.initiationSource) == .queue
    }

    func testPostsFirstUnpostedTransaction() async throws {
        let transactionToPost = Self.createTransaction()
        let postedTransaction = Self.createTransaction()
        let otherTransaction = Self.createTransaction()

        let allTransactions = [
            postedTransaction,
            transactionToPost,
            otherTransaction
        ]
        let unpostedTransactions = [
            transactionToPost,
            otherTransaction
        ]

        self.mockTransactionPoster.transactionCache.savePostedTransaction(postedTransaction)

        self.mockTransationFetcher.stubbedUnfinishedTransactions = allTransactions
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                                         isAppBackgrounded: false)
        expect(self.mockBackend.invokedGetSubscriberData) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true
        // The first transaction is posted synchronously.
        // The rest are posted in the background.
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransactionCount.value) >= 1

        expect(self.mockTransactionPoster.allHandledTransactions).to(contain(transactionToPost))

        self.logger.verifyMessageWasLogged(
            Strings.customerInfo.posting_transactions_in_lieu_of_fetching_customerinfo(
                allTransactions: allTransactions,
                unpostedTransactions: unpostedTransactions
            ),
            level: .debug
        )

        try await asyncWait(
            description: "The rest of transactions should be posted asynchronously"
        ) { [poster = self.mockTransactionPoster!] in
            poster.allHandledTransactions == Set(unpostedTransactions)
        }
    }

    func testPostingAllTransactionsReturnsFirstResult() async throws {
        let otherMockCustomerInfo = try CustomerInfo(data: [
            "request_date": "2024-12-21T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "other user",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": NSNull()
            ]  as [String: Any]
        ])

        let transactions = [
            Self.createTransaction(),
            Self.createTransaction(),
            Self.createTransaction()
        ]

        self.mockTransationFetcher.stubbedUnfinishedTransactions = transactions
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResults.value = [
            .success(otherMockCustomerInfo),
            .success(self.mockCustomerInfo),
            .failure(.networkError(.serverDown()))
        ]

        let result = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                                                  isAppBackgrounded: false)
        expect(result) === otherMockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberData) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true

        self.logger.verifyMessageWasLogged(
            Strings.customerInfo.posting_transactions_in_lieu_of_fetching_customerinfo(
                allTransactions: transactions,
                unpostedTransactions: transactions
            ),
            level: .debug
        )

        try await asyncWait { [poster = self.mockTransactionPoster!] in
            poster.allHandledTransactions == Set(transactions)
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension CustomerInfoManagerPostReceiptTests {

    static func createTransaction() -> StoreTransaction {
        return .init(sk1Transaction: MockTransaction())
    }

}
