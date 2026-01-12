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
    private let documentsDirectoryMigrationStrategy: DocumentsDirectoryMigrationStrategy?
    private let fileManager = FileManager.default
    private var hasDeletedOldDirectory = false

    init(
        cache: LargeItemCacheType,
        basePath: String,
        documentsDirectoryMigrationStrategy: DocumentsDirectoryMigrationStrategy? = nil
    ) {
        self.cache = cache
        self.documentsDirectoryMigrationStrategy = documentsDirectoryMigrationStrategy
        self.lock = Lock(.nonRecursive)

        self.cacheURL = cache.createCacheDirectoryIfNeeded(basePath: basePath)
    }

    private func read<T>(_ action: (LargeItemCacheType, URL?) throws -> T) rethrows -> T {
        return try self.lock.perform {
            self.deleteOldDirectoryIfNeededLazy()
            return try action(self.cache, self.cacheURL)
        }
    }

    private func write(_ action: (LargeItemCacheType, URL?) throws -> Void) rethrows {
        return try self.lock.perform {
            self.deleteOldDirectoryIfNeededLazy()
            try action(self.cache, self.cacheURL)
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
            try self.write { [weak self] cache, _ in
                try cache.saveData(data, to: fileURL)

                // Delete old file if it exists
                if let oldFileURL = self?.oldFileURL(for: key),
                   self?.fileManager.fileExists(atPath: oldFileURL.path) == true {
                    try? self?.fileManager.removeItem(at: oldFileURL)
                    try? self?.deleteOldDirectoryIfEmpty()
                }
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

        return self.read { [weak self] cache, _ in
            if let data = try? cache.loadFile(at: fileURL) {
                return try? JSONDecoder.default.decode(jsonData: data, logErrors: true)
            }

            // Check if the file exists in the old documents directory
            if let oldFileURL = self?.oldFileURL(for: key), let data = try? cache.loadFile(at: oldFileURL) {
                let data: T? = try? JSONDecoder.default.decode(jsonData: data, logErrors: true)

                // Migrate file and remove old directory if it's empty
                if let fileManager = self?.fileManager {
                    try? fileManager.moveItem(at: oldFileURL, to: fileURL)
                }
                try? self?.deleteOldDirectoryIfEmpty()

                return data
            }

            return nil
        }
    }

    /// Remove a cached item
    func removeObject(forKey key: String) {
        guard let fileURL = self.getFileURL(for: key) else {
            return
        }

        self.write { _, _ in
            try? self.cache.remove(fileURL)
        }
    }

    func clear() {
        self.write { cache, cacheURL in
            // Clear the cache directory
            if let cacheURL = cacheURL {
                try? cache.remove(cacheURL)
            }

            // Delete the old documents directory if it exists (for both migration strategies)
            if let oldDirectoryURL = self.oldDirectoryURL,
               self.fileManager.fileExists(atPath: oldDirectoryURL.path) {
                try? self.fileManager.removeItem(at: oldDirectoryURL)
            }
        }
    }

    private func oldFileURL(for key: String) -> URL? {
        return oldDirectoryURL?.appendingPathComponent(key)
    }

    private var oldDirectoryURL: URL? {
        guard let oldBasePath = documentsDirectoryMigrationStrategy?.oldBasePath else { return nil }

        guard let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        return documentsURL.appendingPathComponent(oldBasePath)
    }

    private func deleteOldDirectoryIfNeededLazy() {
        guard !self.hasDeletedOldDirectory else {
            return
        }

        guard let documentsDirectoryMigrationStrategy, case .remove = documentsDirectoryMigrationStrategy,
                let oldDirectoryURL else {
            self.hasDeletedOldDirectory = true
            return
        }

        guard fileManager.fileExists(atPath: oldDirectoryURL.path) else {
            self.hasDeletedOldDirectory = true
            return
        }

        do {
            try fileManager.removeItem(at: oldDirectoryURL)
        } catch {
            Logger.error(Strings.cache.failed_to_delete_old_cache_directory(error))
        }

        self.hasDeletedOldDirectory = true
    }

    private func deleteOldDirectoryIfEmpty() throws {
        guard let oldDirectoryURL else {
            return
        }

        guard fileManager.fileExists(atPath: oldDirectoryURL.path),
            try fileManager.contentsOfDirectory(atPath: oldDirectoryURL.path).isEmpty else {
            return
        }

        do {
            try fileManager.removeItem(at: oldDirectoryURL)
        } catch {
            Logger.error(Strings.cache.failed_to_delete_old_cache_directory(error))
        }
    }
}

extension SynchronizedLargeItemCache {
    /// Migration strategy for handling old cache directories when moving from documents to cache directory
    enum DocumentsDirectoryMigrationStrategy {
        /// Remove the old directory at the specified base path from documents directory
        case remove(oldBasePath: String)

        /// Migrate files from the old documents directory to the new directory as they are read/updated
        case migrate(oldBasePath: String)

        var oldBasePath: String {
            switch self {
            case let .remove(oldBasePath), let .migrate(oldBasePath: oldBasePath):
                return oldBasePath
            }
        }
    }
}

// @unchecked because:
// - The cache property is of type LargeItemCacheType which doesn't conform to Sendable
// - However, all access to the cache is synchronized through the Lock, ensuring thread-safety
extension SynchronizedLargeItemCache: @unchecked Sendable {}
