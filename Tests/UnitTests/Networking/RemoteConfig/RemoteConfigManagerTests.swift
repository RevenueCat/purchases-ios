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
    private var manager: RemoteConfigManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.remoteConfigAPI = MockRemoteConfigAPI()
        self.diskCache = MockRemoteConfigDiskCache()
        self.dateProvider = MockDateProvider(stubbedNow: Self.lastRefreshAt)
        self.manager = RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            diskCache: self.diskCache,
            dateProvider: self.dateProvider
        )
    }

    override func tearDownWithError() throws {
        self.manager = nil
        self.dateProvider = nil
        self.diskCache = nil
        self.remoteConfigAPI = nil

        try super.tearDownWithError()
    }

    func testFirstRunSendsDefaultAppDomainManifest() throws {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest).to(beNil())
    }

    func testSubsequentRunReplaysPersistedManifest() throws {
        let persistedManifest = "v1.1710000100.sources:etag1"
        self.diskCache.stubbedRead = Self.persisted(
            domain: "custom",
            manifest: persistedManifest,
            prefetchBlobs: ["alreadyCachedBlob"]
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.domain) == "custom"
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest) == persistedManifest
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs) == ["alreadyCachedBlob"]
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
            lastRefreshAt: Self.lastRefreshAt
        )
    }

    func testNoContentResponseWithNoPersistedCacheLeavesCacheUntouched() {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 0
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
    }

    func testMalformedConfigPayloadLeavesCacheUntouched() throws {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: "{ not valid json")))
        )

        expect(self.diskCache.invokedWriteCount) == 0
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

}

private extension RemoteConfigManagerTests {

    static func persisted(
        domain: String = RemoteConfiguration.defaultDomain,
        manifest: String,
        activeTopics: [String] = [],
        prefetchBlobs: [String] = [],
        topicBlobRefs: [String: [String]] = [:],
        lastRefreshAt: Date? = nil
    ) -> PersistedRemoteConfiguration {
        return PersistedRemoteConfiguration(
            domain: domain,
            manifest: manifest,
            activeTopics: activeTopics,
            prefetchBlobs: prefetchBlobs,
            topicBlobRefs: topicBlobRefs,
            lastRefreshAt: lastRefreshAt
        )
    }

    static func container(
        config: String,
        contentElements: [Data] = []
    ) throws -> RCContainer {
        return try RCContainer(data: RCContainerTestData.container(
            config: config.asData,
            contentElements: contentElements
        ))
    }

}

private extension RemoteConfigFetchResult {

    /// Builds a fetch result through the production initializer. A `nil` container
    /// represents a `204 No Content` response.
    static func test(
        container: RCContainer?,
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

    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameter: PersistedRemoteConfiguration?

    func read() -> PersistedRemoteConfiguration? {
        return self.stubbedRead
    }

    func write(_ configuration: PersistedRemoteConfiguration) {
        self.invokedWriteCount += 1
        self.invokedWriteParameter = configuration
    }

}
