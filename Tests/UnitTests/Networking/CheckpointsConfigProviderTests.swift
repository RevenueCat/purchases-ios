//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointsConfigProviderTests.swift
//
//  Created by Facundo Menzella.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

/// End-to-end: drives a real `RemoteConfigManager` (the single read front door, via `blobData()`) through
/// `CheckpointsConfigProvider`. Only the backend transport and blob store are faked.
class CheckpointsConfigProviderTests: TestCase {

    private var diskCache: FakeCheckpointsDiskCache!
    private var blobStore: FakeCheckpointsBlobStore!
    private var manager: RemoteConfigManager!
    private var provider: CheckpointsConfigProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.diskCache = FakeCheckpointsDiskCache()
        self.blobStore = FakeCheckpointsBlobStore()
        self.manager = RemoteConfigManager(
            remoteConfigAPI: FakeCheckpointsRemoteConfigAPI(),
            diskCache: self.diskCache,
            blobStore: self.blobStore,
            blobFetcher: FakeCheckpointsBlobFetcher(blobStore: self.blobStore),
            currentUserProvider: FakeCheckpointsCurrentUserProvider()
        )
        self.provider = CheckpointsConfigProvider(manager: self.manager)
    }

    func testResolvesACheckpointFromItsPayload() async throws {
        self.commit(rules: ["onboarding": ["wf-a"]], ids: ["onboarding": "checkpoint-abc"])

        let ruleSetResult = await self.provider.getCheckpoint("onboarding")

        let ruleSet = try XCTUnwrap(ruleSetResult)

        expect(ruleSet.identifier) == "onboarding"
        expect(ruleSet.id) == "checkpoint-abc"
        expect(ruleSet.rules.onlyElement?.workflowId) == "wf-a"
    }

    func testKeepsRulesInServedOrder() async throws {
        self.commit(rules: ["onboarding": ["wf-c", "wf-a", "wf-b"]])

        let ruleSetResult = await self.provider.getCheckpoint("onboarding")

        let ruleSet = try XCTUnwrap(ruleSetResult)

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-c", "wf-a", "wf-b"]
    }

    func testResolvesEachCheckpointIndependently() async throws {
        self.commit(rules: ["onboarding": ["wf-a"], "paywall_close": ["wf-exit"]])

        let onboardingResult = await self.provider.getCheckpoint("onboarding")
        let paywallCloseResult = await self.provider.getCheckpoint("paywall_close")

        let onboarding = try XCTUnwrap(onboardingResult)
        let paywallClose = try XCTUnwrap(paywallCloseResult)

        expect(onboarding.rules.onlyElement?.workflowId) == "wf-a"
        expect(paywallClose.rules.onlyElement?.workflowId) == "wf-exit"
    }

    func testReturnsNilForACheckpointThatHasNoItem() async {
        self.commit(rules: ["onboarding": ["wf-a"]])

        let ruleSet = await self.provider.getCheckpoint("never_registered")

        expect(ruleSet).to(beNil())
    }

    func testReturnsNilWhenTheTopicIsAbsent() async {
        self.commit(rules: [:])

        let ruleSet = await self.provider.getCheckpoint("onboarding")

        expect(ruleSet).to(beNil())
    }

    func testReturnsNilWhenThePayloadIsMissing() async {
        self.commit(checkpoints: ["onboarding": .init(blobRef: "missing-ref", prefetch: true)])

        let ruleSet = await self.provider.getCheckpoint("onboarding")

        expect(ruleSet).to(beNil())
    }

    func testReturnsNilWhenThePayloadIsntJSON() async {
        self.commit(
            checkpoints: ["onboarding": .init(blobRef: "onboarding-ref", prefetch: true)],
            blobs: ["onboarding-ref": Data("not-json".utf8)]
        )

        let ruleSet = await self.provider.getCheckpoint("onboarding")

        expect(ruleSet).to(beNil())
    }

    /// Rules live in the item's payload, not its metadata, so an item without a `blob_ref` has nothing to read.
    func testReturnsNilForAnItemWithoutABlobRef() async {
        self.commit(checkpoints: [
            "onboarding": .init(content: ["rules": .array([
                .object(["workflow_id": .string("wf-metadata")])
            ])])
        ])

        let ruleSet = await self.provider.getCheckpoint("onboarding")

        expect(ruleSet).to(beNil())
    }

    /// A checkpoint whose payload carries no rules is still resolvable, so a caller can tell it apart from
    /// an unconfigured one.
    func testResolvesACheckpointWhosePayloadHasNoRules() async throws {
        self.commit(
            checkpoints: ["onboarding": .init(blobRef: "onboarding-ref", prefetch: true)],
            blobs: ["onboarding-ref": Data(#"{ "id": "checkpoint-abc" }"#.utf8)]
        )

        let ruleSetResult = await self.provider.getCheckpoint("onboarding")

        let ruleSet = try XCTUnwrap(ruleSetResult)

        expect(ruleSet.id) == "checkpoint-abc"
        expect(ruleSet.rules).to(beEmpty())
    }

    /// `blobData` re-reads through the manager every time, so a config replacement is picked up without the
    /// provider holding any state of its own.
    func testPicksUpANewPayloadAfterTheConfigIsReplaced() async throws {
        self.commit(rules: ["onboarding": ["wf-a"]])
        let beforeResult = await self.provider.getCheckpoint("onboarding")

        let before = try XCTUnwrap(beforeResult)
        expect(before.rules.onlyElement?.workflowId) == "wf-a"

        self.manager.clearCache(forAppUserID: "someone-else")
        self.commit(rules: ["onboarding": ["wf-b"]])

        let afterResult = await self.provider.getCheckpoint("onboarding")

        let after = try XCTUnwrap(afterResult)
        expect(after.rules.onlyElement?.workflowId) == "wf-b"
    }

    // MARK: - Helpers

    /// Commits one blob-backed item per checkpoint, each payload carrying one rule per workflow id. This is
    /// the shape the topic is expected to arrive in, so most tests can stay a single line.
    private func commit(rules: [String: [String]], ids: [String: String] = [:]) {
        var items: [String: RemoteConfiguration.ConfigItem] = [:]
        var blobs: [String: Data] = [:]

        for (identifier, workflowIds) in rules {
            // Vary the ref with the payload, the way a content-addressed ref would.
            let ref = "\(identifier)-\(workflowIds.joined(separator: "-"))-ref"
            items[identifier] = .init(blobRef: ref, prefetch: true)
            blobs[ref] = Self.payload(id: ids[identifier], workflowIds: workflowIds)
        }

        self.commit(checkpoints: items, blobs: blobs)
    }

    private func commit(
        checkpoints: [String: RemoteConfiguration.ConfigItem],
        blobs: [String: Data] = [:]
    ) {
        var entries: [String: RemoteConfiguration.ConfigTopic] = [:]
        if !checkpoints.isEmpty {
            entries[RemoteConfigTopic.checkpoints.wireName] = checkpoints
        }

        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "test-manifest",
            activeTopics: Array(entries.keys),
            topics: .init(entries: entries)
        )
        self.blobStore.stubbedData = blobs
    }

    private static func payload(id: String? = nil, workflowIds: [String]) -> Data {
        let rules = workflowIds.map { #"{ "workflow_id": "\#($0)" }"# }.joined(separator: ", ")
        let idField = id.map { #""id": "\#($0)", "# } ?? ""
        return Data(#"{ \#(idField)"rules": [\#(rules)] }"#.utf8)
    }

}

// MARK: - Fakes

private final class FakeCheckpointsRemoteConfigAPI: RemoteConfigAPIType {

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFetchResult>
    ) {
        // `blobData(for:itemKey:)` triggers a refresh-and-wait whenever an item is absent, so this must
        // always settle rather than hang: report a "204 Not Modified", since state is already pre-committed.
        // `RemoteConfigManager` calls this from inside a lock and documents that it assumes the completion is
        // never invoked synchronously, so this must dispatch asynchronously.
        DispatchQueue.global().async {
            completion(.success(RemoteConfigFetchResult(response: VerifiedHTTPResponse(
                httpStatusCode: .noContent,
                responseHeaders: [:],
                body: nil,
                verificationResult: .verified,
                isLoadShedderResponse: false,
                isFallbackUrlResponse: false
            ))))
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

private final class FakeCheckpointsDiskCache: RemoteConfigDiskCacheType {

    private let lock = Lock()
    private var _stubbedRead: PersistedRemoteConfiguration?
    var stubbedRead: PersistedRemoteConfiguration? {
        get { return self.lock.perform { self._stubbedRead } }
        set { self.lock.perform { self._stubbedRead = newValue } }
    }

    func read() -> PersistedRemoteConfiguration? {
        return self.lock.perform { self._stubbedRead }
    }

    func topic(_ topic: RemoteConfigTopic) -> RemoteConfiguration.ConfigTopic? {
        return self.lock.perform { self._stubbedRead?.topics.entries[topic.wireName] }
    }

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool {
        self.lock.perform { self._stubbedRead = configuration }
        return true
    }

    func clear() {
        self.lock.perform { self._stubbedRead = nil }
    }

}

private final class FakeCheckpointsBlobStore: RemoteConfigBlobStoreType {

    private let lock = Lock()
    private var _stubbedData: [String: Data] = [:]
    var stubbedData: [String: Data] {
        get { return self.lock.perform { self._stubbedData } }
        set { self.lock.perform { self._stubbedData = newValue } }
    }

    func contains(ref: String) -> Bool {
        return self.lock.perform { self._stubbedData[ref] != nil }
    }

    func read(ref: String) -> Data? {
        return self.lock.perform { self._stubbedData[ref] }
    }

    @discardableResult
    func write(ref: String, bytes: UnsafeRawBufferPointer) -> Bool {
        var data = Data()
        data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
        self.lock.perform { self._stubbedData[ref] = data }
        return true
    }

    func cachedRefs() -> Set<String> {
        return self.lock.perform { Set(self._stubbedData.keys) }
    }

    func retainOnly(_ refs: Set<String>) {
        self.lock.perform { self._stubbedData = self._stubbedData.filter { refs.contains($0.key) } }
    }

    func clear() {
        self.lock.perform { self._stubbedData = [:] }
    }

}

private final class FakeCheckpointsBlobFetcher: RemoteConfigBlobFetcherType {

    private let blobStore: FakeCheckpointsBlobStore

    init(blobStore: FakeCheckpointsBlobStore) {
        self.blobStore = blobStore
    }

    // The store is pre-populated in these tests, so "downloading" is just confirming it's there.
    func ensureDownloaded(ref: String) async -> Bool {
        return self.blobStore.contains(ref: ref)
    }

    func ensureAllDownloaded(refs: [String]) async -> Bool {
        return refs.allSatisfy { self.blobStore.contains(ref: $0) }
    }

    func prefetch(refs: [String]) {}

}

private final class FakeCheckpointsCurrentUserProvider: CurrentUserProvider {

    var currentAppUserID: String { return "test-user" }
    var currentUserIsAnonymous: Bool { return false }

}
