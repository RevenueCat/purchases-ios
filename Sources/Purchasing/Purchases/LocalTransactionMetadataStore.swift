//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalTransactionMetadataStore.swift
//
//  Created by Antonio Pallares on 15/12/25.
//

import Foundation

/// Protocol for storing and retrieving local transaction metadata.
protocol LocalTransactionMetadataStoreType: Sendable {

    /// Store transaction metadata for a given transaction ID.
    func store(metadata: LocalTransactionMetadata.TransactionMetadata, forTransactionID transactionId: String)

    /// Retrieve transaction metadata for a given transaction ID.
    func getMetadata(forTransactionId transactionId: String) -> LocalTransactionMetadata.TransactionMetadata?

    /// Remove transaction metadata for a given transaction ID.
    func removeMetadata(forTransactionId transactionId: String)
}

/// Cache for storing local transaction metadata persistently on disk.
final class LocalTransactionMetadataStore: LocalTransactionMetadataStoreType {

    private static let cacheKey = "local_transaction_metadata"

    private let cache: SynchronizedLargeItemCache
    private let cachedData: Atomic<LocalTransactionMetadata?> = .init(nil)

    init(fileManager: LargeItemCacheType = FileManager.default) {
        self.cache = SynchronizedLargeItemCache(cache: fileManager, basePath: "revenuecat.localTransactionMetadata")
    }

    /// Store transaction metadata for a given transaction ID.
    func store(metadata: LocalTransactionMetadata.TransactionMetadata, forTransactionID transactionId: String) {
        guard self.getMetadata(forTransactionId: transactionId) == nil else {
            Logger.debug(
                TransactionMetadataStrings.metadata_already_exists_for_transaction(
                    transactionId: transactionId
                )
            )
            return
        }

        let hash = getIdentifierHash(identifier: transactionId)

        var currentMetadata = getCachedMetadata()
        currentMetadata.transactionMetadataByIdHash[hash] = metadata
        storeMetadata(currentMetadata)
    }

    /// Retrieve transaction metadata for a given transaction ID.
    func getMetadata(forTransactionId transactionId: String) -> LocalTransactionMetadata.TransactionMetadata? {
        let hash = getIdentifierHash(identifier: transactionId)
        let currentMetadata = getCachedMetadata()
        return currentMetadata.transactionMetadataByIdHash[hash]
    }

    /// Remove transaction metadata for a given transaction ID.
    func removeMetadata(forTransactionId transactionId: String) {
        let hash = getIdentifierHash(identifier: transactionId)

        var currentMetadata = getCachedMetadata()
        guard currentMetadata.transactionMetadataByIdHash[hash] != nil else {
            Logger.debug(
                TransactionMetadataStrings.metadata_not_found_to_clear_for_transaction(
                    transactionId: transactionId
                )
            )
            return
        }

        currentMetadata.transactionMetadataByIdHash.removeValue(forKey: hash)
        storeMetadata(currentMetadata)
    }

    // MARK: - Private helper methods

    private func getIdentifierHash(identifier: String) -> String {
        return identifier.asData.sha1String
    }

    private struct CacheKey: DeviceCacheKeyType {
        let rawValue: String
    }

    private func getCachedMetadata() -> LocalTransactionMetadata {
        if let cached = self.cachedData.value {
            return cached
        }

        let key = CacheKey(rawValue: Self.cacheKey)
        let metadata: LocalTransactionMetadata = self.cache.value(forKey: key) ?? LocalTransactionMetadata()
        self.cachedData.value = metadata
        return metadata
    }

    /// Save metadata to disk and update in-memory cache
    private func storeMetadata(_ metadata: LocalTransactionMetadata) {
        struct CacheKey: DeviceCacheKeyType {
            let rawValue: String
        }
        let key = CacheKey(rawValue: Self.cacheKey)
        self.cachedData.value = metadata
        self.cache.set(codable: metadata, forKey: key)
    }

}
