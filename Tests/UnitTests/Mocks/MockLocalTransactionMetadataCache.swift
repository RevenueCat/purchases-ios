//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockLocalTransactionMetadataCache.swift
//
//  Created by Rick van der Linden on 30/12/2025.
//

import Foundation
@testable import RevenueCat

/// Mock implementation of LocalTransactionMetadataCacheType using an in-memory dictionary.
final class MockLocalTransactionMetadataCache: LocalTransactionMetadataCacheType, @unchecked Sendable {

    private let lock = NSLock()

    // Dictionary keys: "transaction.{id}" or "product.{id}"
    private var storage: [String: LocalTransactionMetadata] = [:]

    init() {}

    // MARK: - Locking Helper

    private func withLock<T>(_ block: () throws -> T) rethrows -> T {
        self.lock.lock()
        defer { self.lock.unlock() }
        return try block()
    }

    // MARK: - LocalTransactionMetadataCacheType

    func store(metadata: LocalTransactionMetadata, forTransactionID transactionID: String) {
        self.withLock {
            let key = self.key(forTransactionID: transactionID)
            guard self.storage[key] == nil else { return }
            self.storage[key] = metadata
        }
    }

    func store(metadata: LocalTransactionMetadata, forProductID productID: String) {
        self.withLock {
            let key = self.key(forProductID: productID)
            guard self.storage[key] == nil else { return }
            self.storage[key] = metadata
        }
    }

    func retrieve(forTransactionID transactionID: String) -> LocalTransactionMetadata? {
        return self.withLock {
            let key = self.key(forTransactionID: transactionID)
            return self.storage[key]
        }
    }

    func retrieve(forProductID productID: String) -> LocalTransactionMetadata? {
        return self.withLock {
            let key = self.key(forProductID: productID)
            return self.storage[key]
        }
    }

    func remove(forTransactionID transactionID: String) {
        self.withLock {
            let key = self.key(forTransactionID: transactionID)
            self.storage.removeValue(forKey: key)
        }
    }

    func remove(forProductID productID: String) {
        self.withLock {
            let key = self.key(forProductID: productID)
            self.storage.removeValue(forKey: key)
        }
    }

    func migrateMetadata(fromProductID productID: String, toTransactionID transactionID: String) {
        self.withLock {
            let productKey = self.key(forProductID: productID)
            let transactionKey = self.key(forTransactionID: transactionID)

            // Move the metadata from product key to transaction key
            if let metadata = self.storage[productKey] {
                // Only move if transaction key doesn't already exist
                guard self.storage[transactionKey] == nil else {
                    // If transaction key exists, just remove the product key
                    self.storage.removeValue(forKey: productKey)
                    return
                }

                self.storage[transactionKey] = metadata
                self.storage.removeValue(forKey: productKey)
            }
        }
    }

    // MARK: - Helpers

    private func key(forTransactionID transactionID: String) -> String {
        return "transaction.\(transactionID)"
    }

    private func key(forProductID productID: String) -> String {
        return "product.\(productID)"
    }

    // MARK: - Test Helpers

    /// Clears all stored metadata (useful for test cleanup)
    func clear() {
        self.withLock {
            self.storage.removeAll()
        }
    }

    /// Returns all stored metadata (useful for testing)
    var allMetadata: [String: LocalTransactionMetadata] {
        return self.withLock {
            return self.storage
        }
    }
}
