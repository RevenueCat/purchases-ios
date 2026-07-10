//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowsConfigProviderTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

/// End-to-end: drives a real `RemoteConfigManager` (the single read front door, via `topic()`/`blobData()`)
/// through `WorkflowsConfigProvider`. Only the backend transport and blob store are faked; everything else
/// (topic resolution, blob-ref reads) exercises the real implementation.
class WorkflowsConfigProviderTests: TestCase {

    private var diskCache: FakeRemoteConfigDiskCache!
    private var blobStore: FakeRemoteConfigBlobStore!
    private var blobFetcher: FakeRemoteConfigBlobFetcher!
    private var manager: RemoteConfigManager!
    private var provider: WorkflowsConfigProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.diskCache = FakeRemoteConfigDiskCache()
        self.blobStore = FakeRemoteConfigBlobStore()
        self.blobFetcher = FakeRemoteConfigBlobFetcher(blobStore: self.blobStore)
        self.manager = RemoteConfigManager(
            remoteConfigAPI: FakeRemoteConfigAPI(),
            diskCache: self.diskCache,
            blobStore: self.blobStore,
            blobFetcher: self.blobFetcher,
            currentUserProvider: FakeCurrentUserProvider()
        )
        self.provider = WorkflowsConfigProvider(manager: self.manager)
    }

    func testResolvesAWorkflowAlreadyCommittedToTheWorkflowsTopic() async throws {
        let workflowJSON = try Self.workflowJSON(id: "wf-1")
        self.commit(
            workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: ["offeringIdentifier": "premium_annual"])],
            uiConfig: [
                "app": .init(blobRef: "app-ref", content: [:]),
                "localizations": .init(blobRef: "loc-ref", content: [:]),
                "variable_config": .init(blobRef: "variable-config-ref", content: [:]),
                "custom_variables": .init(blobRef: "custom-variables-ref", content: [:])
            ],
            blobs: [
                "wf-1-ref": workflowJSON,
                "app-ref": Data(#"{"colors": {}, "fonts": {}}"#.utf8),
                "loc-ref": Data(#"{}"#.utf8),
                "variable-config-ref": Data(
                    #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#.utf8
                ),
                "custom-variables-ref": Data(#"{}"#.utf8)
            ]
        )

        let workflowId = await self.provider.workflowId(forOfferingId: "premium_annual")
        expect(workflowId) == "wf-1"

        let result = await self.provider.getWorkflow(workflowId: "wf-1")
        let workflowResult = try XCTUnwrap(result.value)
        expect(workflowResult.workflow.id) == "wf-1"
        // enrolled_variants is intentionally out of scope for the config-topic path.
        expect(workflowResult.enrolledVariants).to(beNil())
    }

    func testFailsWithUiConfigUnavailableWhenTheWorkflowResolvesButUiConfigIsUnavailable() async throws {
        // A workflow is never rendered without `ui_config`: if it can't be assembled, the whole result
        // fails, matching Android's PaywallViewModel failing the render when its concurrent fetch fails.
        let workflowJSON = try Self.workflowJSON(id: "wf-1")
        self.commit(
            workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: [:])],
            blobs: ["wf-1-ref": workflowJSON]
        )

        let result = await self.provider.getWorkflow(workflowId: "wf-1")

        expect(result.error) == .uiConfigUnavailable
    }

    func testAssemblesUiConfigFromItsOwnTopicWhenResolvingAWorkflow() async throws {
        let workflowJSON = try Self.workflowJSON(id: "wf-1")
        self.commit(
            workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: [:])],
            uiConfig: [
                "app": .init(blobRef: "app-ref", content: [:]),
                "localizations": .init(blobRef: "loc-ref", content: [:]),
                "variable_config": .init(blobRef: "variable-config-ref", content: [:]),
                "custom_variables": .init(blobRef: "custom-variables-ref", content: [:])
            ],
            blobs: [
                "wf-1-ref": workflowJSON,
                "app-ref": Data(#"{"colors": {}, "fonts": {}}"#.utf8),
                "loc-ref": Data(#"{"en_US": {"day": "Day"}}"#.utf8),
                "variable-config-ref": Data(
                    #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#.utf8
                ),
                "custom-variables-ref": Data(#"{}"#.utf8)
            ]
        )

        let result = await self.provider.getWorkflow(workflowId: "wf-1")
        let workflowResult = try XCTUnwrap(result.value)

#if !os(tvOS) // For Paywalls V2
        XCTAssertEqual(workflowResult.uiConfig.localizations["en_US"]?["day"], "Day")
#endif
    }

    func testPreservesWorkflowMetadataWhenAssemblingUiConfig() async throws {
        // Regression: resolving ui_config must not rebuild the workflow through the public
        // initializer, which always resets `metadata` to nil.
        let workflowJSON = try Self.workflowJSON(id: "wf-1", metadataJSON: #""metadata": { "source": "cdn" }"#)
        self.commit(
            workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: [:])],
            uiConfig: [
                "app": .init(blobRef: "app-ref", content: [:]),
                "localizations": .init(blobRef: "loc-ref", content: [:]),
                "variable_config": .init(blobRef: "variable-config-ref", content: [:]),
                "custom_variables": .init(blobRef: "custom-variables-ref", content: [:])
            ],
            blobs: [
                "wf-1-ref": workflowJSON,
                "app-ref": Data(#"{"colors": {}, "fonts": {}}"#.utf8),
                "loc-ref": Data(#"{}"#.utf8),
                "variable-config-ref": Data(
                    #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#.utf8
                ),
                "custom-variables-ref": Data(#"{}"#.utf8)
            ]
        )

        let result = await self.provider.getWorkflow(workflowId: "wf-1")
        let workflowResult = try XCTUnwrap(result.value)

        expect(workflowResult.workflow.metadata?["source"]) == .string("cdn")
    }

    func testFailsWithNotFoundForAnUnknownWorkflowId() async {
        self.commit(workflows: [:])

        let result = await self.provider.getWorkflow(workflowId: "missing")

        expect(result.error) == .notFound
    }

    func testFailsWithDecodingFailedForAMalformedWorkflowBody() async {
        self.commit(
            workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: [:])],
            blobs: ["wf-1-ref": Data(#"{ "not": "a workflow" }"#.utf8)]
        )

        let result = await self.provider.getWorkflow(workflowId: "wf-1")

        guard case .failure(.decodingFailed) = result else {
            fail("Expected a decodingFailed failure, got \(result)")
            return
        }
    }

    func testDoesNotFetchUiConfigWhenTheWorkflowBodyIsMissing() async {
        // Regression: getWorkflow used to start the ui_config fetch concurrently with the workflow-body
        // read, which meant a miss still paid for ui_config's blob downloads before returning. It's
        // sequential now specifically so a miss never touches ui_config at all.
        self.commit(
            workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: [:])],
            uiConfig: [
                "app": .init(blobRef: "app-ref", content: [:]),
                "localizations": .init(blobRef: "loc-ref", content: [:])
            ],
            blobs: [
                "app-ref": Data(#"{"colors": {}, "fonts": {}}"#.utf8),
                "loc-ref": Data(#"{}"#.utf8)
            ]
        )

        let result = await self.provider.getWorkflow(workflowId: "wf-1")

        expect(result.error) == .notFound // "wf-1-ref" was never stored, so the body read misses.
        // Only the workflow body itself was attempted; ui_config's parts were never touched.
        expect(self.blobFetcher.invokedEnsureDownloadedRefs) == ["wf-1-ref"]
    }

    func testReturnsNilOfferingMappingWhenNoItemMatches() async {
        self.commit(workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: ["offeringIdentifier": "other"])])

        let workflowId = await self.provider.workflowId(forOfferingId: "premium_annual")

        expect(workflowId).to(beNil())
    }

    func testResolvesOfferingIdFromARealWireDecodedTopic() async throws {
        // Decodes literal snake_case JSON through RemoteConfiguration.Topics' real Codable conformance,
        // proving `offering_identifier` survives into `content["offeringIdentifier"]` end to end,
        // rather than seeding the mock topic with an already-camelCased key.
        let topicsJSON = """
        {
          "workflows": {
            "wf-1": { "blob_ref": "wf-1-ref", "offering_identifier": "premium_annual" }
          }
        }
        """
        let topics = try JSONDecoder.default.decode(
            RemoteConfiguration.Topics.self,
            jsonData: try XCTUnwrap(topicsJSON.data(using: .utf8))
        )
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "test-manifest",
            activeTopics: ["workflows"],
            topics: topics
        )

        let workflowId = await self.provider.workflowId(forOfferingId: "premium_annual")

        expect(workflowId) == "wf-1"
    }

    func testResolvesAndWarnsOnDuplicateOfferingId() async throws {
        let logger = TestLogHandler(testIdentifier: self.name)
        let topicsJSON = """
        {
          "workflows": {
            "wf-a": { "blob_ref": "a-ref", "offering_identifier": "shared" },
            "wf-b": { "blob_ref": "b-ref", "offering_identifier": "shared" }
          }
        }
        """
        let topics = try JSONDecoder.default.decode(
            RemoteConfiguration.Topics.self,
            jsonData: try XCTUnwrap(topicsJSON.data(using: .utf8))
        )
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "test-manifest",
            activeTopics: ["workflows"],
            topics: topics
        )

        let result = await self.provider.workflowId(forOfferingId: "shared")
        let workflowId = try XCTUnwrap(result)

        // Matches Android's last-wins duplicate handling, using stable workflow-id ordering on iOS.
        expect(workflowId) == "wf-b"
        logger.verifyMessageWasLogged("Duplicate offeringId in workflows response: shared",
                                      level: .warn,
                                      expectedCount: 1)
    }

    func testOfferingIdMapReflectsATopicChangeInsteadOfServingAStaleCachedMap() async throws {
        // Regression: workflowId(forOfferingId:) caches its offeringId -> workflowId map keyed by the
        // topic snapshot it was built from, to avoid rescanning content on every call. This proves a
        // changed topic (e.g. a resync remapping an offering to a new workflow) invalidates that cache
        // instead of serving the map built from the previous snapshot.
        self.commit(workflows: ["wf-1": .init(blobRef: "wf-1-ref", content: ["offeringIdentifier": "premium"])])
        let firstWorkflowId = await self.provider.workflowId(forOfferingId: "premium")
        expect(firstWorkflowId) == "wf-1"

        self.commit(workflows: ["wf-2": .init(blobRef: "wf-2-ref", content: ["offeringIdentifier": "premium"])])
        let secondWorkflowId = await self.provider.workflowId(forOfferingId: "premium")
        expect(secondWorkflowId) == "wf-2"
    }

    // MARK: - Helpers

    private func commit(
        workflows: [String: RemoteConfiguration.ConfigItem] = [:],
        uiConfig: [String: RemoteConfiguration.ConfigItem] = [:],
        blobs: [String: Data] = [:]
    ) {
        var entries: [String: RemoteConfiguration.ConfigTopic] = [:]
        if !workflows.isEmpty { entries[RemoteConfigTopic.workflows.wireName] = workflows }
        if !uiConfig.isEmpty { entries[RemoteConfigTopic.uiConfig.wireName] = uiConfig }

        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "test-manifest",
            activeTopics: Array(entries.keys),
            topics: .init(entries: entries)
        )
        self.blobStore.stubbedData = blobs
    }

    private static func workflowJSON(id: String, metadataJSON: String? = nil) throws -> Data {
        let metadataJSON = metadataJSON.map { ",\n          \($0)" } ?? ""
        let json = """
        {
          "id": "\(id)",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" }
          },
          "screens": {
            "screen_1": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": {
                    "type": "stack",
                    "components": [],
                    "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                    "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                    "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
                  },
                  "background": {
                    "type": "color",
                    "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
                  }
                }
              },
              "offering_identifier": "default"
            }
          }\(metadataJSON)
        }
        """
        return try XCTUnwrap(json.data(using: .utf8))
    }

}

