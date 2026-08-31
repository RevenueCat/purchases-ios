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
    private var remoteConfigAPI: FakeCheckpointsRemoteConfigAPI!
    private var manager: RemoteConfigManager!
    private var provider: CheckpointsConfigProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.diskCache = FakeCheckpointsDiskCache()
        self.blobStore = FakeCheckpointsBlobStore()
        self.remoteConfigAPI = FakeCheckpointsRemoteConfigAPI()
        self.manager = RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            diskCache: self.diskCache,
            blobStore: self.blobStore,
            blobFetcher: FakeCheckpointsBlobFetcher(blobStore: self.blobStore),
            currentUserProvider: FakeCheckpointsCurrentUserProvider()
        )
        self.provider = CheckpointsConfigProvider(manager: self.manager)
    }

    /// Pinned as a literal: every other fixture derives the key from the enum, so a wrong wire name would be
    /// invisible here and would read as an absent topic forever.
    func testTopicWireNameMatchesTheBackend() {
        expect(RemoteConfigTopic.checkpointRules.wireName) == "checkpoint_rules"
    }

    func testResolvesACheckpointFromItsPayload() async throws {
        self.commit(rules: ["onboarding": ["wf-a"]])

        let ruleSet = try await self.ruleSet("onboarding")

        expect(ruleSet.rules.onlyElement?.workflowId) == "wf-a"
    }

    func testKeepsRulesInServedOrder() async throws {
        self.commit(rules: ["onboarding": ["wf-c", "wf-a", "wf-b"]])

        let ruleSet = try await self.ruleSet("onboarding")

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-c", "wf-a", "wf-b"]
    }

    func testResolvesEachCheckpointIndependently() async throws {
        self.commit(rules: ["onboarding": ["wf-a"], "paywall_close": ["wf-exit"]])

        let onboarding = try await self.ruleSet("onboarding")
        let paywallClose = try await self.ruleSet("paywall_close")

        expect(onboarding.rules.onlyElement?.workflowId) == "wf-a"
        expect(paywallClose.rules.onlyElement?.workflowId) == "wf-exit"
    }

    func testReturnsNilForACheckpointThatHasNoItem() async throws {
        self.commit(rules: ["onboarding": ["wf-a"]])

        let rules = try await self.provider.rules(for: "never_registered")

        expect(rules).to(beNil())
    }

    func testReturnsNilWhenTheTopicIsAbsent() async throws {
        self.commit(rules: [:])

        let rules = try await self.provider.rules(for: "onboarding")

        expect(rules).to(beNil())
    }

    func testReturnsUnavailableWhenColdFetchFails() async {
        self.remoteConfigAPI.result = .failure(.networkError(.unexpectedResponse(nil)))

        let error = await self.providerError(for: "onboarding")

        XCTAssertEqual(error, .payloadUnavailable)
    }

    func testReturnsUnavailableWhenThePayloadIsMissing() async {
        self.commit(checkpoints: ["onboarding": .init(blobRef: "missing-ref", prefetch: true)])

        let error = await self.providerError(for: "onboarding")

        XCTAssertEqual(error, .payloadUnavailable)
    }

    func testReturnsUnavailableWhenThePayloadIsntJSON() async {
        self.commit(
            checkpoints: ["onboarding": .init(blobRef: "onboarding-ref", prefetch: true)],
            blobs: ["onboarding-ref": Data("not-json".utf8)]
        )

        let error = await self.providerError(for: "onboarding")

        XCTAssertEqual(error, .payloadUnavailable)
    }

    func testReturnsUnavailableForAnItemWithoutABlobRef() async {
        self.commit(checkpoints: [
            "onboarding": .init(content: ["rules": .array([
                .object(["workflow_id": .string("wf-metadata")])
            ])])
        ])

        let error = await self.providerError(for: "onboarding")

        XCTAssertEqual(error, .payloadUnavailable)
    }

    func testNoOpManagerReturnsPayloadUnavailable() async {
        let provider = CheckpointsConfigProvider(manager: NoOpRemoteConfigManager())

        let error = await self.providerError(for: "onboarding", provider: provider)

        XCTAssertEqual(error, .payloadUnavailable)
    }

    func testResolvesACheckpointWhosePayloadHasNoRules() async throws {
        self.commit(
            checkpoints: ["onboarding": .init(blobRef: "onboarding-ref", prefetch: true)],
            blobs: ["onboarding-ref": Data(#"{ "id": "checkpoint-abc" }"#.utf8)]
        )

        let ruleSet = try await self.ruleSet("onboarding")

        expect(ruleSet.rules).to(beEmpty())
    }

    /// The provider holds no state of its own, so a config replacement is picked up on the next read.
    func testPicksUpANewPayloadAfterTheConfigIsReplaced() async throws {
        self.commit(rules: ["onboarding": ["wf-a"]])
        let before = try await self.ruleSet("onboarding")
        expect(before.rules.onlyElement?.workflowId) == "wf-a"

        self.manager.clearCache(forAppUserID: "someone-else")
        self.commit(rules: ["onboarding": ["wf-b"]])

        let after = try await self.ruleSet("onboarding")
        expect(after.rules.onlyElement?.workflowId) == "wf-b"
    }

    func testRulesSnapshotBecomesStaleAfterTheConfigIsReplaced() async throws {
        self.commit(rules: ["onboarding": ["wf-a"]])
        let rulesSnapshot = try await self.provider.rules(for: "onboarding")
        let snapshot = try XCTUnwrap(rulesSnapshot)

        XCTAssertTrue(self.provider.isCurrent(snapshot))

        self.manager.clearCache(forAppUserID: "someone-else")

        XCTAssertFalse(self.provider.isCurrent(snapshot))
    }

    // MARK: - Helpers

    private func ruleSet(_ identifier: String) async throws -> CheckpointRuleSet {
        guard let snapshot = try await self.provider.rules(for: identifier) else {
            throw NSError(
                domain: "CheckpointsConfigProviderTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Expected checkpoint rules"]
            )
        }
        return snapshot.ruleSet
    }

    private func providerError(
        for identifier: String,
        provider: CheckpointsConfigProviderType? = nil
    ) async -> CheckpointRulesProviderError? {
        do {
            _ = try await (provider ?? self.provider).rules(for: identifier)
            return nil
        } catch let error as CheckpointRulesProviderError {
            return error
        } catch {
            return nil
        }
    }

    /// One blob-backed item per checkpoint, each payload carrying one rule per workflow id.
    private func commit(rules: [String: [String]]) {
        var items: [String: RemoteConfiguration.ConfigItem] = [:]
        var blobs: [String: Data] = [:]

        for (identifier, workflowIds) in rules {
            let ref = "\(identifier)-\(workflowIds.joined(separator: "-"))-ref"
            items[identifier] = .init(blobRef: ref, prefetch: true)
            blobs[ref] = Self.payload(workflowIds: workflowIds)
        }

        self.commit(checkpoints: items, blobs: blobs)
    }

    private func commit(
        checkpoints: [String: RemoteConfiguration.ConfigItem],
        blobs: [String: Data] = [:]
    ) {
        var entries: [String: RemoteConfiguration.ConfigTopic] = [:]
        if !checkpoints.isEmpty {
            entries[RemoteConfigTopic.checkpointRules.wireName] = checkpoints
        }

        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "test-manifest",
            activeTopics: Array(entries.keys),
            topics: .init(entries: entries)
        )
        self.blobStore.stubbedData = blobs
    }

    private static func payload(workflowIds: [String]) -> Data {
        let rules = workflowIds.map { #"{ "workflow_id": "\#($0)", "audience_id": "aud_4412" }"# }
            .joined(separator: ", ")
        return Data(#"{ "rules": [\#(rules)] }"#.utf8)
    }

}

// MARK: - Fakes

private final class FakeCheckpointsRemoteConfigAPI: RemoteConfigAPIType {

    var result: Result<RemoteConfigFetchResult, BackendError> = .success(RemoteConfigFetchResult(
        response: VerifiedHTTPResponse(
            httpStatusCode: .noContent,
            responseHeaders: [:],
            body: nil,
            verificationResult: .verified,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        )
    ))

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFetchResult>
    ) {
        // Must always settle rather than hang, since a missing item triggers a refresh-and-wait. Must also
        // dispatch asynchronously: `RemoteConfigManager` calls this from inside a lock.
        let result = self.result
        DispatchQueue.global().async {
            completion(result)
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
