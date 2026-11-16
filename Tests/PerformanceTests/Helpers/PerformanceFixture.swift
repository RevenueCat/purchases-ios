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

struct MultipleWorkflowWebBundleURLFixture: Decodable {

    let sourceFixture: String
    let workflowCount: Int

}

enum PerformanceFixture {

    static func makeManager(
        rootURL: URL,
        sourceFixture: String,
        workflowCount: Int
    ) throws -> RemoteConfigManager {
        precondition(workflowCount > 0)
        let diskCache = RemoteConfigDiskCache(cache: SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: "performance",
            directoryType: .applicationSupport(overrideURL: rootURL)
        ))
        let blobStore = RemoteConfigBlobStore(directoryURL: rootURL.appendingPathComponent("blobs"))
        let store = PerformanceFixtureStore(blobStore: blobStore)
        let url = try XCTUnwrap(Bundle(for: WorkflowPrewarmingMemoryTests.self)
            .url(forResource: sourceFixture, withExtension: "json"))
        let data = try Data(contentsOf: url)
        let workflow = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        try store.storeWorkflows(data: data, workflow: workflow, count: workflowCount)
        let uiConfig = try XCTUnwrap(workflow["ui_config"] as? [String: Any])
        for (key, value) in uiConfig {
            store.store(
                try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
                topic: .uiConfig,
                key: key
            )
        }
        XCTAssertTrue(diskCache.write(.init(
            manifest: "performance-fixture",
            activeTopics: store.topics.keys.sorted(),
            topics: .init(entries: store.topics)
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

    static func multipleWorkflowWebBundleURLFixture() throws -> MultipleWorkflowWebBundleURLFixture {
        let url = try XCTUnwrap(Bundle(for: WorkflowPrewarmingMemoryTests.self)
            .url(forResource: "web-bundle-url-publishing-multiple-workflows", withExtension: "json"))
        return try JSONDecoder.default.decode(
            MultipleWorkflowWebBundleURLFixture.self,
            from: Data(contentsOf: url)
        )
    }

}

private final class PerformanceFixtureStore {

    let blobStore: RemoteConfigBlobStore
    var topics: [String: RemoteConfiguration.ConfigTopic] = [:]

    init(blobStore: RemoteConfigBlobStore) {
        self.blobStore = blobStore
    }

    /// Uses deterministic copies of the approved published workflow to isolate the cost of retaining several
    /// decoded graphs without adding a large collection of otherwise identical fixture files.
    func storeWorkflows(data: Data, workflow: [String: Any], count: Int) throws {
        if count == 1 {
            self.store(
                data,
                topic: .workflows,
                key: try XCTUnwrap(workflow["id"] as? String),
                offeringIdentifier: "[performance-benchmark-1]"
            )
            return
        }

        for index in 0..<count {
            let workflowIdentifier = String(format: "wff%016x", index + 1)
            let offeringIdentifier = String(format: "[performance-retention-%02d]", index + 1)
            var workflowCopy = workflow
            workflowCopy["id"] = workflowIdentifier
            workflowCopy["display_name"] = offeringIdentifier
            self.store(
                try JSONSerialization.data(withJSONObject: workflowCopy, options: [.sortedKeys]),
                topic: .workflows,
                key: workflowIdentifier,
                offeringIdentifier: offeringIdentifier
            )
        }
    }

    func store(
        _ data: Data,
        topic: RemoteConfigTopic,
        key: String,
        offeringIdentifier: String? = nil
    ) {
        let ref = Data(SHA256.hash(data: data).prefix(24)).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        XCTAssertTrue(data.withUnsafeBytes { self.blobStore.write(ref: ref, bytes: $0) })
        self.topics[topic.wireName, default: [:]][key] = .init(
            blobRef: ref,
            prefetch: true,
            content: offeringIdentifier.map { ["offering_identifier": .string($0)] } ?? [:]
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