// MARK: - Fakes

private final class FakeRemoteConfigAPI: RemoteConfigAPIType {

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFetchResult>
    ) {
        // `blobData(for:itemKey:)` triggers a refresh-and-wait whenever an item is legitimately absent
        // (e.g. an optional `ui_config` part these tests never committed), so this must always settle
        // rather than hang: report a "204 Not Modified" result, since the state is already pre-committed.
        // `RemoteConfigManager` calls this from inside a lock and documents that it assumes the
        // completion is never invoked synchronously, so this must dispatch asynchronously.
        DispatchQueue.global().async {
            let result = RemoteConfigFetchResult(response: VerifiedHTTPResponse(
                httpStatusCode: .noContent,
                responseHeaders: [:],
                body: nil,
                verificationResult: .verified,
                isLoadShedderResponse: false,
                isFallbackUrlResponse: false
            ))
            completion(.success(result))
        }
    }

    func getRemoteConfigFallback(
        domain: String,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFallbackFetchResult>
    ) {
        DispatchQueue.global().async {
            completion(.failure(.networkError(.unexpectedResponse(nil))))
        }
    }

}

private final class FakeRemoteConfigDiskCache: RemoteConfigDiskCacheType {

    private let lock = Lock()
    private var _stubbedRead: PersistedRemoteConfiguration?
    var stubbedRead: PersistedRemoteConfiguration? {
        get {
            return self.lock.perform {
                self._stubbedRead
            }
        }
        set {
            self.lock.perform {
                self._stubbedRead = newValue
            }
        }
    }

