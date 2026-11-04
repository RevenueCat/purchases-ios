//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockSimpleCache.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Foundation
@testable import RevenueCat

class MockSimpleCache: LargeItemCacheType, @unchecked Sendable {

    var cacheDirectory: URL?
    var workingCacheDirectory: URL?
    let lock = NSLock()

    var saveDataInvocations: [SaveData] = []
    var saveDataResponses: [Result<SaveData, Error>] = []

    var loadFileInvocations = [URL]()
    var loadFileResponses = [Result<Data, Error>]()

    var removeInvocations = [URL]()

    var cachedContentExistsInvocations: [URL] = []
    var cachedContentExistsResponses: [Bool] = []

    init(cacheDirectory: URL? = URL(string: "data:sample")) {
        self.cacheDirectory = cacheDirectory
    }

    func saveData(_ data: Data, to url: URL) throws {
        saveDataInvocations.append(.init(data: data, url: url, checksum: nil))

        if saveDataResponses.indices.contains(saveDataInvocations.count - 1) {
            switch saveDataResponses[saveDataInvocations.count - 1] {
            case .failure(let error):
                throw error
            default:
                break
            }
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    func saveDownloadedFile(
        fromTemporaryURL temporaryURL: URL,
        to url: URL,
        checksum: RevenueCat.Checksum?
    ) throws {
        let count = saveDataInvocations.count
        let data = try Data(contentsOf: temporaryURL)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        self.saveDataInvocations.append(.init(data: data, url: url, checksum: checksum))

        if saveDataResponses.indices.contains(count),
           case .failure(let error) = saveDataResponses[count] {
            throw error
        }
    }

    func cachedContentExists(at url: URL) -> Bool {
        lock.withLock {
            cachedContentExistsInvocations.append(url)

            let count = cachedContentExistsInvocations.count - 1
            if cachedContentExistsResponses.indices.contains(count) {
                return cachedContentExistsResponses[count]
            }

            return false
        }
    }

    func stubSaveData(at index: Int = 0, with result: Result<SaveData, Error>) {
        lock.withLock {
            saveDataResponses.insert(result, at: index)
        }
    }

    func stubCachedContentExists(at index: Int = 0, with result: Bool) {
        lock.withLock {
            cachedContentExistsResponses.insert(result, at: index)
        }
    }

    func loadFile(at url: URL) throws -> Data {
        try lock.withLock {
            loadFileInvocations.append(url)

            if loadFileResponses.indices.contains(loadFileInvocations.count - 1) {
                switch loadFileResponses[loadFileInvocations.count - 1] {
                case .success(let data):
                    return data
                case .failure(let error):
                    throw error
                }
            }

            throw MockSimpleCacheError.noStubConfigured(url: url)
        }
    }

    func stubLoadFile(at index: Int = 0, with result: Result<Data, Error>) {
        lock.withLock {
            loadFileResponses.insert(result, at: index)
        }
    }

    func remove(_ url: URL) throws {
        removeInvocations.append(url)
    }

    func createDirectoryIfNeeded(
        basePath: String,
        directoryType: DirectoryHelper.DirectoryType,
        inAppSpecificDirectory: Bool
    ) -> URL? {
        workingCacheDirectory = cacheDirectoryURL(basePath: basePath)
        return workingCacheDirectory
    }

    func cacheDirectoryURL(basePath: String) -> URL? {
        cacheDirectory?.appendingPathComponent(basePath)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return []
    }

    struct SaveData: Equatable {
        var data: Data
        var url: URL
        var checksum: Checksum?

        init(data: Data, url: URL, checksum: Checksum? = nil) {
            self.data = data
            self.url = url
            self.checksum = checksum
        }
    }
}

enum MockSimpleCacheError: Error, LocalizedError {
    case noStubConfigured(url: URL)

    var errorDescription: String? {
        switch self {
        case .noStubConfigured(let url):
            return "MockSimpleCache: No stub configured for URL: \(url)"
        }
    }
}
