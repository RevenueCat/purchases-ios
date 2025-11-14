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
    private let documentURL: URL?

    init(cache: LargeItemCacheType, basePath: String) {
        self.cache = cache
        self.lock = Lock(.nonRecursive)
        self.documentURL = cache.createDocumentDirectoryIfNeeded(basePath: basePath)
    }

    private func read<T>(_ action: (LargeItemCacheType, URL?) throws -> T) rethrows -> T {
        return try self.lock.perform {
            return try action(self.cache, self.documentURL)
        }
    }

    private func write(_ action: (LargeItemCacheType, URL?) throws -> Void) rethrows {
        return try self.lock.perform {
            try action(self.cache, self.documentURL)
        }
    }

    /// Get the file URL for a specific cache key
    private func getFileURL(for key: DeviceCacheKeyType) -> URL? {
        guard let documentURL = self.documentURL else {
            return nil
        }
        return documentURL.appendingPathComponent(key.rawValue)
    }

    /// Save a codable value to the cache
    @discardableResult
    func set<T: Encodable>(codable value: T, forKey key: DeviceCacheKeyType) -> Bool {
        guard let fileURL = self.getFileURL(for: key) else {
            Logger.error("Cache URL is not available")
            return false
        }

        guard let data = try? JSONEncoder.default.encode(value: value, logErrors: true) else {
            return false
        }

        do {
            try self.write { cache, _ in
                try cache.saveData(data, to: fileURL)
            }
            return true
        } catch {
            Logger.error("Failed to save codable to cache: \(error)")
            return false
        }
    }

    /// Load a codable value from the cache
    func value<T: Decodable>(forKey key: DeviceCacheKeyType) -> T? {
        guard let fileURL = self.getFileURL(for: key) else {
            return nil
        }

        return self.read { cache, _ in
            guard let data = try? cache.loadFile(at: fileURL) else {
                return nil
            }

            return try? JSONDecoder.default.decode(jsonData: data, logErrors: true)
        }
    }

    /// Remove a cached item
    func removeObject(forKey key: DeviceCacheKeyType) {
        guard let fileURL = self.getFileURL(for: key) else {
            return
        }

        self.write { _, _ in
            try? self.cache.remove(fileURL)
        }
    }

}

// @unchecked because:
// - The cache property is of type LargeItemCacheType which doesn't conform to Sendable
// - However, all access to the cache is synchronized through the Lock, ensuring thread-safety
extension SynchronizedLargeItemCache: @unchecked Sendable {}