    func read() -> PersistedRemoteConfiguration? {
        return self.lock.perform {
            self._stubbedRead
        }
    }

    func topic(_ topic: RemoteConfigTopic) -> RemoteConfiguration.ConfigTopic? {
        return self.lock.perform {
            self._stubbedRead?.topics.entries[topic.wireName]
        }
    }

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool {
        self.lock.perform {
            self._stubbedRead = configuration
        }
        return true
    }

    func clear() {
        self.lock.perform {
            self._stubbedRead = nil
        }
    }

}

private final class FakeRemoteConfigBlobStore: RemoteConfigBlobStoreType {

    private let lock = Lock()
    private var _stubbedData: [String: Data] = [:]
    var stubbedData: [String: Data] {
        get {
            return self.lock.perform {
                self._stubbedData
            }
        }
        set {
            self.lock.perform {
                self._stubbedData = newValue
            }
        }
    }

    func contains(ref: String) -> Bool {
        return self.lock.perform {
            self._stubbedData[ref] != nil
        }
    }

    func read(ref: String) -> Data? {
        return self.lock.perform {
            self._stubbedData[ref]
        }
    }

    @discardableResult
    func write(ref: String, bytes: UnsafeRawBufferPointer) -> Bool {
        var data = Data()
        data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
        self.lock.perform {
            self._stubbedData[ref] = data
        }
        return true
    }

