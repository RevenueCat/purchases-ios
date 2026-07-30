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

        let result = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                                  isAppBackgrounded: false)
        expect(result) === self.mockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.isAppBackgrounded) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == false
    }

    func testReturnsFailureWhenBothPostingReceiptAndFetchingCustomerInfoFail() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .failure(
            .networkError(.serverDown())
        )
        self.mockBackend.stubbedGetCustomerInfoResult = .failure(.networkError(.serverDown()))

        do {
            _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                             isAppBackgrounded: false)
            fail("Expected error")
        } catch let BackendError.networkError(networkError) {
            expect(networkError.isServerDown) == true

            expect(self.mockBackend.invokedGetSubscriberData) == true
            expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testFallsBackToGetCustomerInfoWhenPostingReceiptFails() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .failure(
            .networkError(.serverDown())
        )
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                                isAppBackgrounded: false)
        expect(info) === self.mockCustomerInfo

        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true
        expect(self.mockBackend.invokedGetSubscriberData) == true
    }

    func testFallsBackToGetCustomerInfoWhenFirstOfMultipleUnfinishedTransactionPostsFails() async throws {
        let transactions = [
            Self.createTransaction(),
            Self.createTransaction(),
            Self.createTransaction()
        ]

        self.mockTransationFetcher.stubbedUnfinishedTransactions = transactions
        // First transaction (posted synchronously, its result drives the caller's result) fails.
        // The other two (posted in a `Task.detached`, fire-and-forget) succeed.
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResults.value = [
            .failure(.networkError(.serverDown())),
            .success(self.mockCustomerInfo),
            .success(self.mockCustomerInfo)
        ]
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                                isAppBackgrounded: false)
        expect(info) === self.mockCustomerInfo

        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true
        expect(self.mockBackend.invokedGetSubscriberData) == true

        try await asyncWait(
            description: "All unfinished transactions should be posted, including the two in the background"
        ) { [poster = self.mockTransactionPoster!] in
            poster.allHandledTransactions == Set(transactions)
        }
    }

    func testPostsSingleTransaction() async throws {
        let transaction = Self.createTransaction()

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [transaction]
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                                isAppBackgrounded: false)
        expect(info) === self.mockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberData) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true

        let parameters = try XCTUnwrap(self.mockTransactionPoster.invokedHandlePurchasedTransactionParameters.value)

        expect(parameters.transaction as? StoreTransaction) === transaction
        expect(parameters.currentUserID) == Self.userID
        expect(parameters.data.presentedOfferingContext?.offeringIdentifier).to(beNil())
        expect(parameters.data.unsyncedAttributes).to(beEmpty())
        expect(parameters.postReceiptSource.isRestore) == false
        expect(parameters.postReceiptSource.initiationSource) == .queue
    }

    func testPostsFirstTransaction() async throws {
        let transactionToPost = Self.createTransaction()
        let transactions = [
            transactionToPost,
            Self.createTransaction(),
            Self.createTransaction()
        ]

        self.mockTransationFetcher.stubbedUnfinishedTransactions = transactions
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        _ = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                         isAppBackgrounded: false)
        expect(self.mockBackend.invokedGetSubscriberData) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true
        // The first transaction is posted synchronously.
        // The rest are posted in the background.
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransactionCount.value) >= 1

        expect(self.mockTransactionPoster.allHandledTransactions).to(contain(transactionToPost))

        self.logger.verifyMessageWasLogged(
            Strings.customerInfo.posting_transactions_in_lieu_of_fetching_customerinfo(transactions),
            level: .debug
        )

        try await asyncWait(
            description: "The rest of transactions should be posted asynchronously"
        ) { [poster = self.mockTransactionPoster!] in
            poster.allHandledTransactions == Set(transactions)
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

        let result = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                                  isAppBackgrounded: false)
        expect(result) === otherMockCustomerInfo

        expect(self.mockBackend.invokedGetSubscriberData) == false
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true

        self.logger.verifyMessageWasLogged(
            Strings.customerInfo.posting_transactions_in_lieu_of_fetching_customerinfo(transactions),
            level: .debug
        )

        try await asyncWait { [poster = self.mockTransactionPoster!] in
            poster.allHandledTransactions == Set(transactions)
        }
    }

    // MARK: - UnsyncedTransactionsWaitPolicy

    func testDoesNotComputeCustomerInfoOnDeviceByDefault() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = true
        self.mockOfflineEntitlementsManager.stubbedComputeOfflineCustomerInfoResult = .success(self.mockCustomerInfo2)
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        let info = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.userID,
                                                                               isAppBackgrounded: false)

        expect(info) === self.mockCustomerInfo
        expect(self.mockOfflineEntitlementsManager.invokedComputeOfflineCustomerInfo) == false
    }

    func testDoNotWaitReturnsCustomerInfoComputedOnDeviceWhilePostIsInFlight() async throws {
        let transaction = Self.createTransaction()
        let manager = self.createCustomerInfoManager(waitPolicy: .doNotWait)

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [transaction]
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = true
        self.mockOfflineEntitlementsManager.stubbedComputeOfflineCustomerInfoResult = .success(self.mockCustomerInfo2)
        // The post never completes, so a result can only come from computing it on the device.
        self.mockTransactionPoster.holdsCompletions.value = true

        let info = try await manager.fetchAndCacheCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false)

        expect(info) === self.mockCustomerInfo2
        expect(self.mockBackend.invokedGetSubscriberData) == false

        self.logger.verifyMessageWasLogged(
            Strings.customerInfo.not_waiting_for_unsynced_transactions([transaction]),
            level: .debug
        )

        try await asyncWait(
            description: "Unsynced transactions should still be posted in the background"
        ) { [poster = self.mockTransactionPoster!] in
            poster.invokedHandlePurchasedTransaction.value
        }
    }

    func testDoNotWaitPostsEveryUnsyncedTransactionInTheBackground() async throws {
        let transactions = [
            Self.createTransaction(),
            Self.createTransaction(),
            Self.createTransaction()
        ]
        let manager = self.createCustomerInfoManager(waitPolicy: .doNotWait)

        self.mockTransationFetcher.stubbedUnfinishedTransactions = transactions
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = true
        self.mockOfflineEntitlementsManager.stubbedComputeOfflineCustomerInfoResult = .success(self.mockCustomerInfo2)
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        _ = try await manager.fetchAndCacheCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false)

        try await asyncWait { [poster = self.mockTransactionPoster!] in
            poster.allHandledTransactions == Set(transactions)
        }
    }

    func testDoNotWaitCachesCustomerInfoOncePostFinishes() async throws {
        let manager = self.createCustomerInfoManager(waitPolicy: .doNotWait)

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = true
        self.mockOfflineEntitlementsManager.stubbedComputeOfflineCustomerInfoResult = .success(self.mockCustomerInfo2)
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)
        self.mockTransactionPoster.holdsCompletions.value = true

        _ = try await manager.fetchAndCacheCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false)

        try await asyncWait(description: "The transaction should be posted") { [poster = self.mockTransactionPoster!] in
            poster.invokedHandlePurchasedTransaction.value
        }

        let countBeforePostFinishes = self.mockDeviceCache.cacheCustomerInfoCount
        self.mockTransactionPoster.releaseHeldCompletions()

        try await asyncWait(
            description: "CustomerInfo from the post should be cached once it finishes"
        ) { [cache = self.mockDeviceCache!] in
            cache.cacheCustomerInfoCount > countBeforePostFinishes
        }
    }

    func testDoNotWaitWaitsForPostWhenComputingOnDeviceFails() async throws {
        let manager = self.createCustomerInfoManager(waitPolicy: .doNotWait)

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = true
        self.mockOfflineEntitlementsManager.stubbedComputeOfflineCustomerInfoResult = .failure(.notAvailable)
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        let info = try await manager.fetchAndCacheCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false)

        expect(info) === self.mockCustomerInfo
        expect(self.mockOfflineEntitlementsManager.invokedComputeOfflineCustomerInfo) == true
        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == true
    }

    func testDoNotWaitWaitsForPostWhenComputingOnDeviceIsNotPossible() async throws {
        let manager = self.createCustomerInfoManager(waitPolicy: .doNotWait)

        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = false
        self.mockTransactionPoster.stubbedHandlePurchasedTransactionResult.value = .success(self.mockCustomerInfo)

        let info = try await manager.fetchAndCacheCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false)

        expect(info) === self.mockCustomerInfo
        expect(self.mockOfflineEntitlementsManager.invokedComputeOfflineCustomerInfo) == false
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension CustomerInfoManagerPostReceiptTests {

    static func createTransaction() -> StoreTransaction {
        return .init(sk1Transaction: MockTransaction())
    }

    static let userID: String = "user"

    func createCustomerInfoManager(waitPolicy: UnsyncedTransactionsWaitPolicy) -> CustomerInfoManager {
        return CustomerInfoManager(
            offlineEntitlementsManager: self.mockOfflineEntitlementsManager,
            operationDispatcher: self.mockOperationDispatcher,
            deviceCache: self.mockDeviceCache,
            backend: self.mockBackend,
            transactionFetcher: self.mockTransationFetcher,
            transactionPoster: self.mockTransactionPoster,
            systemInfo: MockSystemInfo(finishTransactions: true,
                                       unsyncedTransactionsWaitPolicy: waitPolicy)
        )
    }

}
