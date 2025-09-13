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
    let lock = NSLock()

    var saveDataInvocations: [SaveData] = []
    var saveDataResponses: [Result<SaveData, Error>] = []

    var cachedContentExistsInvocations: [URL] = []
    var cachedContentExistsResponses: [Bool] = []

    init(cacheDirectory: URL? = URL(string: "data:sample")) {
        self.cacheDirectory = cacheDirectory
    }

    func saveData(_ data: Data, to url: URL) throws {
        try lock.withLock {
            let count = saveDataInvocations.count
            self.saveDataInvocations.append(.init(data: data, url: url))
            switch saveDataResponses[count] {
            case .failure(let error):
                throw error
            default:
                break
            }
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
        assert(false, "to do: implement later when used")
        return Data()
    }

    func createCacheDirectoryIfNeeded(basePath: String) -> URL? {
        cacheDirectory?.appendingPathComponent(basePath)
    }

    struct SaveData: Equatable {
        var data: Data
        var url: URL
    }
}