    func cachedRefs() -> Set<String> {
        return self.lock.perform {
            Set(self._stubbedData.keys)
        }
    }

    func retainOnly(_ refs: Set<String>) {
        self.lock.perform {
            self._stubbedData = self._stubbedData.filter { refs.contains($0.key) }
        }
    }

    func clear() {
        self.lock.perform {
            self._stubbedData = [:]
        }
    }

}

private final class FakeRemoteConfigBlobFetcher: RemoteConfigBlobFetcherType {

    private let lock = Lock()
    private let blobStore: FakeRemoteConfigBlobStore
    private var _invokedEnsureDownloadedRefs: [String] = []

    var invokedEnsureDownloadedRefs: [String] {
        return self.lock.perform {
            self._invokedEnsureDownloadedRefs
        }
    }

    init(blobStore: FakeRemoteConfigBlobStore) {
        self.blobStore = blobStore
    }

    func ensureDownloaded(ref: String) async -> Bool {
        self.lock.perform {
            self._invokedEnsureDownloadedRefs.append(ref)
        }
        // The store is pre-populated in these tests, so "downloading" is just confirming it's there.
        return self.blobStore.contains(ref: ref)
    }

    func ensureAllDownloaded(refs: [String]) async -> Bool {
        return refs.allSatisfy { self.blobStore.contains(ref: $0) }
    }

    func prefetch(refs: [String]) {}

}

private final class FakeCurrentUserProvider: CurrentUserProvider {

    var currentAppUserID: String { return "test-user" }
    var currentUserIsAnonymous: Bool { return false }

}
