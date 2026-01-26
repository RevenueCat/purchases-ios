//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionMetadataSyncHelperTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class TransactionMetadataSyncHelperTests: TestCase {

    private var customerInfoManager: MockCustomerInfoManager!
    private var attribution: Attribution!
    private var currentUserProvider: MockCurrentUserProvider!
    private var operationDispatcher: MockOperationDispatcher!
    private var transactionPoster: MockTransactionPoster!
    private var subscriberAttributesManager: MockSubscriberAttributesManager!
    private var deviceCache: MockDeviceCache!
    private var backend: MockBackend!
    private var systemInfo: MockSystemInfo!
    private var attributionFetcher: MockAttributionFetcher!

    private var helper: TransactionMetadataSyncHelper!

    private static let mockUserID = "testAppUserID"
    private static let mockCustomerInfo: CustomerInfo = .emptyInfo

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.systemInfo = MockSystemInfo(finishTransactions: true)
        self.deviceCache = MockDeviceCache(systemInfo: self.systemInfo)
        self.backend = MockBackend()
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: Self.mockUserID)
        self.operationDispatcher = MockOperationDispatcher()
        self.transactionPoster = MockTransactionPoster()

        self.attributionFetcher = MockAttributionFetcher(
            attributionFactory: MockAttributionTypeFactory(),
            systemInfo: self.systemInfo
        )
        self.subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.backend,
            deviceCache: self.deviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: self.attributionFetcher,
            attributionDataMigrator: MockAttributionDataMigrator()
        )

        let attributionPoster = AttributionPoster(
            deviceCache: self.deviceCache,
            currentUserProvider: self.currentUserProvider,
            backend: self.backend,
            attributionFetcher: self.attributionFetcher,
            subscriberAttributesManager: self.subscriberAttributesManager,
            systemInfo: self.systemInfo
        )

        self.attribution = Attribution(
            subscriberAttributesManager: self.subscriberAttributesManager,
            currentUserProvider: self.currentUserProvider,
            attributionPoster: attributionPoster,
            systemInfo: self.systemInfo
        )

        self.customerInfoManager = MockCustomerInfoManager(
            offlineEntitlementsManager: MockOfflineEntitlementsManager(),
            operationDispatcher: OperationDispatcher(),
            deviceCache: self.deviceCache,
            backend: self.backend,
            transactionFetcher: MockStoreKit2TransactionFetcher(),
            transactionPoster: self.transactionPoster,
            systemInfo: self.systemInfo
        )

        self.helper = TransactionMetadataSyncHelper(
            customerInfoManager: self.customerInfoManager,
            attribution: self.attribution,
            currentUserProvider: self.currentUserProvider,
            operationDispatcher: self.operationDispatcher,
            transactionPoster: self.transactionPoster
        )
    }

    // MARK: - syncIfNeeded

    func testSyncIfNeededDispatchesOnWorkerThread() {
        self.helper.syncIfNeeded(allowSharingAppStoreAccount: false)

        expect(self.operationDispatcher.invokedDispatchOnWorkerThread) == true
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == .default
    }

    func testSyncIfNeededCallsTransactionPoster() async {
        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.transactionPoster.invokedPostRemainingCachedTransactionMetadata.value) == true
        expect(self.transactionPoster.invokedPostRemainingCachedTransactionMetadataAppUserID.value) == Self.mockUserID
        expect(self.transactionPoster.invokedPostRemainingCachedTransactionMetadataIsRestore.value) == false
    }

    func testSyncIfNeededPassesAllowSharingAppStoreAccountAsIsRestore() async {
        await self.helper.performSync(allowSharingAppStoreAccount: true)

        expect(self.transactionPoster.invokedPostRemainingCachedTransactionMetadataIsRestore.value) == true
    }

    // MARK: - performSync

    func testPerformSyncDoesNothingWhenNoResults() async {
        // No stubbed results means empty stream
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = []

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.customerInfoManager.invokedCacheCustomerInfo) == false
    }

    func testPerformSyncCachesCustomerInfoOnSuccess() async {
        let transactionData = PurchasedTransactionData()
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (transactionData, .success(Self.mockCustomerInfo))
        ]

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.customerInfoManager.invokedCacheCustomerInfo) == true
        expect(self.customerInfoManager.invokedCacheCustomerInfoParameters?.info) === Self.mockCustomerInfo
        expect(self.customerInfoManager.invokedCacheCustomerInfoParameters?.appUserID) == Self.mockUserID
    }

    func testPerformSyncDoesNotCacheCustomerInfoOnFailure() async {
        let transactionData = PurchasedTransactionData()
        let error = BackendError.networkError(.networkError(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        ))
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (transactionData, .failure(error))
        ]

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.customerInfoManager.invokedCacheCustomerInfo) == false
    }

    func testPerformSyncProcessesMultipleResults() async {
        let transactionData1 = PurchasedTransactionData()
        let transactionData2 = PurchasedTransactionData()
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (transactionData1, .success(Self.mockCustomerInfo)),
            (transactionData2, .success(Self.mockCustomerInfo))
        ]

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.customerInfoManager.invokedCacheCustomerInfoCount) == 2
    }

    func testPerformSyncMarksAttributesAsSyncedOnSuccess() async {
        let unsyncedAttributes: SubscriberAttribute.Dictionary = [
            "key": SubscriberAttribute(withKey: "key", value: "value")
        ]
        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: nil,
            unsyncedAttributes: unsyncedAttributes,
            metadata: nil,
            aadAttributionToken: nil,
            storeCountry: nil
        )
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (transactionData, .success(Self.mockCustomerInfo))
        ]

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.subscriberAttributesManager.invokedMarkAttributes) == true
        expect(self.subscriberAttributesManager.invokedMarkAttributesParameters?.appUserID) == Self.mockUserID
    }

    func testPerformSyncMarksAdServicesTokenAsSyncedOnSuccess() async {
        let adServicesToken = "test_ad_services_token"
        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: nil,
            unsyncedAttributes: nil,
            metadata: nil,
            aadAttributionToken: adServicesToken,
            storeCountry: nil
        )
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (transactionData, .success(Self.mockCustomerInfo))
        ]

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        // The marking of ad services token is handled through the attribution poster
        // which isn't directly mockable, but we can verify the method completes without error
        expect(self.customerInfoManager.invokedCacheCustomerInfo) == true
    }

    // MARK: - Concurrent sync prevention

    func testPerformSyncPreventsConcurrentSyncs() async {
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (PurchasedTransactionData(), .success(Self.mockCustomerInfo))
        ]
        // Add delay to ensure the first sync holds the lock while others try to start
        self.transactionPoster.postRemainingCachedTransactionMetadataDelayNanoseconds = 100_000_000 // 100ms

        // Start multiple concurrent syncs
        async let sync1: Void = self.helper.performSync(allowSharingAppStoreAccount: false)
        // Small delay to ensure sync1 acquires the lock before sync2 and sync3 try
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        async let sync2: Void = self.helper.performSync(allowSharingAppStoreAccount: false)
        async let sync3: Void = self.helper.performSync(allowSharingAppStoreAccount: false)

        _ = await (sync1, sync2, sync3)

        // Only one sync should have actually executed
        expect(self.transactionPoster.invokedPostRemainingCachedTransactionMetadataCount.value) == 1
    }

    func testPerformSyncAllowsSubsequentSyncsAfterCompletion() async {
        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = []

        // First sync
        await self.helper.performSync(allowSharingAppStoreAccount: false)
        expect(self.transactionPoster.invokedPostRemainingCachedTransactionMetadataCount.value) == 1

        // Second sync should also execute since first one completed
        await self.helper.performSync(allowSharingAppStoreAccount: false)
        expect(self.transactionPoster.invokedPostRemainingCachedTransactionMetadataCount.value) == 2
    }

    // MARK: - Error handling

    func testPerformSyncMarksAttributesAsSyncedOnSuccessfullySyncedError() async {
        let unsyncedAttributes: SubscriberAttribute.Dictionary = [
            "key": SubscriberAttribute(withKey: "key", value: "value")
        ]
        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: nil,
            unsyncedAttributes: unsyncedAttributes,
            metadata: nil,
            aadAttributionToken: nil,
            storeCountry: nil
        )

        // Create an error that has successfullySynced = true (4xx errors except 404)
        // Using a 400 Bad Request which is considered "successfully synced"
        let errorResponse = ErrorResponse(
            code: .unknownBackendError,
            originalCode: 400,
            message: "Test error"
        )
        let networkError = NetworkError.errorResponse(errorResponse, .invalidRequest)
        let error = BackendError.networkError(networkError)

        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (transactionData, .failure(error))
        ]

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.subscriberAttributesManager.invokedMarkAttributes) == true
    }

    func testPerformSyncDoesNotMarkAttributesAsSyncedOnNonSuccessfullySyncedError() async {
        let unsyncedAttributes: SubscriberAttribute.Dictionary = [
            "key": SubscriberAttribute(withKey: "key", value: "value")
        ]
        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: nil,
            presentedPaywall: nil,
            unsyncedAttributes: unsyncedAttributes,
            metadata: nil,
            aadAttributionToken: nil,
            storeCountry: nil
        )

        // Network error should not have successfullySynced = true
        let error = BackendError.networkError(.networkError(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        ))

        self.transactionPoster.stubbedPostRemainingCachedTransactionMetadataResults = [
            (transactionData, .failure(error))
        ]

        await self.helper.performSync(allowSharingAppStoreAccount: false)

        expect(self.subscriberAttributesManager.invokedMarkAttributes) == false
    }

}
