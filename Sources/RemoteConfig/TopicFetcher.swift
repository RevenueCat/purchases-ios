//
//  TopicFetcher.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import CryptoKit
import Foundation

protocol FileManaging: AnyObject {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes attr: [FileAttributeKey: Any]?
    ) throws
    func replaceItemAt(
        _ originalItemURL: URL,
        withItemAt newItemURL: URL,
        backupItemName: String?,
        options mask: FileManager.ItemReplacementOptions
    ) throws -> URL?
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func removeItem(at url: URL) throws
}

extension FileManager: FileManaging {}

protocol BlobDownloader: AnyObject {
    func fetchRawData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void)
}

extension HTTPClient: BlobDownloader {}

final class URLSessionBlobDownloader: BlobDownloader {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRawData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        self.session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode != 200 {
                completion(.failure(URLError(.badServerResponse)))
            } else if let data {
                completion(.success(data))
            } else {
                completion(.failure(URLError(.unknown)))
            }
        }.resume()
    }

}

class TopicFetcher {

    private static let topicsRoot = "RevenueCat/topics"
    private static let blobRefPlaceholder = "{blob_ref}"

    private let fileManager: any FileManaging
    private let downloader: any BlobDownloader
    private let baseCacheURL: URL?

    init(
        fileManager: any FileManaging = FileManager.default,
        downloader: any BlobDownloader,
        baseCacheURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.downloader = downloader
        self.baseCacheURL = baseCacheURL
    }

    func fetchTopicIfNeeded(
        topic: RemoteConfigResponse.Topic,
        entryId: String,
        topicEntry: RemoteConfigResponse.TopicEntry,
        source: RemoteConfigResponse.BlobSource
    ) async -> BackendError? {
        guard self.isValidBlobRef(topicEntry.blobRef) else {
            Logger.error(Strings.remoteConfig.topic_malformed_blob_ref(topic: topic, entryId: entryId))
            return TopicFetchError.malformedBlobRef.backendError
        }

        // Normalize to lowercase so the cache path and SHA-256 comparison are
        // always consistent regardless of whether the backend sends upper- or
        // lower-case hex (SHA256.hash produces lowercase via %02x).
        let blobRef = topicEntry.blobRef.lowercased()

        guard let targetFile = self.topicFile(topic: topic, blobRef: blobRef) else {
            Logger.error(Strings.remoteConfig.topic_caches_dir_unavailable(topic: topic, entryId: entryId))
            return TopicFetchError.cachesDirectoryUnavailable.backendError
        }

        if self.fileManager.fileExists(atPath: targetFile.path) {
            Logger.verbose(Strings.remoteConfig.topic_cache_hit(topic: topic, entryId: entryId))
            return nil
        }

        let urlString = source.urlFormat.replacingOccurrences(of: Self.blobRefPlaceholder, with: blobRef)
        guard let url = URL(string: urlString) else {
            Logger.error(Strings.remoteConfig.topic_invalid_blob_url(
                topic: topic, entryId: entryId, urlString: urlString
            ))
            return TopicFetchError.invalidBlobURL.backendError
        }

        let error = await self.download(url: url, expectedSHA256: blobRef, targetFile: targetFile)
        if let error {
            Logger.error(Strings.remoteConfig.topic_fetch_error(topic: topic, entryId: entryId, error: error))
        } else {
            Logger.debug(Strings.remoteConfig.topic_fetched(topic: topic, entryId: entryId))
        }
        return error
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TopicFetcher: @unchecked Sendable {}

private enum TopicFetchError {

    case malformedBlobRef
    case cachesDirectoryUnavailable
    case invalidBlobURL
    case sha256Mismatch(expected: String, actual: String)
    case writeFailure(error: Error)

    var backendError: BackendError {
        switch self {
        case .malformedBlobRef:
            return .unexpectedBackendResponse(.remoteConfigMalformedBlobRef)
        case .cachesDirectoryUnavailable:
            return .networkError(.networkError(URLError(.cannotCreateFile)))
        case .invalidBlobURL:
            return .networkError(.networkError(URLError(.badURL)))
        case .sha256Mismatch:
            return .networkError(.networkError(URLError(.cannotDecodeRawData)))
        case .writeFailure(let error):
            return .networkError(.networkError(error))
        }
    }

}

private extension TopicFetcher {

    func topicFile(topic: RemoteConfigResponse.Topic, blobRef: String) -> URL? {
        guard let cachesDir = self.baseCacheURL ?? DirectoryHelper.baseUrl(for: .cache) else { return nil }
        let topicDir = cachesDir
            .appendingPathComponent(Self.topicsRoot)
            .appendingPathComponent(topic.rawValue)

        if !self.fileManager.fileExists(atPath: topicDir.path) {
            try? self.fileManager.createDirectory(at: topicDir, withIntermediateDirectories: true, attributes: nil)
        }

        return topicDir.appendingPathComponent(blobRef)
    }

    func download(url: URL, expectedSHA256: String, targetFile: URL) async -> BackendError? {
        return await withCheckedContinuation { continuation in
            self.downloader.fetchRawData(from: url) { [self] result in
                switch result {
                case .failure(let error):
                    continuation.resume(returning: .networkError(.networkError(error)))

                case .success(let data):
                    let actualSHA256 = SHA256.hash(data: data)
                        .map { String(format: "%02x", $0) }
                        .joined()

                    guard actualSHA256 == expectedSHA256 else {
                        continuation.resume(returning: TopicFetchError.sha256Mismatch(
                            expected: expectedSHA256,
                            actual: actualSHA256
                        ).backendError)
                        return
                    }

                    let parent = targetFile.deletingLastPathComponent()
                    let tempFile = parent.appendingPathComponent("rc_topic_\(UUID().uuidString).tmp")

                    do {
                        defer { try? self.fileManager.removeItem(at: tempFile) }
                        try data.write(to: tempFile, options: .atomic)
                        do {
                            _ = try self.fileManager.replaceItemAt(
                                targetFile, withItemAt: tempFile, backupItemName: nil, options: []
                            )
                        } catch {
                            try? self.fileManager.removeItem(at: targetFile)
                            try self.fileManager.copyItem(at: tempFile, to: targetFile)
                        }
                        continuation.resume(returning: nil)
                    } catch {
                        continuation.resume(returning: TopicFetchError.writeFailure(error: error).backendError)
                    }
                }
            }
        }
    }

    func isValidBlobRef(_ blobRef: String) -> Bool {
        blobRef.range(of: "^[a-fA-F0-9]{64}$", options: .regularExpression) != nil
    }

}
