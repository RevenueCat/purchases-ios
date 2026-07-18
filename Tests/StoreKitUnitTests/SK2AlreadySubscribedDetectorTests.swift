//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2AlreadySubscribedDetectorTests.swift
//
//  Created by AJ Pallares on 2/27/26.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class SK2AlreadySubscribedDetectorTests: StoreKitConfigTestCase {

    private var mockTransactionFetcher: MockStoreKit2TransactionFetcher!
    private var mockCustomerInfoManager: MockCustomerInfoManager!

    override func setUp() async throws {
        try await super.setUp()
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.mockTransactionFetcher = MockStoreKit2TransactionFetcher()
        self.mockCustomerInfoManager = MockCustomerInfoManager(
            offlineEntitlementsManager: MockOfflineEntitlementsManager(),
            operationDispatcher: MockOperationDispatcher(),
            deviceCache: MockDeviceCache(),
            backend: MockBackend(),
            transactionFetcher: MockStoreKit2TransactionFetcher(),
            transactionPoster: MockTransactionPoster(),
            systemInfo: MockSystemInfo(finishTransactions: true)
        )
    }

    // MARK: - No existing transaction

    func testReturnsNilWhenProductHasNoExistingTransaction() async throws {
        let product = try await self.fetchSk2Product()

        let result = await SK2AlreadySubscribedDetector.alreadyPurchasedTransactionID(
            for: product,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.mockCustomerInfoManager,
            appUserID: "test_user"
        )

        expect(result).to(beNil())
    }

    // MARK: - Unfinished transaction (allow retries)

    func testReturnsNilWhenExistingTransactionIsUnfinished() async throws {
        let product = try await self.fetchSk2Product()

        let purchaseResult = try await self.simulateAnyPurchase(product: product)
        let storeTransaction = StoreTransaction(
            sk2Transaction: purchaseResult.underlyingTransaction,
            jwsRepresentation: purchaseResult.jwsRepresentation
        )

        self.mockTransactionFetcher.stubbedUnfinishedTransactions = [storeTransaction]

        let result = await SK2AlreadySubscribedDetector.alreadyPurchasedTransactionID(
            for: product,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.mockCustomerInfoManager,
            appUserID: "test_user"
        )

        expect(result).to(beNil())
    }

    // MARK: - Different user (allow receipt transfer)

    func testReturnsNilWhenCurrentUserDoesNotOwnProduct() async throws {
        let product = try await self.fetchSk2Product()

        try await self.simulateAnyPurchase(product: product, finishTransaction: true)

        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = .emptyInfo

        let result = await SK2AlreadySubscribedDetector.alreadyPurchasedTransactionID(
            for: product,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.mockCustomerInfoManager,
            appUserID: "test_user"
        )

        expect(result).to(beNil())
    }

    // MARK: - Nil cached customer info (cold start)

    func testReturnsNilWhenCachedCustomerInfoIsNil() async throws {
        let product = try await self.fetchSk2Product()

        try await self.simulateAnyPurchase(product: product, finishTransaction: true)

        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = nil

        let result = await SK2AlreadySubscribedDetector.alreadyPurchasedTransactionID(
            for: product,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.mockCustomerInfoManager,
            appUserID: "test_user"
        )

        expect(result).to(beNil())
    }

    // MARK: - Expired subscription (allow re-purchase)

    func testReturnsNilWhenSubscriptionIsExpired() async throws {
        let product = try await self.fetchSk2Product()

        try await self.simulateAnyPurchase(product: product, finishTransaction: true)

        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = try CustomerInfo(data: [
            "request_date": "2099-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [
                    StoreKitConfigTestCase.productID: [
                        "expires_date": "2020-01-01T00:00:00Z",
                        "purchase_date": "2019-07-17T00:05:54Z"
                    ]
                ],
                "other_purchases": [:] as [String: Any],
                "original_application_version": "1.0",
                "original_purchase_date": "2019-07-17T00:05:54Z"
            ] as [String: Any]
        ])

        let result = await SK2AlreadySubscribedDetector.alreadyPurchasedTransactionID(
            for: product,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.mockCustomerInfoManager,
            appUserID: "test_user"
        )

        expect(result).to(beNil())
    }

    // MARK: - Already purchased (should detect)

    func testReturnsTransactionIDWhenProductIsAlreadyPurchasedSubscription() async throws {
        let product = try await self.fetchSk2Product()

        let purchaseResult = try await self.simulateAnyPurchase(product: product, finishTransaction: true)
        let expectedTransactionID = String(purchaseResult.underlyingTransaction.id)

        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = try CustomerInfo(data: [
            "request_date": "2099-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [
                    StoreKitConfigTestCase.productID: [
                        "expires_date": "2099-08-16T10:30:42Z",
                        "purchase_date": "2019-07-17T00:05:54Z"
                    ]
                ],
                "other_purchases": [:] as [String: Any],
                "original_application_version": "1.0",
                "original_purchase_date": "2019-07-17T00:05:54Z"
            ] as [String: Any]
        ])

        let result = await SK2AlreadySubscribedDetector.alreadyPurchasedTransactionID(
            for: product,
            transactionFetcher: self.mockTransactionFetcher,
            customerInfoManager: self.mockCustomerInfoManager,
            appUserID: "test_user"
        )

        expect(result) == expectedTransactionID
    }

}
