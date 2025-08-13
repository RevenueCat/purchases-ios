//
//  FileRepository.swift
//
//
//  Created by Jacob Rakidzich on 8/11/25.
//

import Foundation
import RevenueCat

/// A file cache that stores videos
class FileRepository: @unchecked Sendable {
    static let shared = FileRepository()

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

    /// Create and/or get the cached file url
    /// - Parameters:
    ///   - url: The url for the remote data to cache into a file
    ///   - completion: A callback that contains the cached object if cacheing was successful, nil if not
    func getCachedURL(for url: URL, completion: @escaping (URL?) -> Void) {
        Task(priority: .high) { @Queue in
            let value = try? await store.getOrPut(
                Task(priority: .high) { [weak self] in
                    guard let self, let cachedUrl = cacheUrl(for: url) else {
                        Logger.error("Failed to create cache directory for \(url.absoluteString)")
                        throw Error.failedToCreateCacheDirectory(url.absoluteString)
                    }

                    if fileManager.fileExists(atPath: cachedUrl.path) {
                        return cachedUrl
                    }

                    let data = try await downloadVideo(from: url)
                    try data.write(to: cachedUrl)
                    return cachedUrl
                },
                forKey: url
            ).value

            completion(value)
        }
    }

    private func downloadVideo(from url: URL) async throws -> Data {
        do {
            return try await URLSession.shared.data(from: url).0
        } catch {
            let message = "Failed to download video from \(url.absoluteString): \(error)"
            Logger.error(message)
            throw Error.failedToFetchVideo(message)
        }
    }

    private func saveCachedVideo(url: URL, data: Data) throws {
        do {
            try data.write(to: url)
        } catch {
            let message = "Failed to save video to \(url.absoluteString): \(error)"
            Logger.error(message)
            throw Error.failedToSaveCachedVideo(message)
        }
    }
}

extension FileRepository {
    typealias InputURL = URL
    typealias OutputURL = URL

    enum Error: Swift.Error {
        case failedToCreateCacheDirectory(String)
        case failedToSaveCachedVideo(String)
        case failedToFetchVideo(String)
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
