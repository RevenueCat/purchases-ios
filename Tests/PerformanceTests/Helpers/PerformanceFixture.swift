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
        func store(_ body: Any, topic: RemoteConfigTopic, key: String) throws {
            let data = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
            let ref = Data(SHA256.hash(data: data).prefix(24)).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            XCTAssertTrue(data.withUnsafeBytes { blobStore.write(ref: ref, bytes: $0) })
            topics[topic.wireName, default: [:]][key] = .init(
                blobRef: ref,
                prefetch: true,
                content: topic == .workflows ? ["offering_identifier": .string(key)] : [:]
            )
        }

        let screen = try self.json(named: "reported_tabs")
        for index in 0..<12 {
            let identifier = "workflow-\(index)"
            try store(self.workflow(id: identifier, screen: screen), topic: .workflows, key: identifier)
        }
        var uiConfig = try self.json(named: "UIConfig")
        uiConfig["custom_variables"] = [:] as [String: Any]
        for (key, value) in uiConfig {
            try store(value, topic: .uiConfig, key: key)
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

    private static func workflow(id: String, screen: [String: Any]) -> [String: Any] {
        let screens = Dictionary(uniqueKeysWithValues: (0..<8).map { ("screen-\($0)", screen) })
        let steps = Dictionary(uniqueKeysWithValues: (0..<8).map {
            ("step-\($0)", ["id": "step-\($0)", "type": "screen", "screen_id": "screen-\($0)"])
        })
        return ["id": id, "display_name": id, "initial_step_id": "step-0", "steps": steps, "screens": screens]
    }

    private static func json(named name: String) throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle(for: WorkflowPrewarmingMemoryTests.self)
            .url(forResource: name, withExtension: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
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
