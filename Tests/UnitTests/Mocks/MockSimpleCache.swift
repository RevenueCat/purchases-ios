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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
class MockSimpleCache: LargeItemCacheType, @unchecked Sendable {

    var cacheDirectory: URL?
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

    func saveData(
        _ bytes: AsyncThrowingStream<UInt8, any Error>,
        to url: URL,
        checksum: RevenueCat.Checksum?
    ) async throws {
        let count = saveDataInvocations.count
        var data = Data()

        for try await byte in bytes {
            data.append(contentsOf: [byte])
        }

        self.saveDataInvocations.append(.init(data: data, url: url))

        switch saveDataResponses[count] {
        case .failure(let error):
            throw error
        default:
            break
        }
    }

    func cachedContentExists(at url: URL) -> Bool {
        lock.withLock {
            let count = cachedContentExistsInvocations.count
            cachedContentExistsInvocations.append(url)
            return cachedContentExistsResponses[count]
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
            switch loadFileResponses[loadFileInvocations.count - 1] {
            case .success(let data):
                return data
            case .failure(let error):
                throw error
            }
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

    func createCacheDirectoryIfNeeded(basePath: String) -> URL? {
        cacheDirectory?.appendingPathComponent(basePath)
    }

    struct SaveData: Equatable {
        var data: Data
        var url: URL
    }
}
