//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FileRepository.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Foundation

/// A file cache
@_spi(Internal) public class FileRepository: @unchecked Sendable {
    let networkService: SimpleNetworkService

    private let store = KeyedDeferredValueStore<InputURL, OutputURL>()
    private let fileManager: Caching

    /// Create a file repository
    /// - Parameters:
    ///   - networkService: A service capable of fetching data from a URL
    ///   - fileManager: A service capable of storing data and returning the URL where that stored data exists
    @_spi(Internal) public init(
        networkService: SimpleNetworkService = URLSession.shared,
        fileManager: Caching = FileManager.default
    ) {
        self.networkService = networkService
        self.fileManager = fileManager
    }

    /// Prefetch files at the given urls
    /// - Parameter urls: An array of URL to fetch data from
    @_spi(Internal) public func prefetch(urls: [InputURL]) {
        for url in urls {
            Task(priority: .high) { [weak self] in
                try await self?.getCachedURL(for: url)
            }
        }
    }

    /// Create and/or get the cached file url
    /// - Parameters:
    ///   - url: The url for the remote data to cache into a file
    @_spi(Internal) public func getCachedURL(for url: InputURL) async throws -> OutputURL {
        try await store.getOrPut(
            Task(priority: .high) { [weak self] in
                guard let self, let cachedUrl = self.fileManager.generateLocalFilesystemURL(forRemoteURL: url) else {
                    Logger.error("Failed to create cache directory for \(url.absoluteString)")
                    throw Error.failedToCreateCacheDirectory(url.absoluteString)
                }

                if fileManager.cachedContentExists(at: cachedUrl.path) {
                    return cachedUrl
                }

                let data = try await downloadFile(from: url)
                try saveCachedFile(url: cachedUrl, data: data)
                return cachedUrl
            },
            forKey: url
        ).value
    }

    private func downloadFile(from url: URL) async throws -> Data {
        do {
            return try await networkService.data(from: url)
        } catch {
            let message = "Failed to download File from \(url.absoluteString): \(error)"
            Logger.error(message)
            throw Error.failedToFetchFileFromRemoteSource(message)
        }
    }

    private func saveCachedFile(url: URL, data: Data) throws {
        do {
            try fileManager.saveData(data, to: url)
        } catch {
            let message = "Failed to save File to \(url.absoluteString): \(error)"
            Logger.error(message)
            throw Error.failedToSaveCachedFile(message)
        }
    }
}

extension FileRepository {
    /// The input URL is the URL that the repository will read remote data from
    @_spi(Internal) public typealias InputURL = URL

    /// The output URL is the local file's URL where the data can be found after caching is complete
    @_spi(Internal) public typealias OutputURL = URL

    /// File repository error cases
    @_spi(Internal) public enum Error: Swift.Error {
        /// Used when creating the folder on disk fails
        case failedToCreateCacheDirectory(String)

        /// Used when saving the file on disk fails
        case failedToSaveCachedFile(String)

        /// Used when fetching the data fails
        case failedToFetchFileFromRemoteSource(String)
    }
}
