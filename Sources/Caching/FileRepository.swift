//
//  FileRepository.swift
//
//
//  Created by Jacob Rakidzich on 8/11/25.
//

import Foundation

/// A file cache
public class FileRepository: @unchecked Sendable {
    let networkService: SimpleNetworkService

    private let store = KeyedDeferredValueStore<InputURL, OutputURL>()
    private let fileManager: Caching

    private lazy var cacheDirectory: URL? = fileManager.cacheDirectory

    private func cacheUrl(for url: URL) -> URL? {
        cacheDirectory?.appendingPathComponent(url.lastPathComponent)
    }

    /// Create a file repository
    /// - Parameters:
    ///   - networkService: A service capable of fetching data from a URL
    ///   - fileManager: A service capable of storing data and returning the URL where that stored data exists
    public init(networkService: SimpleNetworkService = URLSession.shared, fileManager: Caching = FileManager.default) {
        self.networkService = networkService
        self.fileManager = fileManager
    }

    /// Prefetch files at the given urls
    /// - Parameter urls: An array of URL to fetch data from
    public func prefetch(urls: [InputURL]) {
        for url in urls {
            Task(priority: .high) { [weak self] in
                try await self?.getCachedURL(for: url)
            }
        }
    }

    /// Create and/or get the cached file url
    /// - Parameters:
    ///   - url: The url for the remote data to cache into a file
    public func getCachedURL(for url: InputURL) async throws -> OutputURL {
        try await store.getOrPut(
            Task(priority: .high) { [weak self] in
                guard let self, let cachedUrl = cacheUrl(for: url) else {
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

    private func downloadFile(from url: URL) async throws(FileRepository.Error) -> Data {
        do {
            return try await networkService.data(from: url)
        } catch {
            let message = "Failed to download File from \(url.absoluteString): \(error)"
            Logger.error(message)
            throw Error.failedToFetchFileFromRemoteSource(message)
        }
    }

    private func saveCachedFile(url: URL, data: Data) throws(FileRepository.Error) {
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
    public typealias InputURL = URL

    /// The output URL is the local file's URL where the data can be found after caching is complete
    public typealias OutputURL = URL

    /// File repository error cases
    public enum Error: Swift.Error {
        /// Used when creating the folder on disk fails
        case failedToCreateCacheDirectory(String)

        /// Used when saving the file on disk fails
        case failedToSaveCachedFile(String)

        /// Used when fetching the data fails
        case failedToFetchFileFromRemoteSource(String)
    }
}
