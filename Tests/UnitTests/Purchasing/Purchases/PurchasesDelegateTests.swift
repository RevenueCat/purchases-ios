//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesDelegateTests.swift
//
//  Created by Nacho Soto on 5/31/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesDelegateTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testDoesntSetWrapperDelegateToNilIfDelegateNil() {
        self.purchases.delegate = nil

        expect(self.storeKit1Wrapper.delegate).toNot(beNil())

        self.purchases.delegate = self.purchasesDelegate

        expect(self.storeKit1Wrapper.delegate).toNot(beNil())
    }

    func testSubscribesToUIApplicationWillEnterForeground() throws {
        expect(self.notificationCenter.observers).to(haveCount(4))

        let (_, _, name, _) = try XCTUnwrap(self.notificationCenter.observers.first)
        expect(name) == SystemInfo.applicationWillEnterForegroundNotification
    }

    func testTriggersCallToBackend() {
        self.notificationCenter.fireNotifications()
        expect(self.backend.userID).toEventuallyNot(beNil())
    }

    func testAutomaticallyFetchesCustomerInfoOnDidBecomeActiveIfCacheStale() {
        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))

        self.deviceCache.stubbedIsCustomerInfoCacheStale = true
        self.notificationCenter.fireNotifications()

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(2))
    }

    func testSubscribesToUIApplicationDidBecomeActive() throws {
        let applicationDidBecomeActiveNotificationObservers = self.notificationCenter.observers
            .filter { $0.notificationName == SystemInfo.applicationDidBecomeActiveNotification }

        expect(applicationDidBecomeActiveNotificationObservers.count) == 1
    }

    func testDoesntAutomaticallyFetchCustomerInfoOnDidBecomeActiveIfCacheValid() {
        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))
        self.deviceCache.stubbedIsCustomerInfoCacheStale = false

        self.notificationCenter.fireNotifications()

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))
    }

    func testAutomaticallyCallsDelegateOnDidBecomeActiveAndUpdate() {
        self.notificationCenter.fireNotifications()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testDoesntRemoveObservationWhenDelegateNil() {
        self.purchases.delegate = nil

        expect(self.notificationCenter.observers).to(haveCount(4))
    }

    // MARK: - Cached Transaction Metadata Sync

    func testApplicationDidBecomeActiveSyncsCachedTransactionMetadata() async throws {
        let transactionId = "cached_transaction_1"
        let metadata = createCachedMetadata(transactionId: transactionId, productIdentifier: "product_1")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata, forTransactionId: transactionId)
        self.backend.postReceiptResult = .success(
            try CustomerInfo(data: Self.emptyCustomerInfoData)
        )

        // Fire the applicationDidBecomeActive notification
        self.notificationCenter.fireNotifications()

        // Verify that the backend was called to post the cached metadata
        await expect(self.backend.postReceiptDataCalled).toEventually(beTrue())
        expect(self.backend.postedAssociatedTransactionIds).to(contain(transactionId))
    }

    func testApplicationDidBecomeActiveSyncsMultipleCachedTransactions() async throws {
        let transactionId1 = "cached_transaction_1"
        let transactionId2 = "cached_transaction_2"
        let metadata1 = createCachedMetadata(transactionId: transactionId1, productIdentifier: "product_1")
        let metadata2 = createCachedMetadata(transactionId: transactionId2, productIdentifier: "product_2")

        self.mockLocalTransactionMetadataStore.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.mockLocalTransactionMetadataStore.storeMetadata(metadata2, forTransactionId: transactionId2)
        self.backend.postReceiptResult = .success(
            try CustomerInfo(data: Self.emptyCustomerInfoData)
        )

        // Fire the applicationDidBecomeActive notification
        self.notificationCenter.fireNotifications()

        // Wait for backend to be invoked twice
        await expect(self.backend.postReceiptDataCallCount).toEventually(equal(2))

        // Verify both transactions were posted
        expect(self.backend.postedAssociatedTransactionIds).to(contain(transactionId1))
        expect(self.backend.postedAssociatedTransactionIds).to(contain(transactionId2))
    }

    func testApplicationDidBecomeActiveDoesNotPostWhenNoCachedMetadata() async {
        // No metadata stored

        // Fire the applicationDidBecomeActive notification
        self.notificationCenter.fireNotifications()

        // Give some time for any async operations to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Backend should not have been called for receipt posting with an associated transaction ID
        let postedWithTransactionId = self.backend.postedAssociatedTransactionIds.compactMap { $0 }
        expect(postedWithTransactionId).to(beEmpty())
    }

    private func createCachedMetadata(
        transactionId: String,
        productIdentifier: String
    ) -> LocalTransactionMetadata {
        return LocalTransactionMetadata(
            transactionId: transactionId,
            productData: ProductRequestData(
                productIdentifier: productIdentifier,
                paymentMode: nil,
                currencyCode: "USD",
                storeCountry: "US",
                price: 9.99,
                normalDuration: nil,
                introDuration: nil,
                introDurationType: nil,
                introPrice: nil,
                subscriptionGroup: nil,
                discounts: nil
            ),
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .receipt("test_receipt_\(transactionId)".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )
    }

    // See https://github.com/RevenueCat/purchases-ios/issues/2410
    func testDelegateWithGetCustomerInfoCallDoesNotDeadlock() throws {
        final class GetCustomerInfoPurchasesDelegate: NSObject, PurchasesDelegate {
            func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
                purchases.getCustomerInfo { _, _ in }
            }
        }

        let delegate = GetCustomerInfoPurchasesDelegate()
        self.purchases.delegate = delegate

        let offerings = self.offeringsFactory.createOfferings(from: [:],
                                                              contents: .mockContents,
                                                              loadedFromDiskCache: false)
        let package = try XCTUnwrap(offerings?.all["base"]?.monthly)

        waitUntil { completion in
            self.purchases.purchase(package: package) { _, _, _, _ in
                completion()
            }

            let transaction = MockTransaction()
            transaction.mockPayment = self.storeKit1Wrapper.payment!
            transaction.mockState = .purchasing

            self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper,
                                                             updatedTransaction: transaction)

            self.backend.postReceiptResult = .success(.emptyInfo)

            transaction.mockState = .purchased
            self.storeKit1Wrapper.delegate?.storeKit1Wrapper(self.storeKit1Wrapper,
                                                             updatedTransaction: transaction)
        }
    }

}
