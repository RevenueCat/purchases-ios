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

    /// Generate a url for a location on disk based in the input URL
    func generateLocalFilesystemURL(forRemoteURL url: URL) -> URL?
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

    /// Generate a url for a location on disk based in the input URL
    func generateLocalFilesystemURL(forRemoteURL url: URL) -> URL? {
        return cacheDirectory?.appendingPathComponent(url.pathComponents.joined(separator: "/"))
    }

    /// Load data from url
    func loadFile(at url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
}
