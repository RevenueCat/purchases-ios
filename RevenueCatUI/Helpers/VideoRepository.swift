//
//  VideoRepository.swift
//
//
//  Created by Jacob Rakidzich on 8/11/25.
//

import Foundation
import RevenueCat

/// A file cache that stores videos
class VideoRepository: @unchecked Sendable {
    static let shared = VideoRepository()

    let networkService: SimpleNetworkService

    private let store = KeyedDeferredValueStore<InputURL, OutputURL>()
    private let fileManager = FileManager.default

    private lazy var cacheDirectory: URL? = fileManager
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first

    private func cacheUrl(for url: URL) -> URL? {
        cacheDirectory?.appendingPathComponent(url.lastPathComponent)
    }

    init(networkService: SimpleNetworkService = URLSession.sharedAndWaitsForConnectivity) {
        self.networkService = networkService
    }

    /// Create and/or get the cached video url
    /// - Parameters:
    ///   - url: The url for video to cache
    ///   - completion: A callback that contains the cached video if cacheing was successful, nil if not
    func getVideoURL(for url: URL, completion: @escaping (URL?) -> Void) {
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

extension VideoRepository {
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
        return try await URLSession.shared.data(from: url).0
    }

    static let sharedAndWaitsForConnectivity: URLSession = {
        var configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()
}
