//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalTransactionMetadataStoreTests.swift
//
//  Created by Antonio Pallares on 13/1/26.

import Nimble
import XCTest

@testable import RevenueCat

class LocalTransactionMetadataStoreTests: TestCase {

    private var mockCache: MockLargeItemCache!
    private var store: LocalTransactionMetadataStore!
    private let apiKey = "test_api_key"

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockCache = MockLargeItemCache()
        self.store = LocalTransactionMetadataStore(apiKey: self.apiKey, fileManager: self.mockCache)
    }

    // MARK: - storeMetadata tests

    func testStoreMetadataStoresCorrectly() throws {
        let transactionId = "test_transaction_123"
        let metadata = self.createTestMetadata()

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        expect(self.mockCache.saveDataInvocations.count) == 1

        // Verify the key contains the expected hashed transaction ID
        guard let savedData = self.mockCache.saveDataInvocations.first else {
            fail("No saveData invocations")
            return
        }
        let expectedHash = transactionId.asData.sha1String
        let expectedKey = "local_transaction_metadata_\(expectedHash)"
        expect(savedData.url.absoluteString).to(contain(expectedKey))
    }

    func testStoreMetadataDoesNotOverwriteExistingMetadata() throws {
        let transactionId = "test_transaction_456"
        let metadata1 = self.createTestMetadata(productIdentifier: "product_1")
        let metadata2 = self.createTestMetadata(productIdentifier: "product_2")

        // First storeMetadata call stores metadata1
        self.store.storeMetadata(metadata1, forTransactionId: transactionId)
        expect(self.mockCache.saveDataInvocations.count) == 1

        // Second storeMetadata call should not overwrite existing metadata
        self.store.storeMetadata(metadata2, forTransactionId: transactionId)

        // Should still be called only once (second call should be prevented)
        expect(self.mockCache.saveDataInvocations.count) == 1

        // Verify warning was logged
        self.logger.verifyMessageWasLogged(
            TransactionMetadataStrings.metadata_already_exists_for_transaction(
                transactionId: transactionId
            ),
            level: .debug
        )
    }

    func testStoreMetadataWithDifferentTransactionIds() throws {
        let transactionId1 = "transaction_1"
        let transactionId2 = "transaction_2"
        let metadata1 = self.createTestMetadata()
        let metadata2 = self.createTestMetadata()

        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)

        expect(self.mockCache.saveDataInvocations.count) == 2
    }

    // MARK: - getMetadata tests

    func testGetMetadataReturnsStoredMetadata() throws {
        let transactionId = "test_transaction_get"
        let metadata = self.createTestMetadata()

        // Store metadata first
        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        // Retrieve and verify
        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        expect(retrieved?.productData?.productIdentifier) == metadata.productData?.productIdentifier
        expect(retrieved?.originalPurchasesAreCompletedBy) == metadata.originalPurchasesAreCompletedBy
    }

    func testGetMetadataReturnsNilForNonExistentTransaction() throws {
        let transactionId = "non_existent_transaction"

        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).to(beNil())
        // When file doesn't exist, only cachedContentExists is called (returns false)
        expect(self.mockCache.cachedContentExistsInvocations.count) == 1
        expect(self.mockCache.loadFileInvocations.count) == 0
    }

    func testGetMetadataWithMultipleTransactions() throws {
        let transactionId1 = "transaction_1"
        let transactionId2 = "transaction_2"
        let metadata1 = self.createTestMetadata(productIdentifier: "product_1")
        let metadata2 = self.createTestMetadata(productIdentifier: "product_2")

        // Store both metadata objects
        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)

        // Retrieve and verify both
        let retrieved1 = self.store.getMetadata(forTransactionId: transactionId1)
        let retrieved2 = self.store.getMetadata(forTransactionId: transactionId2)

        expect(retrieved1?.productData?.productIdentifier) == "product_1"
        expect(retrieved2?.productData?.productIdentifier) == "product_2"
    }

    // MARK: - removeMetadata tests

    func testRemoveMetadataRemovesStoredMetadata() throws {
        let transactionId = "test_transaction_remove"
        let metadata = self.createTestMetadata()

        // Store metadata first
        self.store.storeMetadata(metadata, forTransactionId: transactionId)
        expect(self.store.getMetadata(forTransactionId: transactionId)).toNot(beNil())

        // Remove metadata
        self.store.removeMetadata(forTransactionId: transactionId)

        // Verify it's gone
        expect(self.store.getMetadata(forTransactionId: transactionId)).to(beNil())
        expect(self.mockCache.removeInvocations.count) == 1
    }

    func testRemoveMetadataForNonExistentTransactionLogsDebug() throws {
        let transactionId = "non_existent_for_removal"

        self.store.removeMetadata(forTransactionId: transactionId)

        // Should not attempt to remove if metadata doesn't exist
        expect(self.mockCache.removeInvocations.count) == 0

        // Verify debug message was logged
        self.logger.verifyMessageWasLogged(
            TransactionMetadataStrings.metadata_not_found_to_clear_for_transaction(
                transactionId: transactionId
            ),
            level: .debug
        )
    }

    func testRemoveMetadataOnlyRemovesSpecificTransaction() throws {
        let transactionId1 = "transaction_keep"
        let transactionId2 = "transaction_remove"
        let metadata1 = self.createTestMetadata()
        let metadata2 = self.createTestMetadata()

        // Store both metadata objects
        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)

        // Remove only transactionId2
        self.store.removeMetadata(forTransactionId: transactionId2)

        // Verify transactionId1 still exists and transactionId2 is gone
        expect(self.store.getMetadata(forTransactionId: transactionId1)).toNot(beNil())
        expect(self.store.getMetadata(forTransactionId: transactionId2)).to(beNil())
    }

    // MARK: - getAllStoredMetadata tests

    func testGetAllStoredMetadataReturnsEmptyArrayWhenNoMetadataStored() throws {
        let allMetadata = self.store.getAllStoredMetadata()

        expect(allMetadata).to(beEmpty())
    }

    func testGetAllStoredMetadataReturnsSingleStoredMetadata() throws {
        let transactionId = "single_transaction"
        let metadata = self.createTestMetadata(transactionId: transactionId, productIdentifier: "single_product")

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        let allMetadata = self.store.getAllStoredMetadata()

        expect(allMetadata.count) == 1
        let retrieved = allMetadata.first
        expect(retrieved?.productData?.productIdentifier) == "single_product"
        expect(retrieved?.transactionId) == transactionId
    }

    func testGetAllStoredMetadataReturnsAllStoredMetadata() throws {
        let transactionId1 = "transaction_1"
        let transactionId2 = "transaction_2"
        let transactionId3 = "transaction_3"
        let metadata1 = self.createTestMetadata(transactionId: transactionId1, productIdentifier: "product_1")
        let metadata2 = self.createTestMetadata(transactionId: transactionId2, productIdentifier: "product_2")
        let metadata3 = self.createTestMetadata(transactionId: transactionId3, productIdentifier: "product_3")

        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)
        self.store.storeMetadata(metadata3, forTransactionId: transactionId3)

        let allMetadata = self.store.getAllStoredMetadata()

        expect(allMetadata.count) == 3

        let productIdentifiers = Set(allMetadata.compactMap { $0.productData?.productIdentifier })
        expect(productIdentifiers) == Set(["product_1", "product_2", "product_3"])

        let transactionIds = Set(allMetadata.compactMap { $0.transactionId })
        expect(transactionIds) == Set([transactionId1, transactionId2, transactionId3])
    }

    func testGetAllStoredMetadataReflectsRemovals() throws {
        let transactionId1 = "transaction_keep"
        let transactionId2 = "transaction_remove"
        let metadata1 = self.createTestMetadata(transactionId: transactionId1, productIdentifier: "product_keep")
        let metadata2 = self.createTestMetadata(transactionId: transactionId2, productIdentifier: "product_remove")

        // Store both metadata objects
        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)

        // Verify both are returned
        expect(self.store.getAllStoredMetadata().count) == 2

        // Remove one
        self.store.removeMetadata(forTransactionId: transactionId2)

        // Verify only one remains
        let allMetadata = self.store.getAllStoredMetadata()
        expect(allMetadata.count) == 1
        expect(allMetadata.first?.productData?.productIdentifier) == "product_keep"
        expect(allMetadata.first?.transactionId) == "transaction_keep"
    }

    func testGetAllStoredMetadataPreservesCompleteData() throws {
        let transactionId = "complete_data_test"
        let originalMetadata = self.createCompleteTestMetadata(transactionId: transactionId)

        self.store.storeMetadata(originalMetadata, forTransactionId: transactionId)

        let allMetadata = self.store.getAllStoredMetadata()

        expect(allMetadata.count) == 1
        let retrieved = allMetadata.first
        expect(retrieved?.productData?.productIdentifier) == originalMetadata.productData?.productIdentifier
        expect(retrieved?.productData?.currencyCode) == originalMetadata.productData?.currencyCode
        expect(retrieved?.productData?.price) == originalMetadata.productData?.price
        expect(retrieved?.originalPurchasesAreCompletedBy) == originalMetadata.originalPurchasesAreCompletedBy
        expect(retrieved?.transactionId) == transactionId
    }

    // MARK: - Key hashing tests

    func testStoreKeyUsesSHA1Hashing() throws {
        let transactionId = "test_transaction_hash"
        let metadata = self.createTestMetadata()

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        let expectedHash = transactionId.asData.sha1String
        let expectedKey = "local_transaction_metadata_\(expectedHash)"

        guard let savedData = self.mockCache.saveDataInvocations.first else {
            fail("No saveData invocations")
            return
        }
        expect(savedData.url.absoluteString).to(contain(expectedKey))
    }

    func testGetMetadataKeyUsesSHA1Hashing() throws {
        let transactionId = "test_transaction_hash_get"

        _ = self.store.getMetadata(forTransactionId: transactionId)

        let expectedHash = transactionId.asData.sha1String
        let expectedKey = "local_transaction_metadata_\(expectedHash)"

        expect(self.mockCache.cachedContentExistsInvocations.count) == 1
        guard let checkedURL = self.mockCache.cachedContentExistsInvocations.first else {
            fail("No cachedContentExists invocations")
            return
        }
        expect(checkedURL.absoluteString).to(contain(expectedKey))
    }

    func testRemoveMetadataKeyUsesSHA1Hashing() throws {
        let transactionId = "test_transaction_hash_remove"
        let metadata = self.createTestMetadata()

        // Store and then remove metadata
        self.store.storeMetadata(metadata, forTransactionId: transactionId)
        self.store.removeMetadata(forTransactionId: transactionId)

        let expectedHash = transactionId.asData.sha1String
        let expectedKey = "local_transaction_metadata_\(expectedHash)"

        expect(self.mockCache.removeInvocations.count) == 1
        guard let removedURL = self.mockCache.removeInvocations.first else {
            fail("No remove invocations")
            return
        }
        expect(removedURL.absoluteString).to(contain(expectedKey))
    }

    // MARK: - Round-trip encoding/decoding tests

    func testMetadataEncodingDecodingPreservesData() throws {
        let transactionId = "roundtrip_test"
        let originalMetadata = self.createCompleteTestMetadata()

        // Store metadata
        self.store.storeMetadata(originalMetadata, forTransactionId: transactionId)

        // Retrieve and verify all fields are preserved
        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        expect(retrieved?.productData?.productIdentifier) == originalMetadata.productData?.productIdentifier
        expect(retrieved?.productData?.currencyCode) == originalMetadata.productData?.currencyCode
        expect(retrieved?.productData?.price) == originalMetadata.productData?.price
        expect(retrieved?.originalPurchasesAreCompletedBy) == originalMetadata.originalPurchasesAreCompletedBy
    }

    // MARK: - Helper methods

    private func createTestMetadata(
        transactionId: String = "test_transaction",
        productIdentifier: String = "test_product"
    ) -> LocalTransactionMetadata {
        let productData = ProductRequestData(
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
        )

        let transactionData = PurchasedTransactionData()

        return LocalTransactionMetadata(
            transactionId: transactionId,
            productData: productData,
            transactionData: transactionData,
            encodedAppleReceipt: .receipt("test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )
    }

    private func createCompleteTestMetadata(
        transactionId: String = "complete_test_transaction"
    ) -> LocalTransactionMetadata {
        let productData = ProductRequestData(
            productIdentifier: "complete_test_product",
            paymentMode: .payUpFront,
            currencyCode: "USD",
            storeCountry: "US",
            price: 19.99,
            normalDuration: "P1M",
            introDuration: "P1W",
            introDurationType: .payUpFront,
            introPrice: 4.99,
            subscriptionGroup: "test_group",
            discounts: nil
        )

        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: .init(
                offeringIdentifier: "test_offering",
                placementIdentifier: "test_placement",
                targetingContext: nil
            ),
            presentedPaywall: nil,
            unsyncedAttributes: ["key": .init(attribute: .email, value: "test@example.com")],
            metadata: ["custom_key": "custom_value"],
            aadAttributionToken: "test_token",
            storeCountry: "US"
        )

        return LocalTransactionMetadata(
            transactionId: transactionId,
            productData: productData,
            transactionData: transactionData,
            encodedAppleReceipt: .receipt("complete_test_receipt".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )
    }

}

// MARK: - Integration Tests (Real File System)

/// Integration tests for LocalTransactionMetadataStore that use the real file system
/// to verify actual persistence behavior without mocks.
class LocalTransactionMetadataStoreE2ETests: TestCase {

    private var store: LocalTransactionMetadataStore!
    private var testApiKey: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Use a unique API key per test to ensure isolation
        self.testApiKey = "integration_test_\(UUID().uuidString)"
        self.store = LocalTransactionMetadataStore(apiKey: self.testApiKey)

        // Verify store starts empty
        expect(self.store.getAllStoredMetadata()).to(beEmpty())
    }

    override func tearDownWithError() throws {
        // Clean up any stored data
        for metadata in self.store.getAllStoredMetadata() {
            self.store.removeMetadata(forTransactionId: metadata.transactionId)
        }

        // Verify store is empty after cleanup
        expect(self.store.getAllStoredMetadata()).to(beEmpty())

        self.store = nil
        self.testApiKey = nil

        try super.tearDownWithError()
    }

    // MARK: - Store and Retrieve Tests

    func testStoreAndRetrieveMetadataWithAllFields() throws {
        let transactionId = "integration_tx_\(UUID().uuidString)"
        let originalMetadata = self.createFullMetadata(transactionId: transactionId)

        // Store metadata
        self.store.storeMetadata(originalMetadata, forTransactionId: transactionId)

        // Retrieve and verify all fields
        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        expect(retrieved?.transactionId) == transactionId
        expect(retrieved?.sdkOriginated) == originalMetadata.sdkOriginated
        expect(retrieved?.originalPurchasesAreCompletedBy) == originalMetadata.originalPurchasesAreCompletedBy

        // Verify product data
        expect(retrieved?.productData?.productIdentifier) == originalMetadata.productData?.productIdentifier
        expect(retrieved?.productData?.paymentMode) == originalMetadata.productData?.paymentMode
        expect(retrieved?.productData?.currencyCode) == originalMetadata.productData?.currencyCode
        expect(retrieved?.productData?.storeCountry) == originalMetadata.productData?.storeCountry
        expect(retrieved?.productData?.price) == originalMetadata.productData?.price
        expect(retrieved?.productData?.normalDuration) == originalMetadata.productData?.normalDuration
        expect(retrieved?.productData?.introDuration) == originalMetadata.productData?.introDuration
        expect(retrieved?.productData?.introDurationType) == originalMetadata.productData?.introDurationType
        expect(retrieved?.productData?.introPrice) == originalMetadata.productData?.introPrice
        expect(retrieved?.productData?.subscriptionGroup) == originalMetadata.productData?.subscriptionGroup

        // Verify transaction data
        expect(retrieved?.transactionData.presentedOfferingContext?.offeringIdentifier)
            == originalMetadata.transactionData.presentedOfferingContext?.offeringIdentifier
        expect(retrieved?.transactionData.presentedOfferingContext?.placementIdentifier)
            == originalMetadata.transactionData.presentedOfferingContext?.placementIdentifier
        expect(retrieved?.transactionData.presentedOfferingContext?.targetingContext?.revision)
            == originalMetadata.transactionData.presentedOfferingContext?.targetingContext?.revision
        expect(retrieved?.transactionData.presentedOfferingContext?.targetingContext?.ruleId)
            == originalMetadata.transactionData.presentedOfferingContext?.targetingContext?.ruleId
        expect(retrieved?.transactionData.metadata) == originalMetadata.transactionData.metadata
        expect(retrieved?.transactionData.aadAttributionToken) == originalMetadata.transactionData.aadAttributionToken
        expect(retrieved?.transactionData.storeCountry) == originalMetadata.transactionData.storeCountry

        // Verify encoded receipt
        expect(retrieved?.encodedAppleReceipt) == originalMetadata.encodedAppleReceipt
    }

    func testStoreAndRetrieveMetadataWithNilProductData() throws {
        let transactionId = "integration_nil_product_\(UUID().uuidString)"
        let metadata = LocalTransactionMetadata(
            transactionId: transactionId,
            productData: nil,
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .empty,
            originalPurchasesAreCompletedBy: .myApp,
            sdkOriginated: false
        )

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        expect(retrieved?.transactionId) == transactionId
        expect(retrieved?.productData).to(beNil())
        expect(retrieved?.originalPurchasesAreCompletedBy) == .myApp
        expect(retrieved?.sdkOriginated) == false
    }

    func testStoreAndRetrieveMetadataWithJWSReceipt() throws {
        let transactionId = "integration_jws_\(UUID().uuidString)"
        let jwsToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.test_payload.signature"
        let metadata = LocalTransactionMetadata(
            transactionId: transactionId,
            productData: nil,
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .jws(jwsToken),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        guard case .jws(let retrievedToken) = retrieved?.encodedAppleReceipt else {
            fail("Expected .jws receipt")
            return
        }
        expect(retrievedToken) == jwsToken
    }

    func testStoreAndRetrieveMetadataWithSK2Receipt() throws {
        let transactionId = "integration_sk2_\(UUID().uuidString)"
        let sk2Receipt = StoreKit2Receipt(
            environment: .sandbox,
            subscriptionStatusBySubscriptionGroupId: [:],
            transactions: ["tx_1", "tx_2", "tx_3"],
            bundleId: "com.integration.test",
            originalApplicationVersion: "2.0.0",
            originalPurchaseDate: Date(timeIntervalSince1970: 1609459200)
        )
        let metadata = LocalTransactionMetadata(
            transactionId: transactionId,
            productData: nil,
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .sk2receipt(sk2Receipt),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        guard case .sk2receipt(let retrievedReceipt) = retrieved?.encodedAppleReceipt else {
            fail("Expected .sk2receipt")
            return
        }
        expect(retrievedReceipt.environment) == .sandbox
        expect(retrievedReceipt.bundleId) == "com.integration.test"
        expect(retrievedReceipt.originalApplicationVersion) == "2.0.0"
        expect(retrievedReceipt.transactions) == ["tx_1", "tx_2", "tx_3"]
    }

    func testStoreAndRetrieveMultipleMetadata() throws {
        let metadata1 = self.createFullMetadata(transactionId: "multi_tx_1", productIdentifier: "product_1")
        let metadata2 = self.createFullMetadata(transactionId: "multi_tx_2", productIdentifier: "product_2")
        let metadata3 = self.createFullMetadata(transactionId: "multi_tx_3", productIdentifier: "product_3")

        self.store.storeMetadata(metadata1, forTransactionId: "multi_tx_1")
        self.store.storeMetadata(metadata2, forTransactionId: "multi_tx_2")
        self.store.storeMetadata(metadata3, forTransactionId: "multi_tx_3")

        // Use getAllStoredMetadata to retrieve and verify
        let allMetadata = self.store.getAllStoredMetadata()

        expect(allMetadata.count) == 3

        let transactionIds = Set(allMetadata.map { $0.transactionId })
        expect(transactionIds) == Set(["multi_tx_1", "multi_tx_2", "multi_tx_3"])

        let productIdentifiers = Set(allMetadata.compactMap { $0.productData?.productIdentifier })
        expect(productIdentifiers) == Set(["product_1", "product_2", "product_3"])
    }

    func testGetMetadataReturnsNilForNonExistentTransaction() throws {
        let retrieved = self.store.getMetadata(forTransactionId: "non_existent_\(UUID().uuidString)")
        expect(retrieved).to(beNil())
    }

    // MARK: - Remove Metadata Tests

    func testRemoveMetadataDeletesStoredData() throws {
        let transactionId = "remove_test_\(UUID().uuidString)"
        let metadata = self.createFullMetadata(transactionId: transactionId)

        self.store.storeMetadata(metadata, forTransactionId: transactionId)
        expect(self.store.getMetadata(forTransactionId: transactionId)).toNot(beNil())

        self.store.removeMetadata(forTransactionId: transactionId)

        expect(self.store.getMetadata(forTransactionId: transactionId)).to(beNil())
    }

    func testRemoveMetadataOnlyAffectsSpecificTransaction() throws {
        let transactionId1 = "keep_\(UUID().uuidString)"
        let transactionId2 = "remove_\(UUID().uuidString)"
        let transactionId3 = "keep_also_\(UUID().uuidString)"

        let metadata1 = self.createFullMetadata(transactionId: transactionId1, productIdentifier: "keep_product")
        let metadata2 = self.createFullMetadata(transactionId: transactionId2, productIdentifier: "remove_product")
        let metadata3 = self.createFullMetadata(transactionId: transactionId3, productIdentifier: "keep_also_product")

        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)
        self.store.storeMetadata(metadata3, forTransactionId: transactionId3)

        // Remove only the second one
        self.store.removeMetadata(forTransactionId: transactionId2)

        // Verify first and third still exist with correct data
        let retrieved1 = self.store.getMetadata(forTransactionId: transactionId1)
        let retrieved3 = self.store.getMetadata(forTransactionId: transactionId3)

        expect(retrieved1).toNot(beNil())
        expect(retrieved1?.productData?.productIdentifier) == "keep_product"
        expect(retrieved3).toNot(beNil())
        expect(retrieved3?.productData?.productIdentifier) == "keep_also_product"

        // Verify second is gone
        expect(self.store.getMetadata(forTransactionId: transactionId2)).to(beNil())
    }

    func testRemoveMetadataForNonExistentTransactionDoesNotCrash() throws {
        // This should not throw or crash
        self.store.removeMetadata(forTransactionId: "non_existent_\(UUID().uuidString)")
    }

    func testRemoveMetadataTwiceDoesNotCrash() throws {
        let transactionId = "double_remove_\(UUID().uuidString)"
        let metadata = self.createFullMetadata(transactionId: transactionId)

        self.store.storeMetadata(metadata, forTransactionId: transactionId)
        self.store.removeMetadata(forTransactionId: transactionId)
        // Second removal should not crash
        self.store.removeMetadata(forTransactionId: transactionId)

        expect(self.store.getMetadata(forTransactionId: transactionId)).to(beNil())
    }

    // MARK: - Combined removeMetadata and getAllStoredMetadata Tests

    func testRemoveAllMetadataOneByOneUsingGetAllStoredMetadata() throws {
        let transactionIds = (1...4).map { "remove_all_\($0)_\(UUID().uuidString)" }

        // Store multiple metadata entries
        for transactionId in transactionIds {
            let metadata = self.createFullMetadata(transactionId: transactionId)
            self.store.storeMetadata(metadata, forTransactionId: transactionId)
        }

        expect(self.store.getAllStoredMetadata().count) == 4

        // Remove each one and verify count decreases
        for (index, transactionId) in transactionIds.enumerated() {
            self.store.removeMetadata(forTransactionId: transactionId)
            expect(self.store.getAllStoredMetadata().count) == 4 - (index + 1)
        }

        expect(self.store.getAllStoredMetadata()).to(beEmpty())
    }

    func testRemoveMetadataAndVerifyRemainingViaGetAllStoredMetadata() throws {
        let keepIds = ["keep_1", "keep_2", "keep_3"].map { "\($0)_\(UUID().uuidString)" }
        let removeIds = ["remove_1", "remove_2"].map { "\($0)_\(UUID().uuidString)" }
        let allIds = keepIds + removeIds

        // Store all metadata
        for transactionId in allIds {
            let metadata = self.createFullMetadata(transactionId: transactionId)
            self.store.storeMetadata(metadata, forTransactionId: transactionId)
        }

        expect(self.store.getAllStoredMetadata().count) == 5

        // Remove only the "remove" ones
        for transactionId in removeIds {
            self.store.removeMetadata(forTransactionId: transactionId)
        }

        // Verify via getAllStoredMetadata
        let remaining = self.store.getAllStoredMetadata()
        expect(remaining.count) == 3

        let remainingIds = Set(remaining.map { $0.transactionId })
        expect(remainingIds) == Set(keepIds)

        // Verify removed ones are not in the list
        for removeId in removeIds {
            expect(remainingIds.contains(removeId)) == false
        }
    }

    func testRemoveMetadataFromMiddleOfStoredItems() throws {
        let transactionId1 = "first_\(UUID().uuidString)"
        let transactionId2 = "middle_\(UUID().uuidString)"
        let transactionId3 = "last_\(UUID().uuidString)"

        let metadata1 = self.createFullMetadata(transactionId: transactionId1, productIdentifier: "first_product")
        let metadata2 = self.createFullMetadata(transactionId: transactionId2, productIdentifier: "middle_product")
        let metadata3 = self.createFullMetadata(transactionId: transactionId3, productIdentifier: "last_product")

        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)
        self.store.storeMetadata(metadata3, forTransactionId: transactionId3)

        // Remove the middle one
        self.store.removeMetadata(forTransactionId: transactionId2)

        // Verify via getAllStoredMetadata
        let remaining = self.store.getAllStoredMetadata()
        expect(remaining.count) == 2

        let productIds = Set(remaining.compactMap { $0.productData?.productIdentifier })
        expect(productIds) == Set(["first_product", "last_product"])
        expect(productIds.contains("middle_product")) == false
    }

    func testRemoveAndReAddMetadataReflectedInGetAllStoredMetadata() throws {
        let transactionId = "readd_\(UUID().uuidString)"
        let metadata = self.createFullMetadata(transactionId: transactionId, productIdentifier: "original_product")

        // Store, verify, remove, verify empty
        self.store.storeMetadata(metadata, forTransactionId: transactionId)
        expect(self.store.getAllStoredMetadata().count) == 1

        self.store.removeMetadata(forTransactionId: transactionId)
        expect(self.store.getAllStoredMetadata()).to(beEmpty())

        // Re-add with different product (but same transaction ID)
        let newMetadata = self.createFullMetadata(transactionId: transactionId, productIdentifier: "new_product")
        self.store.storeMetadata(newMetadata, forTransactionId: transactionId)

        let allMetadata = self.store.getAllStoredMetadata()
        expect(allMetadata.count) == 1
        expect(allMetadata.first?.productData?.productIdentifier) == "new_product"
    }

    // MARK: - GetAllStoredMetadata Tests

    func testGetAllStoredMetadataReturnsEmptyArrayWhenEmpty() throws {
        let allMetadata = self.store.getAllStoredMetadata()
        expect(allMetadata).to(beEmpty())
    }

    func testGetAllStoredMetadataReturnsSingleItem() throws {
        let transactionId = "single_\(UUID().uuidString)"
        let metadata = self.createFullMetadata(transactionId: transactionId, productIdentifier: "single_product")

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        let allMetadata = self.store.getAllStoredMetadata()

        expect(allMetadata.count) == 1
        expect(allMetadata.first?.transactionId) == transactionId
        expect(allMetadata.first?.productData?.productIdentifier) == "single_product"
    }

    func testGetAllStoredMetadataReturnsAllItems() throws {
        let transactionIds = (1...5).map { "all_test_\($0)_\(UUID().uuidString)" }

        for (index, transactionId) in transactionIds.enumerated() {
            let metadata = self.createFullMetadata(
                transactionId: transactionId,
                productIdentifier: "product_\(index)"
            )
            self.store.storeMetadata(metadata, forTransactionId: transactionId)
        }

        let allMetadata = self.store.getAllStoredMetadata()

        expect(allMetadata.count) == 5

        let retrievedTransactionIds = Set(allMetadata.map { $0.transactionId })
        expect(retrievedTransactionIds) == Set(transactionIds)

        let retrievedProductIds = Set(allMetadata.compactMap { $0.productData?.productIdentifier })
        expect(retrievedProductIds) == Set((0..<5).map { "product_\($0)" })
    }

    func testGetAllStoredMetadataReflectsRemovals() throws {
        let transactionId1 = "reflect_keep_\(UUID().uuidString)"
        let transactionId2 = "reflect_remove_\(UUID().uuidString)"

        let metadata1 = self.createFullMetadata(transactionId: transactionId1, productIdentifier: "keep_product")
        let metadata2 = self.createFullMetadata(transactionId: transactionId2, productIdentifier: "remove_product")

        self.store.storeMetadata(metadata1, forTransactionId: transactionId1)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId2)

        expect(self.store.getAllStoredMetadata().count) == 2

        self.store.removeMetadata(forTransactionId: transactionId2)

        let allMetadata = self.store.getAllStoredMetadata()
        expect(allMetadata.count) == 1
        expect(allMetadata.first?.transactionId) == transactionId1
        expect(allMetadata.first?.productData?.productIdentifier) == "keep_product"
    }

    func testGetAllStoredMetadataPreservesCompleteData() throws {
        let transactionId = "complete_data_\(UUID().uuidString)"
        let originalMetadata = self.createFullMetadata(transactionId: transactionId)

        self.store.storeMetadata(originalMetadata, forTransactionId: transactionId)

        let allMetadata = self.store.getAllStoredMetadata()
        expect(allMetadata.count) == 1

        let retrieved = allMetadata.first
        expect(retrieved?.transactionId) == transactionId
        expect(retrieved?.productData?.productIdentifier) == originalMetadata.productData?.productIdentifier
        expect(retrieved?.productData?.currencyCode) == originalMetadata.productData?.currencyCode
        expect(retrieved?.productData?.price) == originalMetadata.productData?.price
        expect(retrieved?.productData?.normalDuration) == originalMetadata.productData?.normalDuration
        expect(retrieved?.transactionData.presentedOfferingContext?.offeringIdentifier)
            == originalMetadata.transactionData.presentedOfferingContext?.offeringIdentifier
        expect(retrieved?.transactionData.metadata) == originalMetadata.transactionData.metadata
        expect(retrieved?.originalPurchasesAreCompletedBy) == originalMetadata.originalPurchasesAreCompletedBy
        expect(retrieved?.sdkOriginated) == originalMetadata.sdkOriginated
    }

    // MARK: - Data Integrity Tests

    func testMetadataIntegrityAcrossMultipleRetrievals() throws {
        let transactionId = "integrity_\(UUID().uuidString)"
        let originalMetadata = self.createFullMetadata(transactionId: transactionId)

        self.store.storeMetadata(originalMetadata, forTransactionId: transactionId)

        // Retrieve multiple times and verify consistency
        for _ in 1...5 {
            let retrieved = self.store.getMetadata(forTransactionId: transactionId)

            expect(retrieved?.transactionId) == transactionId
            expect(retrieved?.productData?.productIdentifier) == originalMetadata.productData?.productIdentifier
            expect(retrieved?.productData?.price) == originalMetadata.productData?.price
            expect(retrieved?.transactionData.metadata) == originalMetadata.transactionData.metadata
        }
    }

    func testStoreDoesNotOverwriteExistingMetadata() throws {
        let transactionId = "no_overwrite_\(UUID().uuidString)"
        let metadata1 = self.createFullMetadata(transactionId: transactionId, productIdentifier: "original_product")
        let metadata2 = self.createFullMetadata(transactionId: transactionId, productIdentifier: "attempted_overwrite")

        self.store.storeMetadata(metadata1, forTransactionId: transactionId)
        self.store.storeMetadata(metadata2, forTransactionId: transactionId)

        let retrieved = self.store.getMetadata(forTransactionId: transactionId)
        expect(retrieved?.productData?.productIdentifier) == "original_product"
    }

    func testNewStoreInstanceCanRetrievePreviouslyStoredData() throws {
        let transactionId = "persistence_\(UUID().uuidString)"
        let originalMetadata = self.createFullMetadata(transactionId: transactionId, productIdentifier: "persisted")

        self.store.storeMetadata(originalMetadata, forTransactionId: transactionId)

        // Create a new store instance with the same API key
        let newStore = LocalTransactionMetadataStore(apiKey: self.testApiKey)

        let retrieved = newStore.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        expect(retrieved?.transactionId) == transactionId
        expect(retrieved?.productData?.productIdentifier) == "persisted"
    }

    // MARK: - Discounts Integration Test

    func testStoreAndRetrieveMetadataWithDiscounts() throws {
        let transactionId = "discounts_\(UUID().uuidString)"

        let mockDiscount1 = MockStoreProductDiscount(
            offerIdentifier: "offer_1",
            currencyCode: "USD",
            price: Decimal(string: "4.99")!,
            localizedPriceString: "$4.99",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 3,
            type: .promotional
        )
        let discount1 = StoreProductDiscount.from(discount: mockDiscount1)

        let mockDiscount2 = MockStoreProductDiscount(
            offerIdentifier: "offer_2",
            currencyCode: "USD",
            price: Decimal.zero,
            localizedPriceString: "Free",
            paymentMode: .freeTrial,
            subscriptionPeriod: SubscriptionPeriod(value: 7, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )
        let discount2 = StoreProductDiscount.from(discount: mockDiscount2)

        let productData = ProductRequestData(
            productIdentifier: "product_with_discounts",
            paymentMode: .payUpFront,
            currencyCode: "USD",
            storeCountry: "US",
            price: Decimal(string: "19.99")!,
            normalDuration: "P1Y",
            introDuration: "P1W",
            introDurationType: .freeTrial,
            introPrice: Decimal.zero,
            subscriptionGroup: "premium_group",
            discounts: [discount1, discount2]
        )

        let metadata = LocalTransactionMetadata(
            transactionId: transactionId,
            productData: productData,
            transactionData: PurchasedTransactionData(),
            encodedAppleReceipt: .jws("test_token"),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )

        self.store.storeMetadata(metadata, forTransactionId: transactionId)

        let retrieved = self.store.getMetadata(forTransactionId: transactionId)

        expect(retrieved).toNot(beNil())
        expect(retrieved?.productData?.discounts?.count) == 2

        let retrievedDiscount1 = retrieved?.productData?.discounts?[0]
        expect(retrievedDiscount1?.offerIdentifier) == "offer_1"
        expect(retrievedDiscount1?.price) == Decimal(string: "4.99")!
        expect(retrievedDiscount1?.paymentMode) == .payAsYouGo
        expect(retrievedDiscount1?.subscriptionPeriod.value) == 1
        expect(retrievedDiscount1?.subscriptionPeriod.unit) == .month
        expect(retrievedDiscount1?.numberOfPeriods) == 3
        expect(retrievedDiscount1?.type) == .promotional

        let retrievedDiscount2 = retrieved?.productData?.discounts?[1]
        expect(retrievedDiscount2?.offerIdentifier) == "offer_2"
        expect(retrievedDiscount2?.price) == Decimal.zero
        expect(retrievedDiscount2?.paymentMode) == .freeTrial
        expect(retrievedDiscount2?.type) == .introductory
    }

    // MARK: - Helper Methods

    private func createFullMetadata(
        transactionId: String,
        productIdentifier: String = "integration_test_product"
    ) -> LocalTransactionMetadata {
        let productData = ProductRequestData(
            productIdentifier: productIdentifier,
            paymentMode: .payUpFront,
            currencyCode: "USD",
            storeCountry: "US",
            price: Decimal(string: "29.99")!,
            normalDuration: "P1Y",
            introDuration: "P2W",
            introDurationType: .freeTrial,
            introPrice: Decimal.zero,
            subscriptionGroup: "premium_subscription_group",
            discounts: nil
        )

        let transactionData = PurchasedTransactionData(
            presentedOfferingContext: PresentedOfferingContext(
                offeringIdentifier: "integration_offering",
                placementIdentifier: "integration_placement",
                targetingContext: .init(revision: 42, ruleId: "rule_integration_123")
            ),
            presentedPaywall: nil,
            unsyncedAttributes: nil,
            metadata: ["integration_key": "integration_value", "another_key": "another_value"],
            aadAttributionToken: "integration_attribution_token",
            storeCountry: "US"
        )

        return LocalTransactionMetadata(
            transactionId: transactionId,
            productData: productData,
            transactionData: transactionData,
            encodedAppleReceipt: .receipt("integration_receipt_data".asData),
            originalPurchasesAreCompletedBy: .revenueCat,
            sdkOriginated: true
        )
    }

}
