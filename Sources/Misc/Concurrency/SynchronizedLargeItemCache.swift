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
internal final class SynchronizedLargeItemCache {

    private let cache: LargeItemCacheType
    private let lock: Lock
    private let cacheURL: URL?

    init(
        cache: LargeItemCacheType,
        basePath: String
    ) {
        self.cache = cache
        self.lock = Lock(.nonRecursive)

        self.cacheURL = cache.createCacheDirectoryIfNeeded(basePath: basePath)
    }

    @inline(__always)
    private func withLock<T>(
        _ action: (_ cache: LargeItemCacheType, _ documentURL: URL?) throws -> T
    ) rethrows -> T {
        return try self.lock.perform {
            return try action(self.cache, self.cacheURL)
        }
    }

    /// Get the file URL for a specific cache key
    private func getFileURL(for key: String) -> URL? {
        guard let cacheURL = self.cacheURL else {
            return nil
        }
        return cacheURL.appendingPathComponent(key)
    }

    /// Save a codable value to the cache
    @discardableResult
    func set<T: Encodable>(codable value: T, forKey key: String) -> Bool {
        guard let fileURL = self.getFileURL(for: key) else {
            Logger.error(Strings.cache.cache_url_not_available)
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
            Logger.error(Strings.cache.failed_to_save_codable_to_cache(error))
            return false
        }
    }

    /// Load a codable value from the cache
    func value<T: Decodable>(forKey key: String) -> T? {
        guard let fileURL = self.getFileURL(for: key) else {
            return nil
        }

        return self.withLock { cache, _ in
            if let data = try? cache.loadFile(at: fileURL) {
                return try? JSONDecoder.default.decode(jsonData: data, logErrors: true)
            }

            return nil
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

    func clear() {
        self.withLock { cache, cacheURL in
            // Clear the cache directory
            if let cacheURL = cacheURL {
                try? cache.remove(cacheURL)
            }
        }
    }
}

// @unchecked because:
// - The cache property is of type LargeItemCacheType which doesn't conform to Sendable
// - However, all access to the cache is synchronized through the Lock, ensuring thread-safety
extension SynchronizedLargeItemCache: @unchecked Sendable {}
