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
    func removeItem(at url: URL) throws
}

extension FileManager: FileManaging {}

class TopicFetcher {

    private static let topicsRoot = "RevenueCat/topics"
    private static let blobRefPlaceholder = "{blob_ref}"

    private let fileManager: any FileManaging
    private let urlSession: URLSession
    private let baseCacheURL: URL?

    init(
        fileManager: any FileManaging = FileManager.default,
        urlSession: URLSession = .shared,
        baseCacheURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.urlSession = urlSession
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

        guard let targetFile = self.topicFile(topic: topic, blobRef: topicEntry.blobRef) else {
            return TopicFetchError.cachesDirectoryUnavailable.backendError
        }

        if self.fileManager.fileExists(atPath: targetFile.path) {
            Logger.verbose(Strings.remoteConfig.topic_cache_hit(topic: topic, entryId: entryId))
            return nil
        }

        let urlString = source.urlFormat.replacingOccurrences(
            of: Self.blobRefPlaceholder,
            with: topicEntry.blobRef
        )
        guard let url = URL(string: urlString) else {
            return TopicFetchError.invalidBlobURL(urlString: urlString).backendError
        }

        let error = await self.download(url: url, expectedSHA256: topicEntry.blobRef, targetFile: targetFile)
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
    case invalidBlobURL(urlString: String)
    case unexpectedHTTPStatus(statusCode: Int)
    case sha256Mismatch(expected: String, actual: String)
    case writeFailure(error: Error)

    var backendError: BackendError {
        switch self {
        case .malformedBlobRef:
            return .unexpectedBackendResponse(.remoteConfigMalformedBlobRef)
        case .cachesDirectoryUnavailable:
            return Self.make(code: -4, "Could not resolve caches directory")
        case .invalidBlobURL(let urlString):
            return Self.make(code: -3, "Invalid blob URL: \(urlString)")
        case .unexpectedHTTPStatus(let statusCode):
            return Self.make(code: -5, "Unexpected HTTP status: \(statusCode)")
        case .sha256Mismatch(let expected, let actual):
            return Self.make(code: -2, "SHA-256 mismatch: expected \(expected), got \(actual)")
        case .writeFailure(let error):
            return .networkError(.networkError(error))
        }
    }

    private static func make(code: Int, _ message: String) -> BackendError {
        .networkError(.networkError(
            NSError(
                domain: "com.revenuecat.remoteconfig",
                code: code,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        ))
    }

}

private extension TopicFetcher {

    func topicFile(topic: RemoteConfigResponse.Topic, blobRef: String) -> URL? {
        guard let cachesDir = self.baseCacheURL ?? DirectoryHelper.baseUrl(for: .cache) else { return nil }
        let topicDir = cachesDir
            .appendingPathComponent(Self.topicsRoot)
            .appendingPathComponent(topic.wireKey)

        if !self.fileManager.fileExists(atPath: topicDir.path) {
            try? self.fileManager.createDirectory(at: topicDir, withIntermediateDirectories: true, attributes: nil)
        }

        return topicDir.appendingPathComponent(blobRef)
    }

    func download(url: URL, expectedSHA256: String, targetFile: URL) async -> BackendError? {
        return await withCheckedContinuation { continuation in
            self.urlSession.dataTask(with: url) { [self] data, response, error in
                if let error {
                    continuation.resume(returning: .networkError(.networkError(error)))
                    return
                }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard statusCode == 200 else {
                    let error = TopicFetchError.unexpectedHTTPStatus(statusCode: statusCode).backendError
                    continuation.resume(returning: error)
                    return
                }

                guard let data else {
                    continuation.resume(returning: .networkError(.unexpectedResponse(nil)))
                    return
                }

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
                    try data.write(to: tempFile, options: .atomic)
                    _ = try self.fileManager.replaceItemAt(
                        targetFile, withItemAt: tempFile, backupItemName: nil, options: []
                    )
                    continuation.resume(returning: nil)
                } catch {
                    try? self.fileManager.removeItem(at: tempFile)
                    continuation.resume(returning: TopicFetchError.writeFailure(error: error).backendError)
                }
            }.resume()
        }
    }

    func isValidBlobRef(_ blobRef: String) -> Bool {
        !blobRef.isEmpty && blobRef.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }

}
