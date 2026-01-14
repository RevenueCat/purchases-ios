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
        expect(self.mockCache.loadFileInvocations.count) == 1
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

        expect(self.mockCache.loadFileInvocations.count) == 1
        guard let loadedURL = self.mockCache.loadFileInvocations.first else {
            fail("No loadFile invocations")
            return
        }
        expect(loadedURL.absoluteString).to(contain(expectedKey))
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
        expect(retrieved?.transactionData.source.isRestore) == originalMetadata.transactionData.source.isRestore
        expect(
            retrieved?.transactionData.source.initiationSource
        ) == originalMetadata.transactionData.source.initiationSource
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

        let transactionData = PurchasedTransactionData(
            source: .init(isRestore: false, initiationSource: .purchase)
        )

        return LocalTransactionMetadata(
            transactionId: transactionId,
            productData: productData,
            transactionData: transactionData,
            originalPurchasesAreCompletedBy: .revenueCat
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
            storeCountry: "US",
            source: .init(isRestore: false, initiationSource: .purchase)
        )

        return LocalTransactionMetadata(
            transactionId: transactionId,
            productData: productData,
            transactionData: transactionData,
            originalPurchasesAreCompletedBy: .revenueCat
        )
    }

}
