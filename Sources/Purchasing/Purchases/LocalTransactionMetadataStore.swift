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
    func storeMetadata(_ metadata: LocalTransactionMetadata, forTransactionId transactionId: String)

    /// Retrieve transaction metadata for a given transaction ID.
    func getMetadata(forTransactionId transactionId: String) -> LocalTransactionMetadata?

    /// Remove transaction metadata for a given transaction ID.
    func removeMetadata(forTransactionId transactionId: String)

    /// Retrieve all stored transaction metadata.
    func getAllStoredMetadata() -> [LocalTransactionMetadata]
}

/// Cache for storing local transaction metadata persistently on disk.
final class LocalTransactionMetadataStore: LocalTransactionMetadataStoreType {

    private static let storeKeyPrefix = "local_transaction_metadata_"

    private let cache: SynchronizedLargeItemCache

    init(apiKey: String, fileManager: LargeItemCacheType = FileManager.default) {
        self.cache = SynchronizedLargeItemCache(
            cache: fileManager,
            basePath: "revenuecat.localTransactionMetadata.\(apiKey)"
        )
    }

    /// Store transaction metadata for a given transaction ID.
    func storeMetadata(_ metadata: LocalTransactionMetadata, forTransactionId transactionId: String) {
        guard self.getMetadata(forTransactionId: transactionId) == nil else {
            Logger.debug(
                TransactionMetadataStrings.metadata_already_exists_for_transaction(
                    transactionId: transactionId
                )
            )
            return
        }

        let key = self.getStoreKey(for: transactionId)

        self.cache.set(codable: metadata, forKey: key)
    }

    /// Retrieve transaction metadata for a given transaction ID.
    func getMetadata(forTransactionId transactionId: String) -> LocalTransactionMetadata? {
        let key = self.getStoreKey(for: transactionId)
        return self.cache.value(forKey: key)
    }

    /// Remove transaction metadata for a given transaction ID.
    func removeMetadata(forTransactionId transactionId: String) {
        guard self.getMetadata(forTransactionId: transactionId) != nil else {
            Logger.debug(
                TransactionMetadataStrings.metadata_not_found_to_clear_for_transaction(
                    transactionId: transactionId
                )
            )
            return
        }

        let key = self.getStoreKey(for: transactionId)
        self.cache.removeObject(forKey: key)
    }

    /// Retrieve all stored transaction metadata.
    func getAllStoredMetadata() -> [LocalTransactionMetadata] {
        let keys = self.cache.allKeys()
        return keys.compactMap { key -> LocalTransactionMetadata? in
            // TODO: Deal with potential errors (e.g. decoding errors)
            return self.cache.value(forKey: key)
        }
    }

    // MARK: - Private helper methods

    private func getStoreKey(for identifier: String) -> String {
        return Self.storeKeyPrefix + identifier.asData.sha1String
    }

    private struct CacheKey: DeviceCacheKeyType {
        let rawValue: String
    }

    private func getCachedMetadata(forKey key: String) -> LocalTransactionMetadata? {
        let metadata: LocalTransactionMetadata? = self.cache.value(forKey: key)
        return metadata
    }

}
