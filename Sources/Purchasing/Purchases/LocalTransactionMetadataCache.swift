//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalTransactionMetadataCache.swift
//
//  Created by Antonio Pallares on 15/12/25.
//

import Foundation

/*
 Metadata stored locally for a transaction to preserve context across sessions.
 This data will be cached before posting receipts and cleared upon a successful post attempt.
 */
internal struct LocalTransactionMetadata: Equatable, Codable, Sendable {

    /// The version of the schema used for encoding/decoding
    let schemaVersion: Int

    /// The app user ID of the user who created the transaction
    let appUserID: String

    /// The product identifier (used for SK1 pending transaction fallback).
    let productIdentifier: String

    /// The offering context when the transaction was initiated.
    let presentedOfferingContext: PresentedOfferingContext?

    /// The paywall event data when the transaction was initiated.
    let paywallPostReceiptData: PaywallPostReceiptData?

    /// Whether purchases are completed by RevenueCat or the app (observer mode equivalent).
    let observerMode: Bool

    init(
        appUserID: String,
        productIdentifier: String,
        presentedOfferingContext: PresentedOfferingContext?,
        paywallPostReceiptData: PaywallPostReceiptData?,
        observerMode: Bool
    ) {
        self.schemaVersion = 1
        self.appUserID = appUserID
        self.productIdentifier = productIdentifier
        self.presentedOfferingContext = presentedOfferingContext
        self.paywallPostReceiptData = paywallPostReceiptData
        self.observerMode = observerMode
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, productIdentifier, presentedOfferingContext, paywallPostReceiptData, observerMode
        case appUserID = "appUserId"
    }
}

/// Cache for storing local transaction metadata persistently on disk.
final class LocalTransactionMetadataCache: Sendable {

    private let cache: SynchronizedLargeItemCache

    init(fileManager: LargeItemCacheType = FileManager.default) {
        self.cache = SynchronizedLargeItemCache(cache: fileManager, basePath: "revenuecat.localTransactionMetadata")
    }

    /// Cache key for local transaction metadata.
    enum Key: DeviceCacheKeyType {
        case transaction(id: String)
        case product(id: String)

        var identifier: String {
            switch self {
            case .transaction(let id):
                return "transaction.\(id)"
            case .product(let id):
                return "product.\(id)"
            }
        }

        var rawValue: String {
            return "transactionMetadata.\(identifier)"
        }
    }

    /// Store transaction metadata for a given transaction ID.
    func store(metadata: LocalTransactionMetadata, forTransactionID transactionID: String) {
        guard retrieve(forTransactionID: transactionID) == nil else { return }
        self.cache.set(codable: metadata, forKey: Key.transaction(id: transactionID))
    }

    /// Store transaction metadata for a given product ID (used for SK1 pending transactions).
    func store(metadata: LocalTransactionMetadata, forProductID productID: String) {
        guard retrieve(forProductID: productID) == nil else { return }
        self.cache.set(codable: metadata, forKey: Key.product(id: productID))
    }

    /// Retrieve transaction metadata for a given transaction ID.
    func retrieve(forTransactionID transactionID: String) -> LocalTransactionMetadata? {
        self.cache.value(forKey: Key.transaction(id: transactionID))
    }

    /// Retrieve transaction metadata for a given product ID (used for SK1 pending transactions).
    func retrieve(forProductID productID: String) -> LocalTransactionMetadata? {
        self.cache.value(forKey: Key.product(id: productID))
    }

    /// Remove transaction metadata for a given transaction ID.
    func remove(forTransactionID transactionID: String) {
        self.cache.removeObject(forKey: Key.transaction(id: transactionID))
    }

    /// Remove transaction metadata for a given product ID.
    func remove(forProductID productID: String) {
        self.cache.removeObject(forKey: Key.product(id: productID))
    }

    /// Migrate metadata from product ID to transaction ID (for SK1 pending → purchased transition).
    // TODO: What about SK2 pending transactions?
    func migrateMetadata(fromProductID productID: String, toTransactionID transactionID: String) {
        self.cache.moveObject(
            fromKey: Key.product(id: productID),
            toKey: Key.transaction(id: transactionID)
        )
    }
}

/// Helpers for easy access based on a StoreTransactionType
extension LocalTransactionMetadataCache {

    /// Retrieve transaction metadata for the given transaction, based on transactionIdentifier or productIdentifier
    func retrieve(for transaction: StoreTransactionType) -> LocalTransactionMetadata? {
        retrieve(forTransactionID: transaction.transactionIdentifier)
            ??
        retrieve(forProductID: transaction.productIdentifier)
    }

    /// Remove transaction metadata for the given transaction, based on transactionIdentifier or productIdentifier
    func remove(for transaction: StoreTransactionType) {
        remove(forTransactionID: transaction.transactionIdentifier)
        remove(forProductID: transaction.productIdentifier)
    }
}
