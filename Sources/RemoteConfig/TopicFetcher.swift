//
//  TopicFetcher.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import CryptoKit
import Foundation

class TopicFetcher {

    private static let topicsRoot = "RevenueCat/topics"
    private static let blobRefPlaceholder = "{blob_ref}"

    private let fileManager: FileManager
    private let urlSession: URLSession

    init(fileManager: FileManager = .default, urlSession: URLSession = .shared) {
        self.fileManager = fileManager
        self.urlSession = urlSession
    }

    func fetchTopicIfNeeded(
        topic: RemoteConfigResponse.Topic,
        entryId: String,
        topicEntry: RemoteConfigResponse.TopicEntry,
        source: RemoteConfigResponse.BlobSource
    ) async -> BackendError? {
        guard self.isValidBlobRef(topicEntry.blobRef) else {
            Logger.error(Strings.remoteConfig.topic_malformed_blob_ref(topic: topic, entryId: entryId))
            return .networkError(.networkError(
                NSError(
                    domain: "com.revenuecat.remoteconfig",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Malformed blob_ref for topic \(topic) (\(entryId))"]
                )
            ))
        }

        guard let targetFile = self.topicFile(topic: topic, blobRef: topicEntry.blobRef) else {
            return .networkError(.networkError(
                NSError(
                    domain: "com.revenuecat.remoteconfig",
                    code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "Could not resolve caches directory"]
                )
            ))
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
            return .networkError(.networkError(
                NSError(
                    domain: "com.revenuecat.remoteconfig",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid blob URL: \(urlString)"]
                )
            ))
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

private extension TopicFetcher {

    func topicFile(topic: RemoteConfigResponse.Topic, blobRef: String) -> URL? {
        guard let cachesDir = DirectoryHelper.baseUrl(for: .cache) else { return nil }
        let topicDir = cachesDir
            .appendingPathComponent(Self.topicsRoot)
            .appendingPathComponent(topic.wireKey)

        if !self.fileManager.fileExists(atPath: topicDir.path) {
            try? self.fileManager.createDirectory(at: topicDir, withIntermediateDirectories: true)
        }

        return topicDir.appendingPathComponent(blobRef)
    }

    func download(url: URL, expectedSHA256: String, targetFile: URL) async -> BackendError? {
        return await withCheckedContinuation { continuation in
            self.urlSession.dataTask(with: url) { [self] data, _, error in
                if let error {
                    continuation.resume(returning: .networkError(.networkError(error)))
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
                    continuation.resume(returning: .networkError(.networkError(
                        NSError(
                            domain: "com.revenuecat.remoteconfig",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey:
                                "SHA-256 mismatch: expected \(expectedSHA256), got \(actualSHA256)"]
                        )
                    )))
                    return
                }

                let parent = targetFile.deletingLastPathComponent()
                let tempFile = parent.appendingPathComponent("rc_topic_\(UUID().uuidString).tmp")

                do {
                    try data.write(to: tempFile, options: .atomic)
                    _ = try? self.fileManager.replaceItemAt(targetFile, withItemAt: tempFile)
                    continuation.resume(returning: nil)
                } catch {
                    try? self.fileManager.removeItem(at: tempFile)
                    continuation.resume(returning: .networkError(.networkError(error)))
                }
            }.resume()
        }
    }

    func isValidBlobRef(_ blobRef: String) -> Bool {
        !blobRef.isEmpty && blobRef.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
    }

}
