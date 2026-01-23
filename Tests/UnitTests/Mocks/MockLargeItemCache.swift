//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockLargeItemCache.swift
//
//  Created by Antonio Pallares on 13/1/26.

import Foundation
@testable import RevenueCat

/// A dictionary-backed mock implementation of `LargeItemCacheType` for testing.
/// Stores cached data in memory and tracks all method invocations for test verification.
final class MockLargeItemCache: LargeItemCacheType {

    private var storage: [URL: Data] = [:]
    private let lock = NSLock()

    // Invocation tracking
    var saveDataInvocations: [(data: Data, url: URL)] = []
    var cachedContentExistsInvocations: [URL] = []
    var loadFileInvocations: [URL] = []
    var removeInvocations: [URL] = []
    var createCacheDirectoryInvocations: [(basePath: String, inAppSpecificDirectory: Bool)] = []

    func saveData(_ data: Data, to url: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        saveDataInvocations.append((data: data, url: url))
        storage[url] = data
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    func saveData(_ bytes: AsyncThrowingStream<UInt8, Error>, to url: URL, checksum: Checksum?) async throws {
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
        }
        try saveData(data, to: url)
    }

    func cachedContentExists(at url: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        cachedContentExistsInvocations.append(url)
        return storage[url] != nil
    }

    func loadFile(at url: URL) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        loadFileInvocations.append(url)
        guard let data = storage[url] else {
            throw MockLargeItemCacheError.fileNotFound(url: url)
        }
        return data
    }

    func remove(_ url: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        removeInvocations.append(url)
        storage.removeValue(forKey: url)
    }

    func createCacheDirectoryIfNeeded(basePath: String, inAppSpecificDirectory: Bool) -> URL? {
        lock.lock()
        defer { lock.unlock() }

        createCacheDirectoryInvocations.append((basePath: basePath, inAppSpecificDirectory: inAppSpecificDirectory))
        return URL(string: "file:///mock/cache/\(basePath)")
    }

}

enum MockLargeItemCacheError: Error, LocalizedError {
    case fileNotFound(url: URL)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "MockLargeItemCache: File not found at URL: \(url)"
        }
    }
}
