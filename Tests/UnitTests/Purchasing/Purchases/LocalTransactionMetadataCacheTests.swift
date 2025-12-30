//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalTransactionMetadataCacheTests.swift
//
//  Created by Rick van der Linden on 30/12/2025.

import Nimble
import XCTest

@testable import RevenueCat

class LocalTransactionMetadataCacheTests: TestCase {

    var localTransactionMetadataCache: LocalTransactionMetadataCache!

    override func setUp() {
        super.setUp()

        localTransactionMetadataCache = .init()
    }

    // MARK: Storing

    func testStoreAndRetrieveMinimalTransactionMetadataForProductID() {
        let productID = UUID().uuidString
        let transactionMetadata = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata, forProductID: productID)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forProductID: productID)
        expect(cachedTransactionMetadata) == transactionMetadata
    }

    func testStoreAndRetrieveMinimalTransactionMetadataForTransactionID() {
        let transactionID = UUID().uuidString
        let transactionMetadata = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata, forTransactionID: transactionID)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forTransactionID: transactionID)
        expect(cachedTransactionMetadata) == transactionMetadata
    }

    func testStoringMetadataForSameProductIDDoesNotOverrideExistingStoredMetadata() {
        let productID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID1)

        let productID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.2"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata2, forProductID: productID2)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forProductID: productID1)
        expect(cachedTransactionMetadata) == transactionMetadata1
    }

    func testStoringMetadataForSameTransactionIDDoesNotOverrideExistingStoredMetadata() {
        let transactionID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forTransactionID: transactionID1)

        let transactionID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.2"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata2, forTransactionID: transactionID2)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forTransactionID: transactionID1)
        expect(cachedTransactionMetadata) == transactionMetadata1
    }

    func testStoreMultipleTransactionsForProductID() {
        let productID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID1)

        let productID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.2"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata2, forProductID: productID2)

        let cachedTransactionMetadata1 = localTransactionMetadataCache.retrieve(forProductID: productID1)
        expect(cachedTransactionMetadata1) == transactionMetadata1

        let cachedTransactionMetadata2 = localTransactionMetadataCache.retrieve(forProductID: productID2)
        expect(cachedTransactionMetadata2) == transactionMetadata2
    }

    func testStoreMultipleTransactionsForTransactionID() {
        let transactionID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forTransactionID: transactionID1)

        let transactionID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.2"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata2, forTransactionID: transactionID2)

        let cachedTransactionMetadata1 = localTransactionMetadataCache.retrieve(forTransactionID: transactionID1)
        expect(cachedTransactionMetadata1) == transactionMetadata1

        let cachedTransactionMetadata2 = localTransactionMetadataCache.retrieve(forTransactionID: transactionID2)
        expect(cachedTransactionMetadata2) == transactionMetadata2
    }

    // MARK: Retrieving

    func testRetrieveNilForNonExistingTransactionID() {
        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forTransactionID: UUID().uuidString)
        expect(cachedTransactionMetadata).to(beNil())
    }

    func testRetrieveNilForNonExistingProductID() {
        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forProductID: UUID().uuidString)
        expect(cachedTransactionMetadata).to(beNil())
    }

    func testRetrieveSameTransactionMetadataForProductIDSubsequently() {
        let productID = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID)

        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata1
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata1
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata1
    }

    func testRetrieveSameTransactionMetadataForTransactionIDSubsequently() {
        let transactionID = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forTransactionID: transactionID)

        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == transactionMetadata1
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == transactionMetadata1
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == transactionMetadata1
    }

    // MARK: Removing

    func testRemoveLocalTransactionMetadataForProductID() {
        let productID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        self.localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID1)

        let productID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.2"
        )
        self.localTransactionMetadataCache.store(metadata: transactionMetadata2, forProductID: productID2)

        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID1)) != nil
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID2)) != nil

        self.localTransactionMetadataCache.remove(forProductID: productID1)

        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID1)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID2)) != nil
    }

    func testRemoveLocalTransactionMetadataForTransactionID() {
        let transactionID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.1"
        )
        self.localTransactionMetadataCache.store(metadata: transactionMetadata1, forTransactionID: transactionID1)

        let transactionID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false,
            productIdentifier: "awesome_product.2"
        )
        self.localTransactionMetadataCache.store(metadata: transactionMetadata2, forTransactionID: transactionID2)

        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID1)) != nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID2)) != nil

        self.localTransactionMetadataCache.remove(forTransactionID: transactionID1)

        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID1)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID2)) != nil
    }
}
