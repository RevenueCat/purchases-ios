//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockUnderlyingSynchronizedFileCache.swift
//
//  Created by Jacob Zivan Rakidzich on 12/12/25.

import Foundation
@testable import RevenueCat

extension SynchronizedLargeItemCache {

    // The SynchronizedLargeItemCache does some mapping on the URLs used as storage keys. They get converted into
    // md5 strings and appended to the working directory for stable saving and reading. This mock is tailored to
    // handle that conversion during the stubbing process
    class MockUnderlyingSynchronizedFileCache: LargeItemCacheType, @unchecked Sendable {

        var cacheDirectory: URL?
        var workingCacheDirectory: URL?
        let lock = NSLock()

        var saveDataInvocations: [SaveData] = []
        var saveDataResponsesByURL: [URL: Result<SaveData, Error>] = [:]

        var loadFileInvocations = [URL]()
        var loadFileResponsesByURL: [URL: Result<Data, Error>] = [:]
        var defaultLoadFileResponse: Result<Data, Error>?

        var removeInvocations = [URL]()

        var cachedContentExistsInvocations: [URL] = []
        var cachedContentExistsByURL: [URL: Bool] = [:]
        var defaultCachedContentExistsResponse: Bool = false

        init(cacheDirectory: URL? = URL(string: "data:sample")) {
            self.cacheDirectory = cacheDirectory
        }

        func saveData(_ data: Data, to url: URL) throws {
            saveDataInvocations.append(.init(data: data, url: url))

            if let response = saveDataResponsesByURL[url] {
                if case .failure(let error) = response {
                    throw error
                }
            }
        }

        @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
        func saveData(
            _ bytes: AsyncThrowingStream<UInt8, any Error>,
            to url: URL,
            checksum: RevenueCat.Checksum?
        ) async throws {
            var data = Data()

            for try await byte in bytes {
                data.append(contentsOf: [byte])
            }

            self.saveDataInvocations.append(.init(data: data, url: url))

            if let response = saveDataResponsesByURL[url] {
                if case .failure(let error) = response {
                    throw error
                }
            }
        }

        func cachedContentExists(at url: URL) -> Bool {
            lock.withLock {
                cachedContentExistsInvocations.append(url)

                if let response = cachedContentExistsByURL[url] {
                    return response
                }

                return defaultCachedContentExistsResponse
            }
        }

        func loadFile(at url: URL) throws -> Data {
            try lock.withLock {
                loadFileInvocations.append(url)

                if let response = loadFileResponsesByURL[url] {
                    switch response {
                    case .success(let data):
                        return data
                    case .failure(let error):
                        throw error
                    }
                }

                if let defaultResponse = defaultLoadFileResponse {
                    switch defaultResponse {
                    case .success(let data):
                        return data
                    case .failure(let error):
                        throw error
                    }
                }

                throw MockSimpleCacheError.noStubConfigured(url: url)
            }
        }

        func stubLoadFile(at url: URL, with result: Result<Data, Error>) {
            lock.withLock {
                loadFileResponsesByURL[cacheURL(from: url)] = result
            }
        }

        func stubDefaultLoadFile(with result: Result<Data, Error>) {
            lock.withLock {
                defaultLoadFileResponse = result
            }
        }

        func stubSaveData(at url: URL, with result: Result<SaveData, Error>) {
            lock.withLock {
                saveDataResponsesByURL[cacheURL(from: url)] = result
            }
        }

        func stubCachedContentExists(at url: URL, with result: Bool) {
            lock.withLock {
                cachedContentExistsByURL[cacheURL(from: url)] = result
            }
        }

        func stubDefaultCachedContentExists(with result: Bool) {
            lock.withLock {
                defaultCachedContentExistsResponse = result
            }
        }

        func remove(_ url: URL) throws {
            removeInvocations.append(cacheURL(from: url))
        }

        func createCacheDirectoryIfNeeded(basePath: String) -> URL? {
            let url = cacheDirectory?.appendingPathComponent(basePath)
            workingCacheDirectory = url
            return url
        }

        private func cacheURL(from url: URL) -> URL {
            workingCacheDirectory.unsafelyUnwrapped.appendingPathComponent(url.absoluteString.asData.md5String)
        }

        // swiftlint:disable:next nesting
        typealias SaveData = MockSimpleCache.SaveData
    }
}
