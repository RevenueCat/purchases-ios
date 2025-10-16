//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LargeItemCacheType.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Foundation

/// An inteface representing a simple cache
protocol LargeItemCacheType {

    /// Store data to a url
    func saveData(_ data: Data, to url: URL) throws

    /// Check if there is content cached at the url
    func cachedContentExists(at url: URL) -> Bool

    /// Load data from url
    func loadFile(at url: URL) throws -> Data

    /// delete data at url
    func remove(_ url: URL) throws

    /// Creates a directory in the cache from a base path
    func createCacheDirectoryIfNeeded(basePath: String) -> URL?
}

extension FileManager: LargeItemCacheType {
    /// A URL for a cache directory if one is present
    private var cacheDirectory: URL? {
        return urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    /// Store data to a url
    func saveData(_ data: Data, to url: URL) throws {
        return try data.write(to: url)
    }

    /// Check if there is content cached at the given path
    func cachedContentExists(at url: URL) -> Bool {
        return (try? loadFile(at: url)) != nil
    }

    /// Creates a directory in the cache from a base path
    func createCacheDirectoryIfNeeded(basePath: String) -> URL? {
        guard let cacheDirectory else {
            return nil
        }

        let path = cacheDirectory.appendingPathComponent(basePath)
        do {
            try FileManager.default.createDirectory(
                at: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            let message = Strings.fileRepository.failedToCreateCacheDirectory(path).description
            Logger.error(message)
        }

        return path
    }

    /// Load data from url
    func loadFile(at url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

    func remove(_ url: URL) throws {
        try self.removeItem(at: url)
    }
}
