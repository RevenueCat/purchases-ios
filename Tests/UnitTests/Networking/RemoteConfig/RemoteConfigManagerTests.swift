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
    private static let refreshAttemptCooldownElapsedInterval: TimeInterval = 61

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

    func testRefreshRemoteConfigIfStaleSendsForegroundFetchContext() {
        // The first committed request is forced to `.appStart`, so prime it before asserting a `.foreground` refresh.
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        self.dateProvider.advance(by: 6)

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .foreground
    }

    func testRefreshRemoteConfigSendsPassedFetchContext() {
        // The first committed request is forced to `.appStart`, so prime it before asserting the passed context.
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .identityChange
    }

    func testFirstRefreshIsForcedToAppStartRegardlessOfRequestedContext() {
        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
    }

    func testFirstStaleRefreshIsForcedToAppStartRegardlessOfRequestedContext() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
    }

    func testOnlyTheFirstRefreshIsForcedToAppStart() {
        // First request forced to `.appStart`; the next committed request reports its own context.
        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .identityChange
    }

    func testRefreshKeepsForcingAppStartUntilARefreshSucceeds() {
        // A failed first refresh must not consume the forced `.appStart`, so the next attempt is forced too.
        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
        self.remoteConfigAPI.complete(with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1)))))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart

        // Once a refresh succeeds, the forcing stops and later refreshes report their own context.
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .identityChange
    }

    func testForcingStopsOnceA200ConfigIsPersisted() throws {
        self.diskCache.stubbedRead = nil
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": [],
          "topics": {}
        }
        """

        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
        self.remoteConfigAPI.complete(with: .success(.test(container: try Self.container(config: response))))

        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .identityChange
    }

    func testA200ThatFailsToParseKeepsForcingAppStart() throws {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
        // A 200 whose body fails to parse commits nothing, so the initial config is still not committed.
        self.remoteConfigAPI.complete(with: .success(.test(container: try Self.container(config: "{ not valid json"))))

        // The next refresh must still be forced to `.appStart`, since no config landed yet.
        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
    }

    func testForcingStopsOnceTheFallbackCommitsItsConfig() {
        self.diskCache.stubbedRead = nil
        let configuration = RemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.sources:etag",
            activeTopics: [],
            prefetchBlobs: [],
            topics: .init(entries: [:])
        )

        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart

        // The main request fails on a cold cache, routing to the fallback, which commits its config.
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        self.remoteConfigAPI.completeFallback(with: .success(.test(configuration: configuration)))

        // The fallback commit counts as the initial config, so later refreshes report their own context.
        self.manager.refreshRemoteConfig(fetchContext: .identityChange, isAppBackgrounded: false)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .identityChange
    }

    func testIsDisabledDefaultsToFalse() {
        expect(self.manager.isDisabled) == false
    }

    func testRefreshRemoteConfigIfStaleRefreshesWhenNeverRefreshed() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testNoContentResponseMarksRefreshAsFresh() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testFreshRefreshDoesNotStartAnotherRequest() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testFailureDoesNotMarkRefreshAsFresh() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1)))))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.dateProvider.advance(by: Self.refreshAttemptCooldownElapsedInterval)
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testForcedRefreshBypassesFailureCooldown() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1)))))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testRefreshRemoteConfigIfStaleUsesForegroundAndBackgroundDurations() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        self.dateProvider.advance(by: 6)
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.dateProvider.advance(by: Self.refreshAttemptCooldownElapsedInterval)
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testClearCacheClearsRefreshAttemptCooldown() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1)))))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.manager.clearCache(forAppUserID: Self.appUserID)
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testClosePreventsNewRefreshes() {
        self.manager.close()

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == Self.appUserID
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .appStart
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == Self.appUserID
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.domain) == "custom"
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest) == persistedManifest
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs) == ["prefetchedBlob"]
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == true
    }

    func testOverlappingRefreshesAreIgnoredUntilInFlightRefreshCompletes() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

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
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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
            await self.manager.topic(.sources)?["api"]?.content["url"]
        }
        await self.waitForRemoteConfigRequestCount(1)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == false
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let apiURL = await task.value
        expect(apiURL) == AnyDecodable.string("https://api.revenuecat.com")
    }

    func testTopicMissingAfterFreshRefreshDoesNotTriggerAnotherRefresh() async throws {
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

        let firstRead = Task {
            await self.manager.topic(.workflows) == nil
        }
        await self.waitForRemoteConfigRequestCount(1)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let didMissTopic = await firstRead.value
        expect(didMissTopic) == true

        let secondRead = await self.manager.topic(.workflows)

        expect(secondRead).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testTopicColdReadFailureUsesFailureCooldown() async {
        let firstRead = Task {
            await self.manager.topic(.sources)
        }
        await self.waitForRemoteConfigRequestCount(1)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        let firstTopic = await firstRead.value
        expect(firstTopic).to(beNil())

        let secondTopic = await self.manager.topic(.sources)

        expect(secondTopic).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.dateProvider.advance(by: Self.refreshAttemptCooldownElapsedInterval)
        let thirdRead = Task {
            await self.manager.topic(.sources)
        }
        await self.waitForRemoteConfigRequestCount(2)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        let thirdTopic = await thirdRead.value
        expect(thirdTopic).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        let task = Task {
            await self.manager.topic(.sources)?["api"]?.content["url"]
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let apiURL = await task.value
        expect(apiURL) == AnyDecodable.string("https://api.revenuecat.com")
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testTopicReturnsNilWhenRemoteConfigIsDisabledEvenWithCachedTopic() async {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: [
                "sources": ["api": .init(content: ["url": "https://api.revenuecat.com"])]
            ])
        )
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

    func testEnsureBlobsDownloadedDelegatesToBlobFetcher() async {
        let refs = ["ref-1", "ref-2"]

        let result = await self.manager.ensureBlobsDownloaded(refs)

        expect(result) == true
        expect(self.blobFetcher.invokedEnsureAllDownloadedRefs) == refs
    }

    func testAwaitTopicReadyWaitsOnlyForPrefetchFlaggedBlobs() async throws {
        let prefetchRef = RCContainerTestData.blobRef(for: #"{"id":"wf-1"}"#.asData)
        let onDemandRef = RCContainerTestData.blobRef(for: #"{"id":"wf-2"}"#.asData)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: [
                "workflows": [
                    "wf-1": .init(blobRef: prefetchRef, prefetch: true),
                    "wf-2": .init(blobRef: onDemandRef, prefetch: false)
                ]
            ])
        )

        let maybeTopic = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows)
        let topic = try XCTUnwrap(maybeTopic)

        expect(topic["wf-1"]?.blobRef) == prefetchRef
        expect(topic["wf-2"]?.blobRef) == onDemandRef
        expect(self.blobFetcher.invokedEnsureAllDownloadedRefs) == [prefetchRef]
    }

    func testAwaitTopicReadyRetriesWhenTopicChangesWhileWaitingOnBlobs() async throws {
        let firstRef = RCContainerTestData.blobRef(for: #"{"id":"wf-1"}"#.asData)
        let secondRef = RCContainerTestData.blobRef(for: #"{"id":"wf-2"}"#.asData)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf-1": .init(blobRef: firstRef, prefetch: true)]])
        )

        // Simulate the topic being invalidated and refetched (e.g. an identity change) while the
        // first blob wait is in flight, by swapping the disk cache's content only on that first
        // call. The retry's own wait then settles on the new topic's own prefetch refs.
        self.blobFetcher.ensureAllDownloadedHandler = { _ in
            guard self.blobFetcher.invokedEnsureAllDownloadedCount == 1 else { return }
            self.diskCache.stubbedRead = Self.persisted(
                manifest: "v1.1710000100.workflows:etag2",
                topics: .init(entries: ["workflows": ["wf-2": .init(blobRef: secondRef, prefetch: true)]])
            )
        }

        let maybeTopic = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows)
        let topic = try XCTUnwrap(maybeTopic)

        expect(topic["wf-2"]?.blobRef) == secondRef
        expect(topic["wf-1"]).to(beNil())
        expect(self.blobFetcher.invokedEnsureAllDownloadedCount) == 2
        expect(self.blobFetcher.invokedEnsureAllDownloadedRefs) == [secondRef]
    }

    func testAwaitTopicReadyReturnsNilWhenTopicUnavailable() async {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf-1": .init(blobRef: "wf-1-ref", prefetch: true)]])
        )
        self.manager.close()

        let topic = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows)

        expect(topic).to(beNil())
        expect(self.blobFetcher.invokedEnsureAllDownloadedRefs).to(beEmpty())
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

    func testMergeItemsBlobDataMergesBlobJSONUnderItemKeys() async throws {
        let appBlob = #"{"enabled": true}"#.asData
        let localizationsBlob = #"{"en_US": {"day": "Day"}}"#.asData
        let variableConfigBlob = """
        {
          "title": "string"
        }
        """.asData
        let customVariablesBlob = #"{"user_name": {"type": "string", "default_value": "Friend"}}"#.asData
        let appRef = RCContainerTestData.blobRef(for: appBlob)
        let localizationsRef = RCContainerTestData.blobRef(for: localizationsBlob)
        let variableConfigRef = RCContainerTestData.blobRef(for: variableConfigBlob)
        let customVariablesRef = RCContainerTestData.blobRef(for: customVariablesBlob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.ui_config:etag1",
            topics: .init(entries: [
                "ui_config": [
                    "app": .init(blobRef: appRef),
                    "localizations": .init(blobRef: localizationsRef),
                    "variable_config": .init(blobRef: variableConfigRef),
                    "custom_variables": .init(blobRef: customVariablesRef)
                ]
            ])
        )
        self.blobStore.stubbedReadDataByRef[appRef] = appBlob
        self.blobStore.stubbedReadDataByRef[localizationsRef] = localizationsBlob
        self.blobStore.stubbedReadDataByRef[variableConfigRef] = variableConfigBlob
        self.blobStore.stubbedReadDataByRef[customVariablesRef] = customVariablesBlob

        let value = try await self.manager.mergeItemsBlobData(
            for: .uiConfig,
            itemKeys: ["app", "localizations", "variable_config", "custom_variables"],
            as: MergedUiConfigLikePayload.self
        )

        expect(value?.app.enabled) == true
        expect(value?.localizations["en_US"]?["day"]) == "Day"
        expect(value?.variableConfig.title) == "string"
        expect(value?.customVariables["user_name"]?.type) == "string"
        expect(value?.customVariables["user_name"]?.defaultValue) == "Friend"
    }

    func testMergeItemsBlobDataUsesItemKeyAsDecodedPropertyName() async throws {
        let blob = #"{"value":"favorite"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: [
                "workflows": ["favorite_workflow": .init(blobRef: ref)]
            ])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["favorite_workflow"],
            as: MergedSnakeCaseWorkflowPayload.self
        )

        expect(value) == MergedSnakeCaseWorkflowPayload(favoriteWorkflow: .init(value: "favorite"))
    }

    func testMergeItemsBlobDataPreservesComplexNestedJSONValues() async throws {
        let firstBlob = """
        {
          "metadata": {
            "title": "Welcome",
            "enabled": true,
            "ratio": 0.75,
            "priority": 2,
            "tags": ["paywall", "experiment"],
            "steps": [
              {
                "id": "intro",
                "conditions": {
                  "countries": ["US", "NL"],
                  "minimum_version": 3
                }
              }
            ]
          }
        }
        """.asData
        let secondBlob = """
        {
          "flags": {
            "show_debug": false,
            "optional_value": null
          },
          "variants": [
            { "id": "control", "weight": 0.4 },
            { "id": "treatment", "weight": 0.6 }
          ]
        }
        """.asData
        let firstRef = RCContainerTestData.blobRef(for: firstBlob)
        let secondRef = RCContainerTestData.blobRef(for: secondBlob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: [
                "workflows": [
                    "wf1": .init(blobRef: firstRef),
                    "wf2": .init(blobRef: secondRef)
                ]
            ])
        )
        self.blobStore.stubbedReadDataByRef[firstRef] = firstBlob
        self.blobStore.stubbedReadDataByRef[secondRef] = secondBlob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1", "wf2"],
            as: MergedComplexPayload.self
        )

        expect(value?.wf1.metadata.title) == "Welcome"
        expect(value?.wf1.metadata.enabled) == true
        expect(value?.wf1.metadata.ratio) == 0.75
        expect(value?.wf1.metadata.priority) == 2
        expect(value?.wf1.metadata.tags) == ["paywall", "experiment"]
        expect(value?.wf1.metadata.steps.first?.conditions.countries) == ["US", "NL"]
        expect(value?.wf1.metadata.steps.first?.conditions.minimumVersion) == 3
        expect(value?.wf2.flags.showDebug) == false
        expect(value?.wf2.flags.optionalValue).to(beNil())
        expect(value?.wf2.variants.map(\.id)) == ["control", "treatment"]
        expect(value?.wf2.variants.map(\.weight)) == [0.4, 0.6]
    }

    func testMergeItemsBlobDataDeduplicatesItemKeysPreservingFirstOccurrence() async throws {
        let blob = #"{"value":"one"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1", "wf1"],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value) == SingleMergedWorkflowPayload(wf1: .init(value: "one"))
        expect(self.blobFetcher.invokedEnsureDownloadedRefs) == [ref]
        expect(self.blobStore.invokedReadRefs) == [ref]
    }

    func testMergeItemsBlobDataReturnsNilForEmptyItemKeysWithoutRefreshingOrReadingBlobs() async throws {
        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: [],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 0
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
        self.logger.verifyMessageWasLogged(
            Strings.remoteConfig.mergeItemsBlobDataEmpty(topic: .workflows),
            level: .warn
        )
    }

    func testMergeItemsBlobDataReturnsNilForEmptyItemKeysWhenRemoteConfigIsDisabledWithoutReadingBlobs() async throws {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: [],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
        self.logger.verifyMessageWasLogged(
            Strings.remoteConfig.mergeItemsBlobDataDisabled(topic: .workflows, itemKeys: []),
            level: .warn
        )
        self.logger.verifyMessageWasNotLogged(
            Strings.remoteConfig.mergeItemsBlobDataEmpty(topic: .workflows),
            allowNoMessages: false
        )
    }

    func testMergeItemsBlobDataReturnsNilWhenItemIsMissingAfterRefresh() async throws {
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
              "other": {}
            }
          }
        }
        """

        let task = Task {
            try await self.manager.mergeItemsBlobData(
                for: .workflows,
                itemKeys: ["wf1"],
                as: SingleMergedWorkflowPayload.self
            )
        }
        await self.waitForRemoteConfigRequestCount(1)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let value = try await task.value
        expect(value).to(beNil())
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        self.logger.verifyMessageWasLogged(
            Strings.remoteConfig.mergeItemsBlobDataUnavailableItems(topic: .workflows, itemKeys: ["wf1"]),
            level: .warn
        )
    }

    func testMergeItemsBlobDataReturnsNilWhenItemHasNoBlobRef() async throws {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(content: ["id": "inline"])]])
        )

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1"],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value).to(beNil())
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        self.logger.verifyMessageWasLogged(
            Strings.remoteConfig.mergeItemsBlobDataUnavailableItems(topic: .workflows, itemKeys: ["wf1"]),
            level: .warn
        )
    }

    func testMergeItemsBlobDataReturnsNilWhenBlobDownloadFails() async throws {
        let blob = #"{"value":"one"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(blobRef: ref)]])
        )
        self.blobFetcher.stubbedEnsureDownloadedResult = false

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1"],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value).to(beNil())
        expect(self.blobFetcher.invokedEnsureDownloadedRefs) == [ref]
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
        self.logger.verifyMessageWasLogged(
            Strings.remoteConfig.mergeItemsBlobDataUnavailableItems(topic: .workflows, itemKeys: ["wf1"]),
            level: .warn
        )
    }

    func testMergeItemsBlobDataReturnsNilWhenBlobReadFails() async throws {
        let blob = #"{"value":"one"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(blobRef: ref)]])
        )

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1"],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value).to(beNil())
        expect(self.blobFetcher.invokedEnsureDownloadedRefs) == [ref]
        expect(self.blobStore.invokedReadRefs) == [ref]
        self.logger.verifyMessageWasLogged(
            Strings.remoteConfig.mergeItemsBlobDataUnavailableItems(topic: .workflows, itemKeys: ["wf1"]),
            level: .warn
        )
    }

    func testMergeItemsBlobDataColdReadTriggersSingleForegroundRefresh() async throws {
        let firstBlob = #"{"value":"one"}"#.asData
        let secondBlob = #"{"value":"two"}"#.asData
        let firstRef = RCContainerTestData.blobRef(for: firstBlob)
        let secondRef = RCContainerTestData.blobRef(for: secondBlob)
        self.diskCache.writeHandler = { configuration in
            self.diskCache.stubbedRead = configuration
            return true
        }
        self.blobStore.stubbedReadDataByRef[firstRef] = firstBlob
        self.blobStore.stubbedReadDataByRef[secondRef] = secondBlob
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.workflows:etag2",
          "active_topics": ["workflows"],
          "topics": {
            "workflows": {
              "wf1": { "blob_ref": "\(firstRef)" },
              "wf2": { "blob_ref": "\(secondRef)" }
            }
          }
        }
        """

        let task = Task {
            try await self.manager.mergeItemsBlobData(
                for: .workflows,
                itemKeys: ["wf1", "wf2"],
                as: MergedWorkflowPayload.self
            )
        }
        await self.waitForRemoteConfigRequestCount(1)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == false
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let value = try await task.value
        expect(value) == MergedWorkflowPayload(wf1: .init(value: "one"), wf2: .init(value: "two"))
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
    }

    func testMergeItemsBlobDataReturnsNilWhenRemoteConfigIsDisabledWithoutReadingBlobs() async throws {
        let blob = #"{"value":"one"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1"],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value).to(beNil())
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
        self.logger.verifyMessageWasLogged(
            Strings.remoteConfig.mergeItemsBlobDataDisabled(topic: .workflows, itemKeys: ["wf1"]),
            level: .warn
        )
    }

    func testMergeItemsBlobDataThrowsWhenBlobDataIsNotValidJSON() async throws {
        let blob = "{ invalid json".asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob

        do {
            _ = try await self.manager.mergeItemsBlobData(
                for: .workflows,
                itemKeys: ["wf1"],
                as: SingleMergedWorkflowPayload.self
            )
            fail("Expected decoding to fail")
        } catch {
            expect(error).toNot(beNil())
        }
    }

    func testMergeItemsBlobDataThrowsWhenMergedObjectCannotDecode() async throws {
        let blob = #"{"value":1}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob

        do {
            _ = try await self.manager.mergeItemsBlobData(
                for: .workflows,
                itemKeys: ["wf1"],
                as: SingleMergedWorkflowPayload.self
            )
            fail("Expected decoding to fail")
        } catch {
            expect(error).toNot(beNil())
        }
    }

    func testMergeItemsBlobDataSupportsNonObjectJSONValues() async throws {
        let stringBlob = #""hello""#.asData
        let intBlob = "42".asData
        let stringRef = RCContainerTestData.blobRef(for: stringBlob)
        let intRef = RCContainerTestData.blobRef(for: intBlob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: [
                "workflows": [
                    "wf1": .init(blobRef: stringRef),
                    "wf2": .init(blobRef: intRef)
                ]
            ])
        )
        self.blobStore.stubbedReadDataByRef[stringRef] = stringBlob
        self.blobStore.stubbedReadDataByRef[intRef] = intBlob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1", "wf2"],
            as: MergedPrimitivePayload.self
        )

        expect(value) == MergedPrimitivePayload(wf1: "hello", wf2: 42)
    }

    func testMergeItemsBlobDataEscapesItemKeysRequiringJSONEscaping() async throws {
        struct MergedEscapedKeyPayload: Decodable, Equatable {
            let escapedKey: MergedSection

            // swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case escapedKey = #"weird"key\slash{brace},colon:end"#
            }
        }

        let blob = #"{"value":"escaped"}"#.asData
        let itemKey = #"weird"key\slash{brace},colon:end"#
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": [itemKey: .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: [itemKey],
            as: MergedEscapedKeyPayload.self
        )

        expect(value) == MergedEscapedKeyPayload(escapedKey: .init(value: "escaped"))
    }

    func testMergeItemsBlobDataSupportsUnicodeItemKeys() async throws {
        struct MergedUnicodeKeyPayload: Decodable, Equatable {
            let unicodeKey: MergedSection

            // swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case unicodeKey = "日本語🎉café"
            }
        }

        let blob = #"{"value":"unicode"}"#.asData
        let itemKey = "日本語🎉café"
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": [itemKey: .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: [itemKey],
            as: MergedUnicodeKeyPayload.self
        )

        expect(value) == MergedUnicodeKeyPayload(unicodeKey: .init(value: "unicode"))
    }

    func testMergeItemsBlobDataAcceptsBlobsWithSurroundingWhitespace() async throws {
        let blob = "\n   {\"value\":\"spaced\"}   \n".asData
        let ref = RCContainerTestData.blobRef(for: blob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: ["workflows": ["wf1": .init(blobRef: ref)]])
        )
        self.blobStore.stubbedReadDataByRef[ref] = blob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1"],
            as: SingleMergedWorkflowPayload.self
        )

        expect(value) == SingleMergedWorkflowPayload(wf1: .init(value: "spaced"))
    }

    func testMergeItemsBlobDataMergesMultipleKeysAndBlobs() async throws {
        struct MergedMultiPayload: Decodable, Equatable {
            let wf1: MergedSection
            let wf2: MergedSection
            let wf3: MergedSection
        }

        let firstBlob = #"{"value":"one"}"#.asData
        let secondBlob = #"{"value":"two"}"#.asData
        let thirdBlob = #"{"value":"three"}"#.asData
        let firstRef = RCContainerTestData.blobRef(for: firstBlob)
        let secondRef = RCContainerTestData.blobRef(for: secondBlob)
        let thirdRef = RCContainerTestData.blobRef(for: thirdBlob)
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: [
                "workflows": [
                    "wf1": .init(blobRef: firstRef),
                    "wf2": .init(blobRef: secondRef),
                    "wf3": .init(blobRef: thirdRef)
                ]
            ])
        )
        self.blobStore.stubbedReadDataByRef[firstRef] = firstBlob
        self.blobStore.stubbedReadDataByRef[secondRef] = secondBlob
        self.blobStore.stubbedReadDataByRef[thirdRef] = thirdBlob

        let value = try await self.manager.mergeItemsBlobData(
            for: .workflows,
            itemKeys: ["wf1", "wf2", "wf3"],
            as: MergedMultiPayload.self
        )

        expect(value) == MergedMultiPayload(
            wf1: .init(value: "one"),
            wf2: .init(value: "two"),
            wf3: .init(value: "three")
        )
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": ["newSources"]]
        expect(self.blobStore.invokedRetainOnlyParameters) == Set(["newSources"])
    }

    func testContainerResponsePrunesBlobRefsForItemsDroppedFromChangedTopic() throws {
        let keptRef = "keptBlob"
        let removedRef = "removedBlob"
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.workflows:etag1",
            topics: .init(entries: [
                "workflows": [
                    "kept": .init(blobRef: keptRef),
                    "removed": .init(blobRef: removedRef)
                ]
            ])
        )
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.workflows:etag2",
          "active_topics": ["workflows"],
          "topics": {
            "workflows": {
              "kept": { "blob_ref": "\(keptRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let workflows = try XCTUnwrap(self.diskCache.invokedWriteParameter?.topics.entries["workflows"])
        expect(Set(workflows.keys)) == Set(["kept"])
        expect(workflows["kept"]?.blobRef) == keptRef
        expect(workflows["removed"]).to(beNil())
        expect(self.blobStore.invokedRetainOnlyParameters) == Set([keptRef])
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testNoContentResponseWithNoPersistedCacheLeavesCacheUntouched() {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testMalformedTopicItemLeavesCacheUntouchedAndReleasesRefreshGuard() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "api": "not-an-object"
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
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
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .invalidRequest)))
        expect(self.manager.isDisabled) == true
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedReadCount) == 1
        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testFourHundredResponseNotifiesWhenRemoteConfigIsDisabled() {
        var disabledCallbackCount = 0
        self.manager.onRemoteConfigDisabled = { disabledCallbackCount += 1 }

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .invalidRequest)))

        expect(disabledCallbackCount) == 1

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        expect(disabledCallbackCount) == 1
    }

    func testTooManyRequestsResponseDisablesRemoteConfig() {
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .tooManyRequests)))
        expect(self.manager.isDisabled) == true
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedReadCount) == 1
    }

    func testServerErrorDoesNotDisableRemoteConfig() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedReadCount) == 2
    }

    func testFallbackClientErrorDisablesRemoteConfig() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .invalidRequest)))
        expect(self.manager.isDisabled) == true

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigFallbackCount) == 1
        expect(self.diskCache.invokedReadCount) == 1
    }

    func testPrimaryServerErrorTriggersFallbackConfigRequest() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))

        expect(self.remoteConfigAPI.invokedGetRemoteConfigFallbackCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigFallbackParameters?.domain) == "app"
        expect(self.remoteConfigAPI.invokedGetRemoteConfigFallbackParameters?.isAppBackgrounded) == true
    }

    func testPrimaryServerErrorWithPersistedCacheDoesNotTriggerFallbackConfigRequest() {
        self.diskCache.stubbedRead = Self.persisted(domain: "app", manifest: "cached-manifest")

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))

        expect(self.manager.isDisabled) == false
        expect(self.remoteConfigAPI.invokedGetRemoteConfigFallbackCount) == 0
        expect(self.diskCache.invokedWriteCount) == 0
    }

    func testPrimaryServerErrorWithProxyURLDoesNotTriggerFallbackConfigRequest() throws {
        SystemInfo.proxyURL = try XCTUnwrap(URL(string: "https://proxy.revenuecat.com"))
        defer { SystemInfo.proxyURL = nil }

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))

        expect(self.manager.isDisabled) == false
        expect(self.remoteConfigAPI.invokedGetRemoteConfigFallbackCount) == 0
        expect(self.diskCache.invokedWriteCount) == 0
    }

    func testPrimaryClientErrorDisablesRemoteConfigAndDoesNotTriggerFallbackConfigRequest() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))

        expect(self.manager.isDisabled) == true
        expect(self.remoteConfigAPI.invokedGetRemoteConfigFallbackCount) == 0
    }

    func testFallbackConfigSuccessPersistsConfigurationWithoutInlineBlobExtraction() {
        let prefetchedRef = RCContainerTestData.blobRef(for: #"{"id":"prefetched"}"#.asData)
        let retainedRef = RCContainerTestData.blobRef(for: #"{"id":"retained"}"#.asData)
        let configuration = RemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.workflows:etag2",
            activeTopics: ["workflows"],
            prefetchBlobs: [prefetchedRef],
            topics: .init(entries: [
                "workflows": ["default": .init(blobRef: retainedRef)]
            ])
        )

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        self.remoteConfigAPI.completeFallback(with: .success(.test(configuration: configuration)))

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedWriteParameter?.manifest) == "v1.1710000100.workflows:etag2"
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == [
            "workflows": [retainedRef]
        ]
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyParameters) == Set([prefetchedRef, retainedRef])
        expect(self.blobFetcher.invokedPrefetchRefs) == [prefetchedRef]
    }

    func testFallbackConfigFailureLeavesCacheUntouchedAndDoesNotMarkRefreshFresh() {
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .internalServerError)))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.dateProvider.advance(by: Self.refreshAttemptCooldownElapsedInterval)
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testTransportNetworkErrorDoesNotDisableRemoteConfig() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedReadCount) == 2
    }

    func testClearCacheDoesNotReenableDisabledRemoteConfigRefresh() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .failure(Self.backendError(statusCode: .forbidden)))
        expect(self.manager.isDisabled) == true
        self.manager.clearCache(forAppUserID: Self.appUserID)
        expect(self.manager.isDisabled) == true
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobStore.invokedClearCount) == 1
    }

    func testMalformedConfigPayloadLeavesCacheUntouched() throws {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        // The first committed request is forced to `.appStart`, so prime it before asserting the cold read's `.read`.
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        self.dateProvider.advance(by: 6)

        let task = Task {
            await self.manager.blobData(for: .workflows, itemKey: "default")
        }
        await self.waitForRemoteConfigRequestCount(2)
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == false
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.fetchContext) == .read
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let maybeData = await task.value
        let data = try XCTUnwrap(maybeData)
        expect(data) == blob
    }

    func testBlobDataMissingItemAfterFreshRefreshDoesNotTriggerAnotherRefresh() async throws {
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
              "other": { "one": 1 }
            }
          }
        }
        """

        let firstRead = Task {
            await self.manager.blobData(for: .workflows, itemKey: "default")
        }
        await self.waitForRemoteConfigRequestCount(1)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let firstData = await firstRead.value
        expect(firstData).to(beNil())

        let secondRead = await self.manager.blobData(for: .workflows, itemKey: "default")

        expect(secondRead).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
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

    func testBlobDataColdReadAfterIdentityClearUsesBoundAppUserIDWhenTriggeringRefresh() async {
        self.currentUserProvider.mockAppUserID = "old-user"
        self.manager.clearCache(forAppUserID: "new-user")

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        _ = await task.value

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == "new-user"
    }

    func testBlobDataColdReadUsesBoundAppUserIDIfIdentityClearRacesCurrentUserRead() async {
        self.currentUserProvider.mockAppUserID = "old-user"
        self.currentUserProvider.currentAppUserIDRequested = { [manager] in
            manager?.clearCache(forAppUserID: "new-user")
        }

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        _ = await task.value

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == "new-user"
    }

    func testRefreshUsesBoundAppUserIDIfIdentityClearRacesRefreshPreparation() {
        self.manager.clearCache(forAppUserID: "new-user")

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == "new-user"
    }

    func testBlobDataNoContentRefreshCompletesWaitingRead() async {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

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
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.remoteConfigAPI.complete(with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1)))))
        self.remoteConfigAPI.completeFallback(with: .failure(Self.backendError(statusCode: .internalServerError)))

        let data = await task.value
        expect(data).to(beNil())
    }

    func testBlobDataMalformedRefreshCompletesWaitingRead() async throws {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

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
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        let task = Task {
            await self.manager.blobData(for: .sources, itemKey: "api")
        }
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForDiskCacheReadCount(2)
        self.manager.clearCache(forAppUserID: Self.appUserID)

        let data = await task.value
        expect(data).to(beNil())
    }

    func testTopicDoesNotReturnStaleReadWhenCacheIsClearedDuringRead() async {
        var didClearDuringRead = false
        self.diskCache.readHandler = {
            if !didClearDuringRead {
                didClearDuringRead = true
                self.manager.clearCache(forAppUserID: Self.appUserID)
            }

            return Self.persisted(
                manifest: "v1.1710000100.sources:etag1",
                topics: .init(entries: ["sources": ["api": .init(content: ["url": .string("stale")])]])
            )
        }

        let topic = await self.manager.topic(.sources)

        expect(topic).to(beNil())
        expect(self.diskCache.invokedClearCount) == 1
    }

    func testBlobDataDoesNotFetchStaleItemWhenCacheIsClearedDuringRead() async {
        let ref = RCContainerTestData.blobRef(for: #"{"id":"workflow"}"#.asData)
        var didClearDuringRead = false
        self.diskCache.readHandler = {
            if !didClearDuringRead {
                didClearDuringRead = true
                self.manager.clearCache(forAppUserID: Self.appUserID)
            }

            return Self.persisted(
                manifest: "v1.1710000100.workflows:etag1",
                topics: .init(entries: ["workflows": ["default": .init(blobRef: ref)]])
            )
        }

        let data = await self.manager.blobData(for: .workflows, itemKey: "default")

        expect(data).to(beNil())
        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobFetcher.invokedEnsureDownloadedRefs).to(beEmpty())
        expect(self.blobStore.invokedReadRefs).to(beEmpty())
    }

    func testBlobDataCloseCompletesWaitingRead() async {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

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
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.blobFetcher.invokedPrefetchRefs) == [cachedRef, missingRef]
    }

    func testContainerResponsePrefetchesItemLevelPrefetchBlobRefs() throws {
        let serverPrefetchRef = RCContainerTestData.blobRef(for: "server prefetch".asData)
        let itemPrefetchRef = RCContainerTestData.blobRef(for: "item prefetch".asData)
        let itemOnDemandRef = RCContainerTestData.blobRef(for: "item on demand".asData)
        let cachedItemPrefetchRef = RCContainerTestData.blobRef(for: "cached item prefetch".asData)
        self.blobStore.stubbedContainsRefs = [cachedItemPrefetchRef]
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.workflows:etag2",
          "active_topics": ["workflows"],
          "prefetch_blobs": ["\(serverPrefetchRef)"],
          "topics": {
            "workflows": {
              "wf-1": { "blob_ref": "\(itemPrefetchRef)", "prefetch": true },
              "wf-2": { "blob_ref": "\(itemOnDemandRef)", "prefetch": false },
              "wf-3": { "blob_ref": "\(cachedItemPrefetchRef)", "prefetch": true },
              "wf-4": { "prefetch": true },
              "wf-5": { "blob_ref": "\(serverPrefetchRef)", "prefetch": true }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.blobFetcher.invokedPrefetchRefs) == [serverPrefetchRef, itemPrefetchRef]
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.dateProvider.advance(by: Self.refreshAttemptCooldownElapsedInterval)
        self.manager.refreshRemoteConfigIfStale(fetchContext: .foreground, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
    }

    func testClearCacheWipesDiskCacheAndBlobStore() {
        self.manager.clearCache(forAppUserID: Self.appUserID)

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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.manager.clearCache(forAppUserID: Self.appUserID)
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
            manager?.clearCache(forAppUserID: Self.appUserID)
            return nil
        }

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 0
        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobStore.invokedClearCount) == 1
    }

    func testStaleNoContentResponseDoesNotReleaseNewerRefreshGuard() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.manager.clearCache(forAppUserID: Self.appUserID)
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

        self.remoteConfigAPI.complete(at: 0, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.manager.clearCache(forAppUserID: Self.appUserID)
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

        self.remoteConfigAPI.complete(
            at: 0,
            with: .success(.test(container: try Self.container(config: response)))
        )
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedWriteCount) == 0

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testStaleErrorResponseDoesNotReleaseNewerRefreshGuard() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.manager.clearCache(forAppUserID: Self.appUserID)
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

        self.remoteConfigAPI.complete(
            at: 0,
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testStaleFourHundredResponseDoesNotDisableRemoteConfig() {
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        self.manager.clearCache(forAppUserID: Self.appUserID)
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: true)

        self.remoteConfigAPI.complete(at: 0, with: .failure(Self.backendError(statusCode: .invalidRequest)))
        expect(self.manager.isDisabled) == false
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)

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

        self.manager.clearCache(forAppUserID: Self.appUserID)
        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
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

        self.manager.refreshRemoteConfig(fetchContext: .appStart, isAppBackgrounded: false)
        DispatchQueue.global().async {
            self.remoteConfigAPI.complete(
                with: .success(.test(container: container))
            )
        }
        expect(writeStarted.wait(timeout: .now() + .seconds(5))) == .success

        DispatchQueue.global().async {
            self.manager.clearCache(forAppUserID: Self.appUserID)
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

    struct MergedSection: Decodable, Equatable {
        let value: String
    }

    struct MergedWorkflowPayload: Decodable, Equatable {
        let wf1: MergedSection
        let wf2: MergedSection
    }

    struct SingleMergedWorkflowPayload: Decodable, Equatable {
        let wf1: MergedSection
    }

    struct MergedSnakeCaseWorkflowPayload: Decodable, Equatable {
        let favoriteWorkflow: MergedSection
    }

    struct MergedPrimitivePayload: Decodable, Equatable {
        let wf1: String
        let wf2: Int
    }

    struct MergedComplexPayload: Decodable, Equatable {
        let wf1: ComplexFirstBlob
        let wf2: ComplexSecondBlob
    }

    struct ComplexFirstBlob: Decodable, Equatable {
        let metadata: ComplexMetadata
    }

    struct ComplexMetadata: Decodable, Equatable {
        let title: String
        let enabled: Bool
        let ratio: Double
        let priority: Int
        let tags: [String]
        let steps: [ComplexStep]
    }

    struct ComplexStep: Decodable, Equatable {
        let id: String
        let conditions: ComplexConditions
    }

    struct ComplexConditions: Decodable, Equatable {
        let countries: [String]
        let minimumVersion: Int
    }

    struct ComplexSecondBlob: Decodable, Equatable {
        let flags: ComplexFlags
        let variants: [ComplexVariant]
    }

    struct ComplexFlags: Decodable, Equatable {
        let showDebug: Bool
        let optionalValue: String?
    }

    struct ComplexVariant: Decodable, Equatable {
        let id: String
        let weight: Double
    }

    struct MergedUiConfigLikePayload: Decodable, Equatable {
        let app: MergedUiConfigLikeApp
        let localizations: [String: [String: String]]
        let variableConfig: MergedUiConfigLikeVariableConfig
        let customVariables: [String: MergedUiConfigLikeCustomVariable]
    }

    struct MergedUiConfigLikeApp: Decodable, Equatable {
        let enabled: Bool
    }

    struct MergedUiConfigLikeVariableConfig: Decodable, Equatable {
        let title: String
    }

    struct MergedUiConfigLikeCustomVariable: Decodable, Equatable {
        let type: String
        let defaultValue: String
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

private extension RemoteConfigFallbackFetchResult {

    static func test(
        configuration: RemoteConfiguration,
        verificationResult: VerificationResult = .verified
    ) -> RemoteConfigFallbackFetchResult {
        return RemoteConfigFallbackFetchResult(response: .init(
            httpStatusCode: .success,
            responseHeaders: [:],
            body: configuration,
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
    private(set) var invokedGetRemoteConfigFallbackCount = 0
    private(set) var invokedGetRemoteConfigFallbackParameters: (
        domain: String,
        isAppBackgrounded: Bool
    )?
    private(set) var invokedGetRemoteConfigFallbackParametersList: [(
        domain: String,
        isAppBackgrounded: Bool
    )] = []

    private var completions: [Backend.ResponseHandler<RemoteConfigFetchResult>] = []
    private var fallbackCompletions: [Backend.ResponseHandler<RemoteConfigFallbackFetchResult>] = []

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

    func getRemoteConfigFallback(
        domain: String,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFallbackFetchResult>
    ) {
        self.invokedGetRemoteConfigFallbackCount += 1
        self.invokedGetRemoteConfigFallbackParameters = (domain, isAppBackgrounded)
        self.invokedGetRemoteConfigFallbackParametersList.append((domain, isAppBackgrounded))
        self.fallbackCompletions.append(completion)
    }

    func complete(with result: Result<RemoteConfigFetchResult, BackendError>) {
        self.completions.last?(result)
    }

    func completeFallback(with result: Result<RemoteConfigFallbackFetchResult, BackendError>) {
        self.fallbackCompletions.last?(result)
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

    private let lock = Lock()
    private var _invokedEnsureDownloadedRefs: [String] = []
    private(set) var invokedEnsureAllDownloadedRefs: [String] = []
    private(set) var invokedPrefetchCount = 0
    private(set) var invokedPrefetchRefs: [String] = []

    var invokedEnsureDownloadedRefs: [String] {
        return self.lock.perform {
            self._invokedEnsureDownloadedRefs
        }
    }

    func ensureDownloaded(ref: String) async -> Bool {
        self.lock.perform {
            self._invokedEnsureDownloadedRefs.append(ref)
        }
        return self.stubbedEnsureDownloadedResult
    }

    var ensureAllDownloadedHandler: (([String]) -> Void)?
    private(set) var invokedEnsureAllDownloadedCount = 0

    func ensureAllDownloaded(refs: [String]) async -> Bool {
        self.invokedEnsureAllDownloadedCount += 1
        self.invokedEnsureAllDownloadedRefs = refs
        self.ensureAllDownloadedHandler?(refs)
        return true
    }

    func prefetch(refs: [String]) {
        self.invokedPrefetchCount += 1
        self.invokedPrefetchRefs = refs
    }

}
