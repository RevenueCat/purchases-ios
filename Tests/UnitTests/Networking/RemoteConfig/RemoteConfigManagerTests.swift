//
//  RemoteConfigManagerTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigManagerTests: TestCase {

    private static let lastRefreshAt = Date(timeIntervalSince1970: 1_710_000_100)

    private var remoteConfigAPI: MockRemoteConfigAPI!
    private var diskCache: MockRemoteConfigDiskCache!
    private var dateProvider: MockDateProvider!
    private var blobStore: MockRemoteConfigBlobStore!
    private var manager: RemoteConfigManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.remoteConfigAPI = MockRemoteConfigAPI()
        self.diskCache = MockRemoteConfigDiskCache()
        self.dateProvider = MockDateProvider(stubbedNow: Self.lastRefreshAt)
        self.blobStore = MockRemoteConfigBlobStore()
        self.manager = RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            diskCache: self.diskCache,
            blobStore: self.blobStore,
            dateProvider: self.dateProvider
        )
    }

    override func tearDownWithError() throws {
        self.manager = nil
        self.dateProvider = nil
        self.blobStore = nil
        self.diskCache = nil
        self.remoteConfigAPI = nil

        try super.tearDownWithError()
    }

    func testFirstRunSendsDefaultAppDomainManifest() throws {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs).to(beEmpty())
    }

    func testSubsequentRunReplaysPersistedManifest() throws {
        let persistedManifest = "v1.1710000100.sources:etag1"
        self.blobStore.stubbedContainsRefs = ["prefetchedBlob"]
        self.diskCache.stubbedRead = Self.persisted(
            domain: "custom",
            manifest: persistedManifest,
            topicBlobRefs: [:],
            prefetchedBlobRefs: ["prefetchedBlob"]
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.domain) == "custom"
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest) == persistedManifest
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs) == ["prefetchedBlob"]
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == true
    }

    func testOverlappingRefreshesAreIgnoredUntilInFlightRefreshCompletes() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == true
    }

    func testSubsequentRunSendsOnlyPersistedPrefetchedBlobsStillCachedLocally() throws {
        self.blobStore.stubbedContainsRefs = ["cachedBlob"]
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            topicBlobRefs: [:],
            prefetchedBlobRefs: ["cachedBlob", "purgedBlob"]
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs) == ["cachedBlob"]
    }

    func testContainerResponsePersistsServerManifestAndChangedTopicBlobRefs() throws {
        self.diskCache.stubbedRead = nil
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["newBlob"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedWriteParameter?.domain) == "app"
        expect(self.diskCache.invokedWriteParameter?.manifest)
            == "v1.1710000100.sources:etag2"
        expect(self.diskCache.invokedWriteParameter?.activeTopics) == ["sources"]
        expect(self.diskCache.invokedWriteParameter?.prefetchBlobs) == ["newBlob"]
        expect(self.diskCache.invokedWriteParameter?.topicBlobRefs) == ["sources": ["newBlob"]]
        expect(self.diskCache.invokedWriteParameter?.lastRefreshAt) == Self.lastRefreshAt
        expect(self.diskCache.invokedWriteParameter?.prefetchedBlobRefs).to(beEmpty())
    }

    func testContainerResponseMergesUnchangedTopicRefsAndPrunesDroppedTopics() throws {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag1",
            topicBlobRefs: [
                "sources": ["oldSources"],
                "product_entitlement_mapping": ["pemBlob"]
            ]
        )
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newSources" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteParameter?.topicBlobRefs) == ["sources": ["newSources"]]
        expect(self.blobStore.invokedRetainOnlyParameters) == Set(["newSources"])
    }

    func testContainerResponseKeepsPreviousRefsForUnchangedTopicsStillActive() throws {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag1",
            topicBlobRefs: [
                "sources": ["oldSources"],
                "product_entitlement_mapping": ["pemBlob"]
            ]
        )
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag2",
          "active_topics": ["sources", "product_entitlement_mapping"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newSources" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteParameter?.topicBlobRefs) == [
            "sources": ["newSources"],
            "product_entitlement_mapping": ["pemBlob"]
        ]
    }

    func testContainerResponsePersistsEmptyBlobRefListForInlineOnlyChangedTopics() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "api": {
                "url": "https://api.revenuecat.com",
                "priority": 100
              }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteParameter?.topicBlobRefs) == ["sources": []]
    }

    func testNoContentResponseUpdatesLastRefreshAtForPersistedCache() {
        let previous = Self.persisted(
            domain: "app",
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            prefetchBlobs: ["prefetchBlob"],
            topicBlobRefs: ["sources": ["sourceBlob"]],
            lastRefreshAt: Date(timeIntervalSince1970: 1)
        )
        self.diskCache.stubbedRead = previous

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedWriteParameter) == PersistedRemoteConfiguration(
            domain: previous.domain,
            manifest: previous.manifest,
            activeTopics: previous.activeTopics,
            prefetchBlobs: previous.prefetchBlobs,
            topicBlobRefs: previous.topicBlobRefs,
            lastRefreshAt: Self.lastRefreshAt,
            prefetchedBlobRefs: previous.prefetchedBlobRefs
        )
    }

    func testNoContentResponseWithNoPersistedCacheLeavesCacheUntouched() {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testBackendErrorLeavesCacheUntouched() {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1"
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testMalformedConfigPayloadLeavesCacheUntouched() throws {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: "{ not valid json")))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testConfigDecodingUsesOnlyContainerConfigElement() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """
        let invalidContentElement = "{ invalid content element json".asData

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [invalidContentElement])
            ))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedWriteParameter?.topicBlobRefs) == ["sources": ["newBlob"]]
    }

    func testContainerResponseCachesInlineContentElements() throws {
        let blob = "blob payload".asData
        let blobRef = RCContainerTestData.blobRef(for: blob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(blobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.container(
                try Self.container(config: response, contentElements: [blob]),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParameters?.ref) == blobRef
        expect(self.blobStore.invokedWriteParameters?.data) == blob
    }

    func testContainerResponseCachesOnlyValidInlineContentElements() throws {
        let validBlob = "valid blob".asData
        let invalidBlob = "invalid blob".asData
        let validBlobRef = RCContainerTestData.blobRef(for: validBlob)
        let invalidBlobRef = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(validBlobRef)" }
            }
          }
        }
        """
        let containerData = RCContainerTestData.container(
            config: response.asData,
            contentElements: [validBlob, invalidBlob],
            checksumOverride: { index, payload in
                return index == 2
                    ? Array(repeating: 0, count: RCContainerTestData.checksumSize)
                    : RCContainerTestData.checksum(for: payload)
            }
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.container(try RemoteConfigContainer(data: containerData), verificationResult: .verified))
        )

        expect(self.blobStore.invokedWriteParametersList.map(\.ref)) == [validBlobRef]
        expect(self.blobStore.invokedWriteParametersList.map(\.data)) == [validBlob]
        expect(self.blobStore.invokedWriteParametersList.map(\.ref)).toNot(contain(invalidBlobRef))
    }

    func testContainerResponseRetainsPrefetchAndTopicBlobRefs() throws {
        let topicBlobRef = RCContainerTestData.blobRef(for: "topic blob".asData)
        let prefetchBlobRef = RCContainerTestData.blobRef(for: "prefetch blob".asData)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["\(prefetchBlobRef)"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(topicBlobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.container(try Self.container(config: response), verificationResult: .verified))
        )

        expect(self.blobStore.invokedRetainOnlyParameters) == Set([topicBlobRef, prefetchBlobRef])
    }

    func testContainerResponsePersistsOnlyPrefetchBlobRefsHeldInBlobStore() throws {
        let cachedRef = RCContainerTestData.blobRef(for: "cached".asData)
        let missingRef = RCContainerTestData.blobRef(for: "missing".asData)
        self.blobStore.stubbedContainsRefs = [cachedRef]
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["\(cachedRef)", "\(missingRef)"]
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.container(try Self.container(config: response), verificationResult: .verified))
        )

        expect(self.diskCache.invokedWriteParameter?.prefetchedBlobRefs) == [cachedRef]
    }

    func testContainerResponseDoesNotPruneBlobStoreWhenCacheWriteFails() throws {
        let oldRef = RCContainerTestData.blobRef(for: "old".asData)
        let newRef = RCContainerTestData.blobRef(for: "new".asData)
        self.diskCache.stubbedWriteResult = false
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: RemoteConfigManifestToken("v1.1710000100.sources:etag1"),
            topicBlobRefs: ["sources": [oldRef]]
        )
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(newRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.container(try Self.container(config: response), verificationResult: .verified))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

}

