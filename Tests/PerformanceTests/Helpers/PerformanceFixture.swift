//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PerformanceFixture.swift
//

import CryptoKit
import Foundation
@testable import RevenueCat
import XCTest

enum PerformanceFixture {

    static func makeManager(rootURL: URL) throws -> RemoteConfigManager {
        let diskCache = RemoteConfigDiskCache(cache: SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: "performance",
            directoryType: .applicationSupport(overrideURL: rootURL)
        ))
        let blobStore = RemoteConfigBlobStore(directoryURL: rootURL.appendingPathComponent("blobs"))
        var topics: [String: RemoteConfiguration.ConfigTopic] = [:]
        func store(_ data: Data, topic: RemoteConfigTopic, key: String) {
            let ref = Data(SHA256.hash(data: data).prefix(24)).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            XCTAssertTrue(data.withUnsafeBytes { blobStore.write(ref: ref, bytes: $0) })
            topics[topic.wireName, default: [:]][key] = .init(
                blobRef: ref,
                prefetch: true,
                content: topic == .workflows ? ["offering_identifier": .string("[performance-benchmark-1]")] : [:]
            )
        }

        let url = try XCTUnwrap(Bundle(for: WorkflowPrewarmingMemoryTests.self)
            .url(forResource: "performance-benchmark-1-revision-24", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let workflow = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let identifier = try XCTUnwrap(workflow["id"] as? String)
        store(data, topic: .workflows, key: identifier)
        let uiConfig = try XCTUnwrap(workflow["ui_config"] as? [String: Any])
        for (key, value) in uiConfig {
            store(try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]), topic: .uiConfig, key: key)
        }
        XCTAssertTrue(diskCache.write(.init(
            manifest: "performance-fixture",
            activeTopics: topics.keys.sorted(),
            topics: .init(entries: topics)
        )))
        let backend = OfflinePerformanceBackend()
        return RemoteConfigManager(
            remoteConfigAPI: backend,
            diskCache: diskCache,
            blobStore: blobStore,
            blobFetcher: RemoteConfigBlobFetcher(
                blobStore: blobStore,
                sourceProvider: RemoteConfigSourceProvider(topicStore: diskCache),
                downloader: backend
            ),
            currentUserProvider: backend
        )
    }

}

private final class OfflinePerformanceBackend: RemoteConfigAPIType,
                                               RemoteConfigBlobDownloaderType,
                                               CurrentUserProvider {
    var currentAppUserID: String { "workflow-memory-benchmark" }
    var currentUserIsAnonymous: Bool { true }

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping RemoteConfigResponseHandler
    ) {
        XCTFail("The performance fixture must not request remote config.")
        DispatchQueue.global().async { completion(.failure(.networkError(.unexpectedResponse(nil)))) }
    }

    func getRemoteConfigFallback(
        domain: String,
        isAppBackgrounded: Bool,
        completion: @escaping FallbackResponseHandler
    ) {
        XCTFail("The performance fixture must not request fallback config.")
        DispatchQueue.global().async { completion(.failure(.networkError(.unexpectedResponse(nil)))) }
    }

    func data(from url: URL) async throws -> Data {
        XCTFail("The performance fixture must not download blobs.")
        throw URLError(.notConnectedToInternet)
    }
}
