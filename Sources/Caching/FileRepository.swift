//
//  FileRepository.swift
//
//
//  Created by Jacob Rakidzich on 8/11/25.
//

import Foundation

/// A file cache that stores Files
public class FileRepository: @unchecked Sendable {
    // Will likely not stick with a shared instance, but it's helpful to get things working at the moment
    /// A shared instance of the file repository
    public static let shared = FileRepository()

    let networkService: SimpleNetworkService

    private let store = KeyedDeferredValueStore<InputURL, OutputURL>()
    private let fileManager = FileManager.default

    private lazy var cacheDirectory: URL? = fileManager
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first

    private func cacheUrl(for url: URL) -> URL? {
        cacheDirectory?.appendingPathComponent(url.lastPathComponent)
    }

    init(networkService: SimpleNetworkService = URLSession.shared) {
        self.networkService = networkService
    }

    /// Prefetch files at the given urls
    /// - Parameter urls: An array of URL to fetch data from
    public func prefetch(urls: [InputURL]) {
        for url in urls {
            getCachedURL(for: url) { _ in }
        }
    }

    /// Create and/or get the cached file url
    /// - Parameters:
    ///   - url: The url for the remote data to cache into a file
    ///   - completion: A callback that contains the cached object if cacheing was successful, nil if not
    public func getCachedURL(
        for url: InputURL,
        completion: @escaping (Result<URL, Swift.Error>) -> Void
    ) {
        Task(priority: .high) { @Queue in
            let value = await store.getOrPut(
                Task(priority: .high) { [weak self] in
                    guard let self, let cachedUrl = cacheUrl(for: url) else {
                        Logger.error("Failed to create cache directory for \(url.absoluteString)")
                        throw Error.failedToCreateCacheDirectory(url.absoluteString)
                    }

                    if fileManager.fileExists(atPath: cachedUrl.path) {
                        return cachedUrl
                    }

                    let data = try await downloadFile(from: url)
                    try saveCachedFile(url: cachedUrl, data: data)
                    return cachedUrl
                },
                forKey: url
            ).result

            completion(value)
        }
    }

    private func downloadFile(from url: URL) async throws(FileRepository.Error) -> Data {
        do {
            return try await URLSession.shared.data(from: url).0
        } catch {
            let message = "Failed to download File from \(url.absoluteString): \(error)"
            Logger.error(message)
            throw Error.failedToFetchFileFromRemoteSource(message)
        }
    }

    private func saveCachedFile(url: URL, data: Data) throws(FileRepository.Error) {
        do {
            try data.write(to: url)
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

    @globalActor actor Queue {
        private init() { }
        static let shared = Queue()
    }
}

extension URLSession: @retroactive SimpleNetworkService {
    /// Fetch data from the network
    /// - Parameter url: The URL to fetch data from
    /// - Returns: Data upon success
    public func data(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpURLResponse = response as? HTTPURLResponse, !(200..<300).contains(httpURLResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