private extension RemoteConfigManagerTests {

    static func persisted(
        domain: String = RemoteConfiguration.defaultDomain,
        manifest: String,
        activeTopics: [String] = [],
        prefetchBlobs: [String] = [],
        topicBlobRefs: [String: [String]] = [:],
        lastRefreshAt: Date? = nil,
        prefetchedBlobRefs: [String] = []
    ) -> PersistedRemoteConfiguration {
        return PersistedRemoteConfiguration(
            domain: domain,
            manifest: manifest,
            activeTopics: activeTopics,
            prefetchBlobs: prefetchBlobs,
            topicBlobRefs: topicBlobRefs,
            lastRefreshAt: lastRefreshAt,
            prefetchedBlobRefs: prefetchedBlobRefs
        )
    }

    static func container(
        config: String,
        contentElements: [Data] = []
    ) throws -> RemoteConfigContainer {
        return try RemoteConfigContainer(data: RCContainerTestData.container(
            config: config.asData,
            contentElements: contentElements
        ))
    }

}

private extension RemoteConfigFetchResult {

    /// Builds a fetch result through the production initializer. A `nil` container
    /// represents a `204 No Content` response.
    static func test(
        container: RemoteConfigContainer?,
        verificationResult: VerificationResult = .verified
    ) -> RemoteConfigFetchResult {
        return RemoteConfigFetchResult(response: .init(
            httpStatusCode: container == nil ? .noContent : .success,
            responseHeaders: [:],
            body: container,
            verificationResult: verificationResult,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ))
    }

}

