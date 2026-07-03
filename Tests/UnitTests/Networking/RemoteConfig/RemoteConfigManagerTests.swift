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

    private static let appUserID = "app-user-id"

    private var remoteConfigAPI: MockRemoteConfigAPI!
    private var diskCache: MockRemoteConfigDiskCache!
    private var blobStore: MockRemoteConfigBlobStore!
    private var blobFetcher: MockRemoteConfigBlobFetcher!
    private var currentUserProvider: MockCurrentUserProvider!
    private var dateProvider: MockCurrentDateProvider!
    private var manager: RemoteConfigManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.remoteConfigAPI = MockRemoteConfigAPI()
        self.diskCache = MockRemoteConfigDiskCache()
        self.blobStore = MockRemoteConfigBlobStore()
        self.blobFetcher = MockRemoteConfigBlobFetcher()
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: Self.appUserID)
        self.dateProvider = MockCurrentDateProvider()
        let dateProvider = self.dateProvider!
        self.manager = RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            diskCache: self.diskCache,
            blobStore: self.blobStore,
            blobFetcher: self.blobFetcher,
            currentUserProvider: self.currentUserProvider,
            dateProvider: dateProvider,
            cacheDurationInSeconds: { isAppBackgrounded in
                isAppBackgrounded ? 10 : 5
            }
        )
    }

    override func tearDownWithError() throws {
        self.manager = nil
        self.blobFetcher = nil
        self.blobStore = nil
        self.currentUserProvider = nil
        self.dateProvider = nil
        self.diskCache = nil
        self.remoteConfigAPI = nil

        try super.tearDownWithError()
    }

    func testIsDisabledDefaultsToFalse() {
        expect(self.manager.isDisabled) == false
    }

    func testRefreshRemoteConfigIfStaleRefreshesWhenNeverRefreshed() {
        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testNoContentResponseMarksRefreshAsFresh() {
        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testFailureDoesNotMarkRefreshAsFresh() {
        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1)))))

        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testRefreshRemoteConfigIfStaleUsesForegroundAndBackgroundDurations() {
        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        self.dateProvider.advance(by: 6)
        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testClosePreventsNewRefreshes() {
        self.manager.close()

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 0
    }

    func testTopicReturnsNilAfterCloseWithoutReadingCache() async {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: ["sources": ["api": .init(content: ["url": .string("https://api.revenuecat.com")])]])
        )
        self.manager.close()

        let topic = await self.manager.topic(.sources)

        expect(topic).to(beNil())
        expect(self.diskCache.invokedReadCount) == 0
    }

    func testBlobDataReturnsNilAfterCloseWithoutReadingOrFetching() async {
        let ref = RCContainerTestData.blobRef(for: #"{"id":"workflow"}"#.asData)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["default": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = #"{"id":"workflow"}"#.asData
        self.manager.close()

        let data = await self.manager.blobData(for: .workflows, itemKey: "default")

        expect(data).to(beNil())
        expect(self.diskCache.invokedReadCount) == 0
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
    }

    func testResponseThatArrivesAfterCloseDoesNotPersist() throws {
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

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.close()
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testFirstRunSendsDefaultAppDomainManifest() throws {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == Self.appUserID
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs).to(beEmpty())
    }

    func testSubsequentRunReplaysPersistedManifest() throws {
        let persistedManifest = "v1.1710000100.sources:etag1"
        self.blobStore.stubbedContainsRefs = ["prefetchedBlob"]
        self.diskCache.stubbedRead = Self.persisted(
            domain: "custom",
            manifest: persistedManifest,
            prefetchBlobs: ["prefetchedBlob"],
            topics: .init()
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == Self.appUserID
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

    func testSubsequentRunSendsOnlyRequestedPrefetchBlobsStillCachedLocally() throws {
        self.blobStore.stubbedContainsRefs = ["cachedBlob"]
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            prefetchBlobs: ["cachedBlob", "purgedBlob"],
            topics: .init()
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs) == ["cachedBlob"]
        expect(self.blobStore.invokedCachedRefsCount) == 1
    }

    func testTopicReturnsCommittedMetadataWithoutRefreshing() async {
        let item = RemoteConfiguration.ConfigItem(content: ["url": "https://api.revenuecat.com"])
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: ["sources": ["api": item]])
        )

        let topic = await self.manager.topic(.sources)

        expect(topic?["api"]) == item
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 0
    }

    func testTopicReturnsNilWhenRemoteConfigIsDisabledDuringCommittedRead() async {
        let item = RemoteConfiguration.ConfigItem(content: ["url": "https://api.revenuecat.com"])
        let persisted = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: ["sources": ["api": item]])
        )
        self.diskCache.stubbedRead = persisted
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.diskCache.readHandler = {
            self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))
            return persisted
        }

        let topic = await self.manager.topic(.sources)

        expect(topic).to(beNil())
    }

    @MainActor
    func testTopicReadsCommittedMetadataOffMainThread() async {
        let item = RemoteConfiguration.ConfigItem(content: ["url": "https://api.revenuecat.com"])
        let persisted = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: ["sources": ["api": item]])
        )
        let lock = Lock()
        var readThreadIsMain: Bool?
        self.diskCache.readHandler = {
            lock.perform {
                readThreadIsMain = Thread.isMainThread
            }
            return persisted
        }

        let topic = await self.manager.topic(.sources)

        expect(topic?["api"]) == item
        expect(lock.perform { readThreadIsMain }) == false
    }

    func testBlobDataReturnsNilForItemWithoutBlobRef() async {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: [
                "sources": ["api": .init(content: ["priority": 100, "url": "https://api.revenuecat.com"])]
            ])
        )

        let data = await self.manager.blobData(for: .sources, itemKey: "api")

        expect(data).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 0
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
    }

    func testTopicReturnsInlineMetadata() async throws {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: [
                "sources": ["api": .init(content: ["priority": 100, "url": "https://api.revenuecat.com"])]
            ])
        )

        let maybeTopic = await self.manager.topic(.sources)
        let topic = try XCTUnwrap(maybeTopic)

        expect(topic["api"]?.content["priority"]) == 100
        expect(topic["api"]?.content["url"]) == "https://api.revenuecat.com"
    }

    func testTopicColdReadTriggersForegroundRefresh() async throws {
        self.diskCache.writeHandler = { configuration in
            self.diskCache.stubbedRead = configuration
            return true
        }
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "api": { "url": "https://api.revenuecat.com" }
            }
          }
        }
        """

        let task = Task {
            await self.manager.topic(.sources)
        }
        await self.waitForRemoteConfigRequestCount(1)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == false
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let maybeTopic = await task.value
        let topic = try XCTUnwrap(maybeTopic)
        expect(topic["api"]?.content["url"]) == "https://api.revenuecat.com"
    }

    func testTopicWaitsForInFlightRefreshBeforeReturningMissingTopic() async throws {
        self.diskCache.writeHandler = { configuration in
            self.diskCache.stubbedRead = configuration
            return true
        }
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "api": { "url": "https://api.revenuecat.com" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        let task = Task {
            await self.manager.topic(.sources)
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let maybeTopic = await task.value
        let topic = try XCTUnwrap(maybeTopic)
        expect(topic["api"]?.content["url"]) == "https://api.revenuecat.com"
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testTopicReturnsNilWhenRemoteConfigIsDisabledEvenWithCachedTopic() async {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: [
                "sources": ["api": .init(content: ["url": "https://api.revenuecat.com"])]
            ])
        )
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))

        let topic = await self.manager.topic(.sources)

        expect(topic).to(beNil())
    }

    func testBlobDataDecodesExternalBlob() async throws {
        let ref = RCContainerTestData.blobRef(for: #"{"id":"workflow"}"#.asData)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["default": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = #"{"id":"workflow"}"#.asData

        let value = try await self.manager.blobData(for: .workflows, itemKey: "default", as: WorkflowPayload.self)

        expect(value) == WorkflowPayload(id: "workflow")
        expect(self.blobFetcher.invokedEnsureDownloadedRefs) == [ref]
        expect(self.blobStore.invokedReadRefs) == [ref]
    }

    func testBlobDataReturnsNilWhenExternalBlobDownloadFails() async {
        let ref = RCContainerTestData.blobRef(for: #"{"id":"workflow"}"#.asData)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["default": .init(blobRef: ref)]])
        )
        self.blobFetcher.stubbedEnsureDownloadedResult = false

        let data = await self.manager.blobData(for: .workflows, itemKey: "default")

        expect(data).to(beNil())
        expect(self.blobFetcher.invokedEnsureDownloadedRefs) == [ref]
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
    }

    func testBlobDataThrowsWhenPresentDataCannotDecode() async throws {
        let ref = RCContainerTestData.blobRef(for: #"{"id":1}"#.asData)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["default": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = #"{"id":1}"#.asData

        do {
            _ = try await self.manager.blobData(for: .workflows, itemKey: "default", as: WorkflowPayload.self)
            fail("Expected decoding to fail")
        } catch {
            expect(error).toNot(beNil())
        }
    }

    func testContainerResponsePersistsServerManifestAndChangedTopics() throws {
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
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": ["newBlob"]]
    }

    func testContainerResponseDecodesCompressedConfigElement() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "api": { "url": "https://api.revenuecat.com" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.compressedContainer(
                config: response,
                configEncoding: .gzip
            )))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedWriteParameter?.manifest) == "v1.1710000100.sources:etag2"
    }

    func testContainerResponseMergesUnchangedTopicsAndPrunesDroppedTopics() throws {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag1",
            topics: .init(entries: [
                "sources": ["default": .init(blobRef: "oldSources")],
                "product_entitlement_mapping": ["default": .init(blobRef: "pemBlob")]
            ])
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

        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": ["newSources"]]
        expect(self.blobStore.invokedRetainOnlyParameters) == Set(["newSources"])
    }

    func testContainerResponseKeepsPreviousEntriesForUnchangedTopicsStillActive() throws {
        let previousProductMapping = RemoteConfiguration.ConfigItem(
            blobRef: "pemBlob",
            content: ["format": "v1"]
        )
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag1",
            topics: .init(entries: [
                "sources": ["default": .init(blobRef: "oldSources")],
                "product_entitlement_mapping": ["default": previousProductMapping]
            ])
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

        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == [
            "sources": ["newSources"],
            "product_entitlement_mapping": ["pemBlob"]
        ]
        expect(self.diskCache.invokedWriteParameter?.topics.entries["product_entitlement_mapping"]?["default"])
            == previousProductMapping
    }

    func testContainerResponsePersistsInlineOnlyChangedTopics() throws {
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

        let item = self.diskCache.invokedWriteParameter?.topics.entries["sources"]?["api"]
        expect(item?.blobRef).to(beNil())
        expect(item?.content["url"]) == "https://api.revenuecat.com"
        expect(item?.content["priority"]) == 100
    }

    func testNoContentResponseWithPersistedCacheLeavesCacheUntouched() {
        let previous = Self.persisted(
            domain: "app",
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            prefetchBlobs: ["prefetchBlob"],
            topics: .init(entries: ["sources": ["default": .init(blobRef: "sourceBlob")]])
        )
        self.diskCache.stubbedRead = previous

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testNoContentResponseWithNoPersistedCacheLeavesCacheUntouched() {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
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
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testFourHundredResponseDisablesRemoteConfig() {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1"
        )

        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .invalidRequest)))
        expect(self.manager.isDisabled) == true
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedReadCount) == 1
        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testTooManyRequestsResponseDisablesRemoteConfig() {
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .tooManyRequests)))
        expect(self.manager.isDisabled) == true
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedReadCount) == 1
    }

    func testServerErrorDoesNotDisableRemoteConfig() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedReadCount) == 2
    }

    func testTransportNetworkErrorDoesNotDisableRemoteConfig() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedReadCount) == 2
    }

    func testClearCacheDoesNotReenableDisabledRemoteConfigRefresh() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))
        expect(self.manager.isDisabled) == true
        self.manager.clearCache()
        expect(self.manager.isDisabled) == true
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobStore.invokedClearCount) == 1
    }

    func testMalformedConfigPayloadLeavesCacheUntouched() throws {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: "{ not valid json")))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
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
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": ["newBlob"]]
    }

    func testBlobDataWaitsForInFlightRefreshBeforeReturningMissingItem() async throws {
        let blob = #"{"id":"workflow"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.writeHandler = { configuration in
            self.diskCache.stubbedRead = configuration
            return true
        }
        self.blobStore.stubbedReadDataByRef[ref] = blob
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.workflows:etag2",
          "active_topics": ["workflows"],
          "topics": {
            "workflows": {
              "default": { "blob_ref": "\(ref)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        let task = Task {
            await self.manager.blobData(for: .workflows, itemKey: "default")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let maybeData = await task.value
        let data = try XCTUnwrap(maybeData)
        expect(data) == blob
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testBlobDataColdReadTriggersForegroundRefresh() async throws {
        let blob = #"{"id":"workflow"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.writeHandler = { configuration in
            self.diskCache.stubbedRead = configuration
            return true
        }
        self.blobStore.stubbedReadDataByRef[ref] = blob
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.workflows:etag2",
          "active_topics": ["workflows"],
          "topics": {
            "workflows": {
              "default": { "blob_ref": "\(ref)" }
            }
          }
        }
        """

        let task = Task {
            await self.manager.blobData(for: .workflows, itemKey: "default")
        }
        await self.waitForRemoteConfigRequestCount(1)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == false
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let maybeData = await task.value
        let data = try XCTUnwrap(maybeData)
        expect(data) == blob
    }

    func testBlobDataColdReadUsesCurrentAppUserIDWhenTriggeringRefresh() async {
        self.currentUserProvider.mockAppUserID = "new-user"

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        _ = await task.value

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == "new-user"
    }

    func testBlobDataNoContentRefreshCompletesWaitingRead() async {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        let data = await task.value
        expect(data).to(beNil())
    }

    func testBlobDataFailedRefreshCompletesWaitingRead() async {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.remoteConfigAPI.complete(with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1)))))

        let data = await task.value
        expect(data).to(beNil())
    }

    func testBlobDataMalformedRefreshCompletesWaitingRead() async throws {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: "{ not valid json")))
        )

        let data = await task.value
        expect(data).to(beNil())
    }

    func testBlobDataClearCacheCompletesWaitingRead() async {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.manager.clearCache()

        let data = await task.value
        expect(data).to(beNil())
    }

    func testBlobDataCloseCompletesWaitingRead() async {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.manager.close()

        let data = await task.value
        expect(data).to(beNil())
    }

    func testBlobDataDoesNotTriggerRefreshWhenRemoteConfigIsDisabled() async {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))

        let data = await self.manager.blobData(for: .sources, itemKey: "api")

        expect(data).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testBlobDataDoesNotFetchExternalBlobWhenRemoteConfigIsDisabled() async {
        let ref = RCContainerTestData.blobRef(for: #"{"id":"workflow"}"#.asData)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["default": .init(blobRef: ref)]])
        )
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))
        let readCountAfterDisabling = self.diskCache.invokedReadCount

        let data = await self.manager.blobData(for: .workflows, itemKey: "default")

        expect(data).to(beNil())
        expect(self.diskCache.invokedReadCount) == readCountAfterDisabling
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
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
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [blob]),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParameters?.ref) == blobRef
        expect(self.blobStore.invokedWriteParameters?.data) == blob
    }

    func testBlobDataReadsContainerInlineBlobAfterItIsStored() async throws {
        let blob = #"{"id":"workflow"}"#.asData
        let blobRef = RCContainerTestData.blobRef(for: blob)
        self.diskCache.writeHandler = { configuration in
            self.diskCache.stubbedRead = configuration
            return true
        }
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.workflows:etag2",
          "active_topics": ["workflows"],
          "topics": {
            "workflows": {
              "default": { "blob_ref": "\(blobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [blob]),
                verificationResult: .verified
            ))
        )

        let data = await self.manager.blobData(for: .workflows, itemKey: "default")

        expect(data) == blob
        expect(self.blobFetcher.invokedEnsureDownloadedRefs) == [blobRef]
        expect(self.blobStore.invokedReadRefs) == [blobRef]
    }

    func testSingleElementFixtureCachesReferencedWorkflowBlob() throws {
        let fixture = try XCTUnwrap(RCContainerTestData.allFixtures.first { $0.fileName == "v1_single_element.bin" })
        let container = try RemoteConfigContainer(data: RCContainerTestData.container(fixture: fixture))
        let workflowBlobRef = RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob)
        let summerWorkflowBlobRef = RCContainerTestData.blobRef(for: RCContainerTestData.summerWorkflowBlob)

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: container,
                verificationResult: .verified
            ))
        )

        expect(self.diskCache.invokedWriteParameter?.activeTopics) == ["workflows"]
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == [
            "workflows": [workflowBlobRef, summerWorkflowBlobRef]
        ]
        expect(self.blobStore.invokedWriteParameters?.ref) == workflowBlobRef
        expect(self.blobStore.invokedWriteParameters?.data) == RCContainerTestData.workflowBlob
    }

    func testContainerResponseCachesDecodedCompressedInlineContentElements() throws {
        let blob = Data(repeating: UInt8(ascii: "b"), count: 2048)
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
            with: .success(.test(
                container: try Self.compressedContainer(
                    config: response,
                    contentElements: [(payload: blob, encoding: .gzip)]
                ),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParameters?.ref) == blobRef
        expect(self.blobStore.invokedWriteParameters?.data) == blob
    }

    func testContainerResponseSkipsUnsupportedCodecInlineContentElements() throws {
        let blob = "unsupported codec blob".asData
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
            with: .success(.test(
                container: try Self.compressedContainer(
                    config: response,
                    contentElements: [(payload: blob, encoding: .zstd)]
                ),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteCount) == 0
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": [blobRef]]
    }

    func testContainerResponseSkipsGzipInlineContentElementWithTrailingBytes() throws {
        let blob = Data(repeating: UInt8(ascii: "b"), count: 2048)
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
            with: .success(.test(
                container: try RemoteConfigContainer(
                    data: RCContainerTestData.compressedContainerWithTrailingGzipContentElement(
                        config: response.asData,
                        content: blob,
                        trailingBytes: Data([0xff])
                    )
                ),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteCount) == 0
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": [blobRef]]
    }

    func testContainerResponseCachesOnlyReferencedInlineContentElements() throws {
        let referencedBlob = "referenced blob".asData
        let unreferencedBlob = "unreferenced blob".asData
        let referencedBlobRef = RCContainerTestData.blobRef(for: referencedBlob)
        let unreferencedBlobRef = RCContainerTestData.blobRef(for: unreferencedBlob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(referencedBlobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [referencedBlob, unreferencedBlob]),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParametersList.map(\.ref)) == [referencedBlobRef]
        expect(self.blobStore.invokedWriteParametersList.map(\.data)) == [referencedBlob]
        expect(self.blobStore.invokedWriteParametersList.map(\.ref)).toNot(contain(unreferencedBlobRef))
    }

    func testContainerResponseCachesInlineContentElementReferencedOnlyByPrefetchBlobs() throws {
        let prefetchBlob = "prefetch blob".asData
        let prefetchBlobRef = RCContainerTestData.blobRef(for: prefetchBlob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["\(prefetchBlobRef)"],
          "topics": {
            "sources": {
              "api": { "url": "https://api.revenuecat.com" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [prefetchBlob]),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParameters?.ref) == prefetchBlobRef
        expect(self.blobStore.invokedWriteParameters?.data) == prefetchBlob
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
            with: .success(.test(
                container: try RemoteConfigContainer(data: containerData),
                verificationResult: .verified
            ))
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
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedRetainOnlyParameters) == Set([topicBlobRef, prefetchBlobRef])
    }

    func testContainerResponsePersistsServerPrefetchBlobRefs() throws {
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
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.diskCache.invokedWriteParameter?.prefetchBlobs) == [cachedRef, missingRef]
    }

    func testContainerResponsePrefetchesServerPrefetchBlobRefs() throws {
        let cachedRef = RCContainerTestData.blobRef(for: "cached".asData)
        let missingRef = RCContainerTestData.blobRef(for: "missing".asData)
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
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.blobFetcher.invokedPrefetchRefs) == [cachedRef, missingRef]
    }

    func testContainerResponseDoesNotPruneBlobStoreWhenCacheWriteFails() throws {
        let oldRef = RCContainerTestData.blobRef(for: "old".asData)
        let newRef = RCContainerTestData.blobRef(for: "new".asData)
        self.diskCache.stubbedWriteResult = false
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: ["sources": ["default": .init(blobRef: oldRef)]])
        )
        let blob = "new".asData
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
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [blob]),
                verificationResult: .verified
            ))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testContainerResponseDoesNotMarkRefreshAsFreshWhenCacheWriteFails() throws {
        self.diskCache.stubbedWriteResult = false
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"]
        }
        """

        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )
        self.manager.refreshRemoteConfigIfStale(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testClearCacheWipesDiskCacheAndBlobStore() {
        self.manager.clearCache()

        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobStore.invokedClearCount) == 1
    }

    func testResponseThatArrivesAfterClearCacheDoesNotPersist() throws {
        self.diskCache.stubbedRead = nil
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

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.remoteConfigAPI.complete(
            at: 0,
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testClearCacheWhileBuildingRequestDoesNotSendStaleRequest() {
        self.diskCache.readHandler = { [manager] in
            manager?.clearCache()
            return nil
        }

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 0
        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobStore.invokedClearCount) == 1
    }

    func testStaleNoContentResponseDoesNotReleaseNewerRefreshGuard() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        self.remoteConfigAPI.complete(at: 0, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testStaleContainerResponseDoesNotReleaseNewerRefreshGuard() throws {
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

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        self.remoteConfigAPI.complete(
            at: 0,
            with: .success(.test(container: try Self.container(config: response)))
        )
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedWriteCount) == 0

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testStaleErrorResponseDoesNotReleaseNewerRefreshGuard() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        self.remoteConfigAPI.complete(
            at: 0,
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testStaleFourHundredResponseDoesNotDisableRemoteConfig() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        self.remoteConfigAPI.complete(at: 0, with: .failure(Self.backendError(statusCode: .invalidRequest)))
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testManagerCanSyncAgainAfterClearCache() throws {
        self.diskCache.stubbedRead = nil
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

        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedWriteCount) == 1
    }

    func testClearCacheDuringPersistWaitsAndWipesAfterWrite() throws {
        self.diskCache.stubbedRead = nil
        let writeStarted = DispatchSemaphore(value: 0)
        let releaseWrite = DispatchSemaphore(value: 0)
        let clearEntered = DispatchSemaphore(value: 0)
        let writeReleaseResult: Atomic<DispatchTimeoutResult?> = nil
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
        let container = try Self.container(config: response)
        self.diskCache.writeHandler = { _ in
            writeStarted.signal()
            writeReleaseResult.value = releaseWrite.wait(timeout: .now() + .seconds(5))
            return true
        }
        self.diskCache.clearHandler = {
            clearEntered.signal()
        }

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        DispatchQueue.global().async {
            self.remoteConfigAPI.complete(
                with: .success(.test(container: container))
            )
        }
        expect(writeStarted.wait(timeout: .now() + .seconds(5))) == .success

        DispatchQueue.global().async {
            self.manager.clearCache()
        }

        expect(clearEntered.wait(timeout: .now() + .milliseconds(200))) == .timedOut

        releaseWrite.signal()
        expect(clearEntered.wait(timeout: .now() + .seconds(5))) == .success
        expect(writeReleaseResult.value) == .success
        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedClearCount) == 1
    }

}

private extension RemoteConfigManagerTests {

    static func persisted(
        domain: String = RemoteConfiguration.defaultDomain,
        manifest: String,
        activeTopics: [String] = [],
        prefetchBlobs: [String] = [],
        topics: RemoteConfiguration.Topics = .init()
    ) -> PersistedRemoteConfiguration {
        return PersistedRemoteConfiguration(
            domain: domain,
            manifest: manifest,
            activeTopics: activeTopics,
            prefetchBlobs: prefetchBlobs,
            topics: topics
        )
    }

    static func blobRefsByTopic(from topics: RemoteConfiguration.Topics?) -> [String: Set<String>] {
        guard let topics else { return [:] }

        return topics.entries.mapValues { topic in
            Set(topic.values.compactMap(\.blobRef))
        }
    }

    static func backendError(statusCode: HTTPStatusCode) -> BackendError {
        return .networkError(.errorResponse(
            .init(code: .unknownError, originalCode: BackendErrorCode.unknownError.rawValue),
            statusCode
        ))
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

    static func compressedContainer(
        config: String,
        configEncoding: RCContainer.Element.ContentEncoding = .none,
        contentElements: [(payload: Data, encoding: RCContainer.Element.ContentEncoding)] = []
    ) throws -> RemoteConfigContainer {
        return try RemoteConfigContainer(data: RCContainerTestData.compressedContainer(
            config: config.asData,
            configEncoding: configEncoding,
            contentElements: contentElements
        ))
    }

    func waitForRemoteConfigRequestCount(
        _ count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if self.remoteConfigAPI.invokedGetRemoteConfigCount >= count {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for \(count) remote config requests", file: file, line: line)
    }

    func waitForDiskCacheReadCount(
        _ count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if self.diskCache.invokedReadCount >= count {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for \(count) disk cache reads", file: file, line: line)
    }

    struct WorkflowPayload: Decodable, Equatable {
        let id: String
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
    private(set) var invokedGetRemoteConfigParametersList: [(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool
    )] = []

    private var completions: [Backend.ResponseHandler<RemoteConfigFetchResult>] = []

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFetchResult>
    ) {
        self.invokedGetRemoteConfigCount += 1
        self.invokedGetRemoteConfigParameters = (request, isAppBackgrounded)
        self.invokedGetRemoteConfigParametersList.append((request, isAppBackgrounded))
        self.completions.append(completion)
    }

    func complete(with result: Result<RemoteConfigFetchResult, BackendError>) {
        self.completions.last?(result)
    }

    func complete(
        at index: Int,
        with result: Result<RemoteConfigFetchResult, BackendError>
    ) {
        self.completions[index](result)
    }

}

private final class MockRemoteConfigDiskCache: RemoteConfigDiskCacheType {

    var stubbedRead: PersistedRemoteConfiguration?
    var stubbedWriteResult = true
    var readHandler: (() -> PersistedRemoteConfiguration?)?
    var writeHandler: ((PersistedRemoteConfiguration) -> Bool)?
    var clearHandler: (() -> Void)?

    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameter: PersistedRemoteConfiguration?
    private(set) var invokedReadCount = 0
    private(set) var invokedClearCount = 0

    func read() -> PersistedRemoteConfiguration? {
        self.invokedReadCount += 1
        return self.readHandler?() ?? self.stubbedRead
    }

    func topic(_ topic: RemoteConfigTopic) -> RemoteConfiguration.ConfigTopic? {
        return self.read()?.topics.entries[topic.wireName]
    }

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool {
        self.invokedWriteCount += 1
        self.invokedWriteParameter = configuration

        return self.writeHandler?(configuration) ?? self.stubbedWriteResult
    }

    func clear() {
        self.invokedClearCount += 1
        self.clearHandler?()
    }

}

private final class MockRemoteConfigBlobStore: RemoteConfigBlobStoreType {

    var stubbedContainsRefs: Set<String> = []
    var stubbedReadDataByRef: [String: Data] = [:]

    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameters: (ref: String, data: Data)?
    private(set) var invokedWriteParametersList: [(ref: String, data: Data)] = []
    private(set) var invokedReadRefs: [String] = []
    private(set) var invokedCachedRefsCount = 0
    private(set) var invokedRetainOnlyCount = 0
    private(set) var invokedRetainOnlyParameters: Set<String>?
    private(set) var invokedClearCount = 0

    func contains(ref: String) -> Bool {
        return self.stubbedContainsRefs.contains(ref)
    }

    func read(ref: String) -> Data? {
        self.invokedReadRefs.append(ref)
        if let data = self.stubbedReadDataByRef[ref] {
            return data
        }

        return self.invokedWriteParametersList.last { $0.ref == ref }?.data
    }

    @discardableResult
    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool {
        self.invokedWriteCount += 1
        var data = Data()
        data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
        self.invokedWriteParameters = (ref, data)
        self.invokedWriteParametersList.append((ref, data))
        return true
    }

    func cachedRefs() -> Set<String> {
        self.invokedCachedRefsCount += 1
        return self.stubbedContainsRefs
    }

    func retainOnly(_ refs: Set<String>) {
        self.invokedRetainOnlyCount += 1
        self.invokedRetainOnlyParameters = refs
    }

    func clear() {
        self.invokedClearCount += 1
    }

}

private final class MockRemoteConfigBlobFetcher: RemoteConfigBlobFetcherType {

    var stubbedEnsureDownloadedResult = true

    private(set) var invokedEnsureDownloadedRefs: [String] = []
    private(set) var invokedEnsureAllDownloadedRefs: [String] = []
    private(set) var invokedPrefetchCount = 0
    private(set) var invokedPrefetchRefs: [String] = []

    func ensureDownloaded(ref: String) async -> Bool {
        self.invokedEnsureDownloadedRefs.append(ref)
        return self.stubbedEnsureDownloadedResult
    }

    func ensureAllDownloaded(refs: [String]) async -> Bool {
        self.invokedEnsureAllDownloadedRefs = refs
        return true
    }

    func prefetch(refs: [String]) {
        self.invokedPrefetchCount += 1
        self.invokedPrefetchRefs = refs
    }

}
