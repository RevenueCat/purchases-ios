//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Caching.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Foundation

/// An inteface representing a simple cache
@_spi(Internal) public protocol Caching {

    /// Store data to a url
    func saveData(_ data: Data, to url: URL) throws

    /// Check if there is content cached at the given path
    func cachedContentExists(at path: String) -> Bool

    /// Load data from url
    func loadFile(at url: URL) throws -> Data

    /// Generate a url for a location on disk based in the input URL
    func generateLocalFilesystemURL(forRemoteURL url: URL) -> URL?
}

@_spi(Internal) extension FileManager: Caching {
    /// A URL for a cache directory if one is present
    private var cacheDirectory: URL? {
        urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    /// Store data to a url
    public func saveData(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }

    /// Check if there is content cached at the given path
    public func cachedContentExists(at path: String) -> Bool {
        fileExists(atPath: path)
    }

    /// Generate a url for a location on disk based in the input URL
    public func generateLocalFilesystemURL(forRemoteURL url: URL) -> URL? {
        cacheDirectory?.appendingPathComponent(url.pathComponents.joined(separator: "/"))
    }

    /// Load data from url
    public func loadFile(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}
