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

/// A file repository
@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
@_spi(Internal) public final class FileRepository: FileRepositoryType, @unchecked Sendable {
    /// A shared file repository
    @_spi(Internal) public static let shared = FileRepository()

    private static let defaultBasePath = "RevenueCat"

    let networkService: SimpleNetworkServiceType

    private let store = KeyedDeferredValueStore<JobKey, OutputURL>()
    private let fileManager: LargeItemCacheType
    private let cacheURL: URL?

    /// Create a file repository
    /// - Parameters:
    ///   - networkService: A service capable of fetching data from a URL
    ///   - fileManager: A service capable of storing data and returning the URL where that stored data exists
    init(
        networkService: SimpleNetworkServiceType = URLSession.shared,
        fileManager: LargeItemCacheType = FileManager.default,
        basePath: String = FileRepository.defaultBasePath
    ) {
        self.networkService = networkService
        self.fileManager = fileManager

        self.cacheURL = fileManager.createCacheDirectoryIfNeeded(basePath: basePath)
    }

    /// Create a file repository
    @_spi(Internal) public convenience init() {
        self.init(
            networkService: URLSession.shared,
            fileManager: FileManager.default
        )
    }

    /// Prefetch files at the given urls
    /// - Parameter urls: An array of URL to fetch data from
    @_spi(Internal) public func prefetch(urls: [InputURL]) {
        for url in urls {
            Task { [weak self] in
                try await self?.generateOrGetCachedFileURL(for: url, withChecksum: nil)
            }
        }
    }

    /// Create and/or get the cached file url
    /// - Parameters:
    ///   - url: The url for the remote data to cache into a file
    @_spi(Internal) public func generateOrGetCachedFileURL(
        for url: InputURL,
        withChecksum checksum: Checksum?
    ) async throws -> OutputURL {
        return try await store.getOrPut(
            Task { [weak self] in
                guard let self,
                      let cachedUrl = self.generateLocalFilesystemURL(
                        forRemoteURL: url,
                        withChecksum: checksum
                      )
                else {
                    Logger.error(Strings.fileRepository.failedToCreateCacheDirectory(url).description)
                    throw Error.failedToCreateCacheDirectory(url.absoluteString)
                }

                if self.fileManager.cachedContentExists(at: cachedUrl) {
                    return cachedUrl
                }

                let bytes = try await self.getBytes(from: url)

                try await self.saveCachedFile(url: cachedUrl, fromBytes: bytes, withChecksum: checksum)
                return cachedUrl
            },
            forKey: JobKey(url, checksum)
        ).value
    }

    /// Get the cached file url (if it exists)
    /// - Parameters:
    ///   - url: The url for the remote data to cache into a file
    @_spi(Internal) public func getCachedFileURL(for url: InputURL, withChecksum checksum: Checksum?) -> OutputURL? {
        let cachedUrl = self.generateLocalFilesystemURL(forRemoteURL: url, withChecksum: checksum)

        if let cachedUrl, self.fileManager.cachedContentExists(at: cachedUrl) {
            return cachedUrl
        }

        return nil
    }

    private func getBytes(from url: URL) async throws -> AsyncThrowingStream<UInt8, Swift.Error> {
        do {
            return try await networkService.bytes(from: url)
        } catch {
            let message = Strings.fileRepository.failedToFetchFileFromRemoteSource(url, error).description
            Logger.error(message)
            throw Error.failedToFetchFileFromRemoteSource(message)
        }
    }

    private func saveCachedFile(
        url: URL,
        fromBytes bytes: AsyncThrowingStream<UInt8, Swift.Error>,
        withChecksum checksum: Checksum?
    ) async throws {
        do {
            try await fileManager.saveData(bytes, to: url, checksum: checksum)
        } catch {
            let message = Strings.fileRepository.failedToSaveCachedFile(url, error).description
            Logger.error(message)
            throw Error.failedToSaveCachedFile(message)
        }
    }

    func generateLocalFilesystemURL(forRemoteURL url: URL, withChecksum checksum: Checksum?) -> URL? {
        let path = checksum?.value ?? url.absoluteString.asData.md5String
        return cacheURL?
            .appendingPathComponent(path + url.lastPathComponent)
    }
}

/// A file cache
@_spi(Internal) public protocol FileRepositoryType: Sendable {

    /// Prefetch files at the given urls
    /// - Parameter urls: An array of URL to fetch data from
    func prefetch(urls: [InputURL])

    /// Create and/or get the cached file url
    /// - Parameters:
    ///   - url: The url for the remote data to cache into a file
    ///   - checksum: A checksum of the remote file if there is any
    func generateOrGetCachedFileURL(
        for url: InputURL,
        withChecksum checksum: Checksum?
    ) async throws -> OutputURL
}

/// The input URL is the URL that the repository will read remote data from
@_spi(Internal) public typealias InputURL = URL

/// The output URL is the local file's URL where the data can be found after caching is complete
@_spi(Internal) public typealias OutputURL = URL

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
extension FileRepository {

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

private struct JobKey: Hashable {
    let url: InputURL
    let checksum: Checksum?

    init(_ url: InputURL, _ checksum: Checksum?) {
        self.url = url
        self.checksum = checksum
    }
}