private final class MockRemoteConfigAPI: RemoteConfigAPIType {

    private(set) var invokedGetRemoteConfigCount = 0
    private(set) var invokedGetRemoteConfigParameters: (
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool
    )?

    private var completion: Backend.ResponseHandler<RemoteConfigFetchResult>?

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFetchResult>
    ) {
        self.invokedGetRemoteConfigCount += 1
        self.invokedGetRemoteConfigParameters = (request, isAppBackgrounded)
        self.completion = completion
    }

    func complete(with result: Result<RemoteConfigFetchResult, BackendError>) {
        self.completion?(result)
    }

}

private final class MockRemoteConfigDiskCache: RemoteConfigDiskCacheType {

    var stubbedRead: PersistedRemoteConfiguration?
    var stubbedWriteResult = true

    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameter: PersistedRemoteConfiguration?

    func read() -> PersistedRemoteConfiguration? {
        return self.stubbedRead
    }

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool {
        self.invokedWriteCount += 1
        self.invokedWriteParameter = configuration

        return self.stubbedWriteResult
    }

}

private final class MockRemoteConfigBlobStore: RemoteConfigBlobStoreType {

    var stubbedContainsRefs: Set<String> = []

    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameters: (ref: String, data: Data)?
    private(set) var invokedWriteParametersList: [(ref: String, data: Data)] = []
    private(set) var invokedRetainOnlyCount = 0
    private(set) var invokedRetainOnlyParameters: Set<String>?

    func contains(ref: String) -> Bool {
        return self.stubbedContainsRefs.contains(ref)
    }

    func read(ref: String) -> Data? {
        return nil
    }

    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) {
        self.invokedWriteCount += 1
        var data = Data()
        data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
        self.invokedWriteParameters = (ref, data)
        self.invokedWriteParametersList.append((ref, data))
    }

    func cachedRefs() -> Set<String> {
        return []
    }

    func retainOnly(_ refs: Set<String>) {
        self.invokedRetainOnlyCount += 1
        self.invokedRetainOnlyParameters = refs
    }

}
