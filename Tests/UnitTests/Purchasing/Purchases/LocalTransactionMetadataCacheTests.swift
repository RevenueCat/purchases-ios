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
            appUserID: UUID().uuidString,
            productIdentifier: productID,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata, forProductID: productID)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forProductID: productID)
        expect(cachedTransactionMetadata) == transactionMetadata
    }

    func testStoreAndRetrieveMinimalTransactionMetadataForTransactionID() {
        let transactionID = UUID().uuidString
        let transactionMetadata = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.1",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata, forTransactionID: transactionID)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forTransactionID: transactionID)
        expect(cachedTransactionMetadata) == transactionMetadata
    }

    func testStoringMetadataForSameProductIDDoesNotOverrideExistingStoredMetadata() {
        let productID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID1,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID1)

        let productID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID2,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata2, forProductID: productID2)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forProductID: productID1)
        expect(cachedTransactionMetadata) == transactionMetadata1
    }

    func testStoringMetadataForSameTransactionIDDoesNotOverrideExistingStoredMetadata() {
        let transactionID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.1",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forTransactionID: transactionID1)

        let transactionID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.2",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata2, forTransactionID: transactionID2)

        let cachedTransactionMetadata = localTransactionMetadataCache.retrieve(forTransactionID: transactionID1)
        expect(cachedTransactionMetadata) == transactionMetadata1
    }

    func testStoreMultipleTransactionsForProductID() {
        let productID1 = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID1,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID1)

        let productID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID2,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
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
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.1",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forTransactionID: transactionID1)

        let transactionID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.2",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
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
            appUserID: UUID().uuidString,
            productIdentifier: productID,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID)

        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata1
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata1
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata1
    }

    func testRetrieveSameTransactionMetadataForTransactionIDSubsequently() {
        let transactionID = UUID().uuidString
        let transactionMetadata1 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.1",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
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
            appUserID: UUID().uuidString,
            productIdentifier: productID1,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        self.localTransactionMetadataCache.store(metadata: transactionMetadata1, forProductID: productID1)

        let productID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID2,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
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
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.1",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        self.localTransactionMetadataCache.store(metadata: transactionMetadata1, forTransactionID: transactionID1)

        let transactionID2 = UUID().uuidString
        let transactionMetadata2 = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "awesome_product.2",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )
        self.localTransactionMetadataCache.store(metadata: transactionMetadata2, forTransactionID: transactionID2)

        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID1)) != nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID2)) != nil

        self.localTransactionMetadataCache.remove(forTransactionID: transactionID1)

        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID1)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID2)) != nil
    }

    // MARK: Migrating from ProductID to TransactionID
    func testMigrateFromProductIDToTransactionID() {
        let productID = UUID().uuidString
        let transactionID = UUID().uuidString
        let transactionMetadata = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )

        self.localTransactionMetadataCache.store(metadata: transactionMetadata, forProductID: productID)
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == nil

        self.localTransactionMetadataCache.migrateMetadata(fromProductID: productID, toTransactionID: transactionID)
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == transactionMetadata
    }

    func testMigrateFromProductIDToTransactionIDWhenTransactionForTransactionIDAlreadyExists() {
        let productID = UUID().uuidString
        let transactionID = UUID().uuidString
        let transactionMetadata = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )

        self.localTransactionMetadataCache.store(metadata: transactionMetadata, forProductID: productID)
        self.localTransactionMetadataCache.store(metadata: transactionMetadata, forTransactionID: transactionID)

        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == transactionMetadata

        self.localTransactionMetadataCache.migrateMetadata(fromProductID: productID, toTransactionID: transactionID)
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == transactionMetadata
    }

    func testMigrateFromProductIDToTransactionIDWhenTransactionForProductIDDoesNotExist() {
        let productID = UUID().uuidString
        let transactionID = UUID().uuidString

        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == nil

        self.localTransactionMetadataCache.migrateMetadata(fromProductID: productID, toTransactionID: transactionID)
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == nil
    }

    // MARK: StoreTransactionType helpers
    func testRetrieveTransactionMetadataBasedOnStoreTransactionStoredByProductID() {
        let productID = UUID().uuidString
        let transactionID = UUID().uuidString
        let storeTransaction = MockStoreTransaction(
            productIdentifier: productID,
            transactionIdentifier: transactionID
        )

        let transactionMetadata = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )

        self.localTransactionMetadataCache.store(metadata: transactionMetadata, forProductID: productID)
        expect(self.localTransactionMetadataCache.retrieve(for: storeTransaction)) == transactionMetadata
    }

    func testRetrieveTransactionMetadataBasedOnStoreTransactionStoredByTransactionID() {
        let productID = UUID().uuidString
        let transactionID = UUID().uuidString
        let storeTransaction = MockStoreTransaction(
            productIdentifier: productID,
            transactionIdentifier: transactionID
        )

        let transactionMetadata = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )

        self.localTransactionMetadataCache.store(metadata: transactionMetadata, forTransactionID: transactionID)
        expect(self.localTransactionMetadataCache.retrieve(for: storeTransaction)) == transactionMetadata
    }

    func testRetrieveTransactionMetadataBasedOnStoreTransactionStoredByProductAndTransactionID() {
        let productID = UUID().uuidString
        let transactionID = UUID().uuidString
        let storeTransaction = MockStoreTransaction(
            productIdentifier: productID,
            transactionIdentifier: transactionID
        )

        let transactionMetadataForProductID = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "byProductID",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )

        let transactionMetadataForTransactionID = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: "byTransactionID",
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )

        self.localTransactionMetadataCache.store(metadata: transactionMetadataForProductID, forProductID: productID)
        self.localTransactionMetadataCache.store(
            metadata: transactionMetadataForTransactionID,
            forTransactionID: transactionID
        )
        // swiftlint:disable:next line_length
        expect(self.localTransactionMetadataCache.retrieve(for: storeTransaction)) == transactionMetadataForTransactionID
    }

    func testRetrieveTransactionMetadataBasedOnStoreTransactionMigrated() {
        let productID = UUID().uuidString
        let transactionID = UUID().uuidString
        let storeTransaction = MockStoreTransaction(
            productIdentifier: productID,
            transactionIdentifier: transactionID
        )

        let transactionMetadata = LocalTransactionMetadata(
            appUserID: UUID().uuidString,
            productIdentifier: productID,
            presentedOfferingContext: nil,
            paywallPostReceiptData: nil,
            observerMode: false
        )

        self.localTransactionMetadataCache.store(metadata: transactionMetadata, forProductID: productID)
        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == transactionMetadata
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == nil
        expect(self.localTransactionMetadataCache.retrieve(for: storeTransaction)) == transactionMetadata

        self.localTransactionMetadataCache.migrateMetadata(fromProductID: productID, toTransactionID: transactionID)

        expect(self.localTransactionMetadataCache.retrieve(forProductID: productID)) == nil
        expect(self.localTransactionMetadataCache.retrieve(forTransactionID: transactionID)) == transactionMetadata
        expect(self.localTransactionMetadataCache.retrieve(for: storeTransaction)) == transactionMetadata
    }
}

extension LocalTransactionMetadataCacheTests {
    struct MockStoreTransaction: StoreTransactionType {

        let productIdentifier: String

        let transactionIdentifier: String

        var purchaseDate: Date { Date(timeIntervalSince1970: 0) }

        var hasKnownPurchaseDate: Bool { false }

        var hasKnownTransactionIdentifier: Bool { true }

        var quantity: Int { 1 }

        var storefront: RevenueCat.Storefront? { nil }

        var jwsRepresentation: String? { nil }

        var environment: RevenueCat.StoreEnvironment? { nil}

        func finish(_ wrapper: any RevenueCat.PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {}
    }
}
