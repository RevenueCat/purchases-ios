//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SynchronizedLargeItemCache.swift
//
//  Created by Jacob Zivan Rakidzich on 10/9/25.

import Foundation

/// A thread-safe wrapper around `LargeItemCacheType` for synchronized file-based caching operations.
///
/// - Important: Cache keys must not contain path separators (`/`). Keys are used directly as file names,
///   so including path separators would create nested directories and break key retrieval via `allKeys()`.
internal final class SynchronizedLargeItemCache {

    private let cache: LargeItemCacheType
    private let lock: Lock
    private let documentURL: URL?

    init(cache: LargeItemCacheType, basePath: String) {
        self.cache = cache
        self.lock = Lock(.nonRecursive)
        self.documentURL = cache.createDocumentDirectoryIfNeeded(basePath: basePath)
    }

    @inline(__always)
    private func withLock<T>(
        _ action: (_ cache: LargeItemCacheType, _ documentURL: URL?) throws -> T
    ) rethrows -> T {
        return try self.lock.perform {
            return try action(self.cache, self.documentURL)
        }
    }

    /// Get the file URL for a specific cache key
    private func getFileURL(for key: String) -> URL? {
        assert(!key.contains("/"), "Cache key must not contain path separators: \(key)")

        guard let documentURL = self.documentURL else {
            return nil
        }
        return documentURL.appendingPathComponent(key)
    }

    /// Save a codable value to the cache
    @discardableResult
    func set<T: Encodable>(codable value: T, forKey key: String) -> Bool {
        guard let fileURL = self.getFileURL(for: key) else {
            Logger.error("Cache URL is not available")
            return false
        }

        guard let data = try? JSONEncoder.default.encode(value: value, logErrors: true) else {
            return false
        }

        do {
            try self.withLock { cache, _ in
                try cache.saveData(data, to: fileURL)
            }
            return true
        } catch {
            Logger.error("Failed to save codable to cache: \(error)")
            return false
        }
    }

    /// Load a codable value from the cache
    /// - Throws: If the file cannot be loaded or decoded
    func value<T: Decodable>(forKey key: String) throws -> T? {
        guard let fileURL = self.getFileURL(for: key) else {
            return nil
        }

        return try self.withLock { cache, _ in
            guard cache.cachedContentExists(at: fileURL) else {
                return nil
            }

            let data = try cache.loadFile(at: fileURL)
            return try JSONDecoder.default.decode(jsonData: data)
        }
    }

    /// Remove a cached item
    func removeObject(forKey key: String) {
        guard let fileURL = self.getFileURL(for: key) else {
            return
        }

        self.withLock { cache, _ in
            try? cache.remove(fileURL)
        }
    }

    /// Get all keys in the cache
    func allKeys() -> [String] {
        guard let documentURL = self.documentURL else {
            return []
        }

        return self.withLock { cache, _ in
            do {
                let fileURLs = try cache.contentsOfDirectory(at: documentURL)
                return fileURLs.map { $0.lastPathComponent }
            } catch {
                Logger.error("Failed to read cache contents: \(error)")
                return []
            }
        }
    }

    func clear() {
        guard let documentURL = self.documentURL else {
            return
        }

        try? self.cache.remove(documentURL)
    }
}

// @unchecked because:
// - The cache property is of type LargeItemCacheType which doesn't conform to Sendable
// - However, all access to the cache is synchronized through the Lock, ensuring thread-safety
extension SynchronizedLargeItemCache: @unchecked Sendable {}
