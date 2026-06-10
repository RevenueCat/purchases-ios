//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowManagerTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class WorkflowManagerTests: TestCase {

    private let appUserID = "user_1"

    private var dateProvider: MockCurrentDateProvider!
    private var mockBackend: MockBackend!
    private var mockWorkflowsAPI: MockWorkflowsAPI!
    private var mockDeviceCache: MockDeviceCache!
    private var mockOperationDispatcher: MockOperationDispatcher!
    private var systemInfo: MockSystemInfo!
    private var workflowsCache: WorkflowsCache!
    private var manager: WorkflowManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.dateProvider = MockCurrentDateProvider()
        self.systemInfo = MockSystemInfo(finishTransactions: false)
        self.systemInfo.stubbedIsSandbox = false
        self.mockBackend = MockBackend()
        self.mockWorkflowsAPI = try XCTUnwrap(self.mockBackend.workflowsAPI as? MockWorkflowsAPI)
        self.mockDeviceCache = MockDeviceCache(systemInfo: self.systemInfo)
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.workflowsCache = WorkflowsCache(deviceCache: self.mockDeviceCache, dateProvider: self.dateProvider)
        self.manager = WorkflowManager(backend: self.mockBackend,
                                       workflowsCache: self.workflowsCache,
                                       paywallCache: nil,
                                       operationDispatcher: self.mockOperationDispatcher)
    }

    // MARK: - getWorkflow cache

    func testGetWorkflowCachesResultOnSuccess() throws {
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)

        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }

        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == expected
        // On-demand fetches stay on the serial queue (prefetch == false).
        expect(self.mockWorkflowsAPI.invokedGetWorkflowParameters?.prefetch) == false
    }

    func testGetWorkflowReturnsCachedResultWithoutCallingBackendWhenFresh() throws {
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)

        // First call populates the cache.
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }

        // Second call within TTL should hit the cache.
        var secondResult: WorkflowDataResult?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            secondResult = try? $0.get()
        }

        expect(secondResult) == expected
        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 1
    }

    func testGetWorkflowRefetchesWhenCacheIsStale() throws {
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)

        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }

        // Past the 5-minute foreground TTL.
        self.dateProvider.advance(by: 6 * 60)
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }

        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 2
    }

    func testGetWorkflowStaleHitServesCachedValueAndRefreshesInBackground() throws {
        // Stale-while-revalidate: a stale-but-present entry is served immediately and the cache is
        // refreshed in the background, mirroring how `OfferingsManager` vends a stale offerings cache.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true
        let stale = try Self.workflowDataResult(id: "stale")
        let refreshed = try Self.workflowDataResult(id: "refreshed")

        // First call populates the cache with the stale value.
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(stale))
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == stale

        // Past the 5-minute foreground TTL: the entry is now stale-but-present.
        self.dateProvider.advance(by: 6 * 60)

        var served: WorkflowDataResult?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            served = try? $0.get()
        }

        // The caller gets the stale cached value immediately, before the background refresh lands.
        expect(served) == stale
        // A background refresh was issued (second backend call).
        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 2

        // When the background refresh completes, it updates the cache to the fresh value.
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(refreshed))
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == refreshed
    }

    func testGetWorkflowStaleHitDoesNotSurfaceFailingBackgroundRefresh() throws {
        // The caller already has a usable value, so a failing background refresh is logged and
        // swallowed, never delivered as an error, and the stale value stays cached.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true
        let stale = try Self.workflowDataResult(id: "stale")

        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(stale))

        self.dateProvider.advance(by: 6 * 60)

        var served: WorkflowDataResult?
        var erroredWith: BackendError?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            switch $0 {
            case let .success(result): served = result
            case let .failure(error): erroredWith = error
            }
        }
        expect(served) == stale

        // The background refresh fails: not surfaced to the caller, and the cache keeps the stale value.
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .failure(.missingAppUserID()))
        expect(erroredWith).to(beNil())
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == stale
    }

    func testGetWorkflowStaleHitDropsBackgroundWriteWhenCacheClearedBeforeRefreshLands() throws {
        // The background refresh's write is guarded by the generation captured when the stale value was
        // served. If an identity change clears the cache before the refresh lands, the write is dropped,
        // so the previous user's (user-scoped) detail can't repopulate the new user's cache.
        //
        // Like the prefetch generation tests, this drives the guard directly: the true sub-statement
        // race (a clear landing between reading the cached value and capturing the generation) is the
        // same lock-free read window the workflows cache accepts by design and isn't deterministically
        // reproducible here.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true
        let stale = try Self.workflowDataResult(id: "stale")

        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(stale))

        self.dateProvider.advance(by: 6 * 60)

        // Stale hit: serves the cached value and stores the background refresh (capturing the generation).
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }

        // Identity change clears the cache (bumping the generation) before the refresh lands.
        self.workflowsCache.clearCache()

        // The background refresh now returns the previous user's detail: its write must be dropped.
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1",
                                                        with: .success(try Self.workflowDataResult(id: "refreshed")))
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    func testGetWorkflowStaleHitInvokesCallerCompletionExactlyOnce() throws {
        // The caller's completion fires once (with the stale value); the background refresh receives a
        // separate logging-only closure and never delivers to the caller again.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true
        let stale = try Self.workflowDataResult(id: "stale")

        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(stale))

        self.dateProvider.advance(by: 6 * 60)

        var completionCount = 0
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in
            completionCount += 1
        }
        expect(completionCount) == 1

        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1",
                                                        with: .success(try Self.workflowDataResult(id: "refreshed")))
        expect(completionCount) == 1
    }

    func testGetWorkflowWithStaleWhileRevalidateDisabledBlocksAndDeliversFreshValue() throws {
        // With stale-while-revalidate disabled, a stale-but-present entry must not be served: the
        // caller blocks until the refetch lands and receives the freshly fetched value.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true
        let stale = try Self.workflowDataResult(id: "stale")
        let refreshed = try Self.workflowDataResult(id: "refreshed")

        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false,
                                 staleWhileRevalidate: false) { _ in }
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(stale))

        self.dateProvider.advance(by: 6 * 60)

        var served: WorkflowDataResult?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false,
                                 staleWhileRevalidate: false) { served = try? $0.get() }

        // Nothing delivered yet: the call blocks on the refetch instead of serving the stale value.
        expect(served).to(beNil())

        // Once the refetch lands, the caller receives the freshly fetched value.
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(refreshed))
        expect(served) == refreshed
    }

    func testGetWorkflowForwardsBackendError() {
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .failure(.missingAppUserID())

        var error: BackendError?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            if case let .failure(failure) = $0 { error = failure }
        }

        expect(error).toNot(beNil())
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    // MARK: - getWorkflow fetch fallback

    func testGetWorkflowFallsBackToDiskDetailOnServerErrorAndDeliversSuccess() throws {
        // A 5xx is transient: recover the last persisted detail from disk, cache it fresh, and deliver it,
        // mirroring how offerings and the workflows list fall back on `shouldFallBackToCache`.
        let persisted = try Self.workflowDataResult(id: "wf_1")
        self.mockDeviceCache.stubbedCachedWorkflowDetails = ["wf_1": persisted]
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .failure(
            .networkError(.errorResponse(.init(code: .unknownError, originalCode: 0), .internalServerError))
        )

        var served: WorkflowDataResult?
        var erroredWith: BackendError?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            switch $0 {
            case let .success(result): served = result
            case let .failure(error): erroredWith = error
            }
        }

        expect(served) == persisted
        expect(erroredWith).to(beNil())
        // Recovered into memory and re-stamped fresh so the next call serves it without a refetch.
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == persisted
        expect(self.workflowsCache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == false
    }

    func testGetWorkflowDoesNotFallBackToDiskDetailOnClientError() throws {
        // A 4xx means the backend rejected the request (workflow removed/disabled), so the persisted
        // copy must not be served; the error surfaces instead.
        self.mockDeviceCache.stubbedCachedWorkflowDetails = ["wf_1": try Self.workflowDataResult(id: "wf_1")]
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .failure(
            .networkError(.errorResponse(.init(code: .invalidAPIKey, originalCode: 0), .invalidRequest))
        )

        var served: WorkflowDataResult?
        var erroredWith: BackendError?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            switch $0 {
            case let .success(result): served = result
            case let .failure(error): erroredWith = error
            }
        }

        expect(served).to(beNil())
        expect(erroredWith).toNot(beNil())
        // The persisted copy was not served into memory.
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    func testGetWorkflowSurfacesErrorWhenFallbackEligibleButNoDiskDetail() {
        // A transient error but nothing persisted to recover: surface the original error rather than
        // leaving the caller without a response.
        self.mockDeviceCache.stubbedCachedWorkflowDetails = nil
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .failure(
            .networkError(.errorResponse(.init(code: .unknownError, originalCode: 0), .internalServerError))
        )

        var served: WorkflowDataResult?
        var erroredWith: BackendError?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            switch $0 {
            case let .success(result): served = result
            case let .failure(error): erroredWith = error
            }
        }

        expect(served).to(beNil())
        expect(erroredWith).toNot(beNil())
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    func testGetWorkflowStaleHitRePinsFromDiskWhenBackgroundRefreshFails() throws {
        // Stale-while-revalidate: a fallback-eligible background-refresh failure recovers the persisted
        // detail and re-stamps the cache fresh, mirroring `OfferingsManager`'s disk fallback. The disk
        // copy (the persisted prefetched detail) can differ from the in-memory value, so the cache ends
        // up holding the recovered disk copy.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true
        let inMemory = try Self.workflowDataResult(id: "in_memory")
        let persisted = try Self.workflowDataResult(id: "persisted")
        self.mockDeviceCache.stubbedCachedWorkflowDetails = ["wf_1": persisted]

        // First call populates memory with the in-memory value.
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .success(inMemory))
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == inMemory

        // Past the foreground TTL: the entry is stale-but-present.
        self.dateProvider.advance(by: 6 * 60)

        var served: WorkflowDataResult?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            served = try? $0.get()
        }
        // Served the stale in-memory value immediately.
        expect(served) == inMemory

        // The background refresh fails fallback-eligibly: it re-pins from disk and re-stamps fresh.
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_1", with: .failure(
            .networkError(.errorResponse(.init(code: .unknownError, originalCode: 0), .internalServerError))
        ))
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == persisted
        expect(self.workflowsCache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == false
    }

    // MARK: - getWorkflowsList

    func testGetWorkflowsListStalePresentServesImmediatelyAndRefreshesInBackground() {
        // Stale-while-revalidate for the list: when a usable offeringId -> workflowId map is already
        // cached (stale but present), `onComplete` fires immediately and the list is refreshed in the
        // background, so a caller (e.g. offerings delivery) isn't blocked on the network.
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_1", displayName: "A", offeringId: "default", prefetch: false)
        ]))
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)
        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_1"

        // Let the list go stale, then control the refresh timing.
        self.dateProvider.advance(by: 6 * 60)
        self.mockWorkflowsAPI.shouldStoreGetWorkflowsCompletions = true

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        // Served immediately, before the background refresh lands, and a refresh was issued.
        expect(completed) == true
        expect(self.mockWorkflowsAPI.invokedGetWorkflowsCount) == 2
        // The stale map keeps resolving in the meantime.
        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_1"

        // When the background refresh lands, the map updates.
        self.mockWorkflowsAPI.completeStoredGetWorkflows(with: .success(.init(workflows: [
            .init(id: "wf_2", displayName: "B", offeringId: "default", prefetch: false)
        ])))
        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_2"
    }

    func testGetWorkflowsListColdCacheBlocksUntilFetchCompletes() {
        // With no cached map yet, there's nothing to serve, so `onComplete` must block on the fetch:
        // callers need a populated offeringId -> workflowId map before `getOfferings` returns.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowsCompletions = true

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        expect(completed) == false

        self.mockWorkflowsAPI.completeStoredGetWorkflows(with: .success(.init(workflows: [
            .init(id: "wf_1", displayName: "A", offeringId: "default", prefetch: false)
        ])))
        expect(completed) == true
        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_1"
    }

    func testGetWorkflowsListStalePresentDropsBackgroundWriteWhenClearedBeforeRefreshLands() throws {
        // The background list refresh's write is guarded by the generation captured when the stale map
        // was served. If an identity change clears the cache before the refresh lands, the write is
        // dropped, so the previous user's offeringId -> workflowId map can't repopulate the new user's
        // cache. Like the detail drop-after-clear test, this drives the guard directly: the clear is
        // sequenced after the call, so it passes with or without the capture-before-serve move; the
        // true sub-statement race is the same lock-free read window the cache accepts by design.
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_1", displayName: "A", offeringId: "default", prefetch: false)
        ]))
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)
        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_1"

        self.dateProvider.advance(by: 6 * 60)
        self.mockWorkflowsAPI.shouldStoreGetWorkflowsCompletions = true

        // Stale hit: serves the cached map and stores the background refresh (capturing the generation).
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        // Identity change clears the cache (bumping the generation) before the refresh lands.
        self.workflowsCache.clearCache()

        // The background refresh returns the previous user's list: its write must be dropped.
        self.mockWorkflowsAPI.completeStoredGetWorkflows(with: .success(.init(workflows: [
            .init(id: "wf_2", displayName: "B", offeringId: "default", prefetch: false)
        ])))
        expect(self.manager.cachedWorkflowId(forOfferingId: "default")).to(beNil())
    }

    func testGetWorkflowsListCallsBackendAndCachesPayload() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow A", offeringId: "default", prefetch: false)
        ]))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.mockWorkflowsAPI.invokedGetWorkflowsCount) == 1
        expect(self.mockWorkflowsAPI.invokedGetWorkflowsParameters?.type) == "paywall"
        expect(self.mockDeviceCache.cacheWorkflowsListResponseCount) == 1
        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 0
    }

    func testGetWorkflowsListSkipsNetworkWhenCacheIsFresh() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: []))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)
        self.dateProvider.advance(by: 1) // still within TTL
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.mockWorkflowsAPI.invokedGetWorkflowsCount) == 1
    }

    func testGetWorkflowsListTriggersGetWorkflowForEachPrefetchEntryOnly() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_prefetch", displayName: "A", offeringId: "off_a", prefetch: true),
            .init(id: "wf_skip", displayName: "B", offeringId: "off_b", prefetch: false),
            .init(id: "wf_also_prefetch", displayName: "C", offeringId: "off_c", prefetch: true)
        ]))
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(try Self.workflowDataResult(id: "wf"))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        let prefetchedIds = self.mockWorkflowsAPI.invokedGetWorkflowParametersList.map { $0.workflowId }
        expect(prefetchedIds).to(contain("wf_prefetch", "wf_also_prefetch"))
        expect(prefetchedIds).toNot(contain("wf_skip"))
        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 2
        // Prefetch fetches must request the concurrent workflows queue.
        expect(self.mockWorkflowsAPI.invokedGetWorkflowParametersList.allSatisfy { $0.prefetch }) == true
    }

    func testGetWorkflowsListSkipsPrefetchForWorkflowsWithoutOfferingId() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_with_offering", displayName: "A", offeringId: "off_a", prefetch: true),
            .init(id: "wf_without_offering", displayName: "B", offeringId: nil, prefetch: true)
        ]))
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(try Self.workflowDataResult(id: "wf"))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        let prefetchedIds = self.mockWorkflowsAPI.invokedGetWorkflowParametersList.map { $0.workflowId }
        expect(prefetchedIds).to(contain("wf_with_offering"))
        expect(prefetchedIds).toNot(contain("wf_without_offering"))
        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 1
    }

    func testGetWorkflowsListDoesNotCacheOnBackendFailure() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.mockDeviceCache.cacheWorkflowsListResponseCount) == 0
    }

    func testGetWorkflowsListRestoresOfferingIdMapFromDiskOnBackendFailure() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_1"
    }

    func testGetWorkflowsListKeepsCacheStaleAfterBackendFailureSoNextCallRetries() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])

        // First fetch fails and restores the list from disk, but leaves it stale.
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.workflowsCache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == true

        // A second call therefore still hits the backend rather than short-circuiting on the
        // restored entry.
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.mockWorkflowsAPI.invokedGetWorkflowsCount) == 2
    }

    func testGetWorkflowsListDoesNotRewriteDiskWhenRestoringAfterBackendFailure() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        // The list was read from disk to restore the in-memory map; it must not be written back.
        expect(self.mockDeviceCache.cacheWorkflowsListResponseCount) == 0
    }

    func testGetWorkflowsListDoesNotRestoreFromDiskOnClientError() throws {
        // A 4xx means the backend rejected the request (workflows disabled, unauthorized, ...), so
        // stale prefetched data must not be served.
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(
            .networkError(.errorResponse(.init(code: .invalidAPIKey, originalCode: 0), .invalidRequest))
        )
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])
        self.mockDeviceCache.stubbedCachedWorkflowDetails = ["wf_1": try Self.workflowDataResult(id: "wf_1")]

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.manager.cachedWorkflowId(forOfferingId: "default")).to(beNil())
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    func testGetWorkflowsListRestoresFromDiskOnServerError() {
        // A 5xx is transient, so the last cached list is restored to keep resolving offline.
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(
            .networkError(.errorResponse(.init(code: .unknownError, originalCode: 0), .internalServerError))
        )
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_1"
    }

    func testGetWorkflowsListRestoresDetailsFromDiskOnServerError() throws {
        // A 5xx is transient: both the list mapping AND prefetched details must be restored so the
        // next render can serve them offline. Complements testGetWorkflowsListRestoresFromDiskOnServerError
        // which only asserts on the list mapping.
        let restored = try Self.workflowDataResult(id: "wf_1")
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(
            .networkError(.errorResponse(.init(code: .unknownError, originalCode: 0), .internalServerError))
        )
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])
        self.mockDeviceCache.stubbedCachedWorkflowDetails = ["wf_1": restored]

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == restored
    }

    func testGetWorkflowsListWithDuplicateOfferingIdKeepsLastEntry() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_first", displayName: "First", offeringId: "shared", prefetch: false),
            .init(id: "wf_last", displayName: "Last", offeringId: "shared", prefetch: false)
        ]))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.manager.cachedWorkflowId(forOfferingId: "shared")) == "wf_last"
    }

    // MARK: - cachedWorkflow(forOfferingId:)

    func testCachedWorkflowReturnsFreshCachedWorkflowResolvedViaOfferingIdMap() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_abc", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        let expected = try Self.workflowDataResult(id: "wf_abc")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_abc", isAppBackgrounded: false) { _ in }

        expect(self.manager.cachedWorkflow(forOfferingId: "default")) == expected
    }

    func testCachedWorkflowReturnsNilWhenListNeverFetched() throws {
        // No list fetched, so the mapping is unknown: must not fall back to the offering id.
        let expected = try Self.workflowDataResult(id: "default")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "default", isAppBackgrounded: false) { _ in }

        expect(self.manager.cachedWorkflow(forOfferingId: "default")).to(beNil())
    }

    func testCachedWorkflowReturnsNilWhenOfferingHasNoListMapping() throws {
        // Fresh list maps a different offering; the queried one has no mapping (even though a
        // workflow is cached under its id), so it must not be used as a fallback workflow key.
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_other", displayName: "Other", offeringId: "other", prefetch: false)
        ]))
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        let cachedUnderOfferingId = try Self.workflowDataResult(id: "default")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(cachedUnderOfferingId)
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "default", isAppBackgrounded: false) { _ in }

        expect(self.manager.cachedWorkflow(forOfferingId: "default")).to(beNil())
    }

    func testCachedWorkflowReturnsNilWhenWorkflowsListIsStale() throws {
        // List ages past the TTL while the detail stays fresh: a stale mapping must not be served.
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_abc", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        self.dateProvider.advance(by: 6 * 60)

        let expected = try Self.workflowDataResult(id: "wf_abc")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_abc", isAppBackgrounded: false) { _ in }

        expect(self.manager.cachedWorkflow(forOfferingId: "default")).to(beNil())
    }

    func testCachedWorkflowReturnsNilWhenNothingCached() {
        expect(self.manager.cachedWorkflow(forOfferingId: "default")).to(beNil())
    }

    func testCachedWorkflowReturnsNilWhenCachedWorkflowIsStale() throws {
        // Detail ages past the TTL while the list mapping stays fresh: a stale detail must not be served.
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }

        self.dateProvider.advance(by: 6 * 60)

        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.manager.cachedWorkflow(forOfferingId: "default")).to(beNil())
    }

    // MARK: - cachedWorkflowId(forOfferingId:)

    func testWorkflowIdForOfferingIdReturnsNilBeforeListIsFetched() {
        expect(self.manager.cachedWorkflowId(forOfferingId: "default")).to(beNil())
    }

    func testWorkflowIdForOfferingIdReturnsWorkflowIdAfterListIsFetched() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_abc", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.manager.cachedWorkflowId(forOfferingId: "default")) == "wf_abc"
        expect(self.manager.cachedWorkflowId(forOfferingId: "premium")).to(beNil())
    }

    func testWorkflowIdForOfferingIdReturnsNilForWorkflowWithNilOfferingId() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_no_offering", displayName: "Flow", offeringId: nil, prefetch: false)
        ]))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.manager.cachedWorkflowId(forOfferingId: "default")).to(beNil())
    }

    // MARK: - onComplete

    func testGetWorkflowsListCallsOnCompleteAfterSuccessWithNoPrefetch() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        expect(completed) == true
    }

    func testGetWorkflowsListCallsOnCompleteImmediatelyWhenCacheIsFresh() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: []))
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        self.dateProvider.advance(by: 1)
        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        expect(completed) == true
        expect(self.mockWorkflowsAPI.invokedGetWorkflowsCount) == 1
    }

    func testGetWorkflowsListCallsOnCompleteOnlyAfterAllPrefetchWorkflowsComplete() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_a", displayName: "A", offeringId: "off_a", prefetch: true),
            .init(id: "wf_b", displayName: "B", offeringId: "off_b", prefetch: true)
        ]))
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true
        let result = try Self.workflowDataResult(id: "wf")

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        expect(completed) == false
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_a", with: .success(result))
        expect(completed) == false
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_b", with: .success(result))
        expect(completed) == true
    }

    func testGetWorkflowsListCallsOnCompleteEvenIfAPrefetchWorkflowFails() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_a", displayName: "A", offeringId: "off_a", prefetch: true),
            .init(id: "wf_b", displayName: "B", offeringId: "off_b", prefetch: true)
        ]))
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_a",
                                                        with: .success(try Self.workflowDataResult(id: "wf_a")))
        expect(completed) == false
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_b", with: .failure(.missingAppUserID()))
        expect(completed) == true
    }

    func testGetWorkflowsListCallsOnCompleteAfterNetworkError() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        expect(completed) == true
    }

    func testGetWorkflowsListCallsOnCompleteOnClientError() {
        // A 4xx skips disk restoration and returns early. onComplete must still fire so
        // callers (e.g. offerings delivery) are not blocked.
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(
            .networkError(.errorResponse(.init(code: .invalidAPIKey, originalCode: 0), .invalidRequest))
        )

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        expect(completed) == true
    }

    // MARK: - Detail disk persistence

    func testPrefetchPersistsWorkflowDetailToDisk() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_prefetch", displayName: "A", offeringId: "off_a", prefetch: true)
        ]))
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(try Self.workflowDataResult(id: "wf_prefetch"))

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.mockDeviceCache.cacheWorkflowDetailsCount) >= 1
        expect(self.mockDeviceCache.cachedWorkflowDetailsParameter?.keys).to(contain("wf_prefetch"))
    }

    func testPrefetchBlocksOnFetchAndPersistsFreshDetailWhenCachedButStale() throws {
        // Seed the detail cache, then let it go stale.
        let stale = try Self.workflowDataResult(id: "stale")
        self.workflowsCache.cache(workflow: stale,
                                  workflowId: "wf_a",
                                  ifGeneration: self.workflowsCache.currentCacheGeneration())
        self.dateProvider.advance(by: 6 * 60)

        // Prefetch the same workflow. Even though it's cached-but-stale, prefetch opts out of
        // stale-while-revalidate, so it fetches fresh and persists the fresh envelope, never the stale
        // cached value it would otherwise serve.
        let fresh = try Self.workflowDataResult(id: "fresh")
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_a", displayName: "A", offeringId: "off_a", prefetch: true)
        ]))
        self.mockWorkflowsAPI.stubbedGetWorkflowResults = ["wf_a": .success(fresh)]

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.mockDeviceCache.cachedWorkflowDetailsParameter?["wf_a"]) == fresh
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_a")) == fresh
    }

    func testOnDemandGetWorkflowDoesNotPersistDetailToDisk() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(try Self.workflowDataResult(id: "wf_1"))

        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) { _ in }

        expect(self.mockDeviceCache.cacheWorkflowDetailsCount) == 0
    }

    func testPrefetchDoesNotPersistDetailWhenFetchFails() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_prefetch", displayName: "A", offeringId: "off_a", prefetch: true)
        ]))
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .failure(.missingAppUserID())

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.mockDeviceCache.cacheWorkflowDetailsCount) == 0
    }

    func testPrefetchPersistsAllDetailsInASingleDiskWrite() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_a", displayName: "A", offeringId: "off_a", prefetch: true),
            .init(id: "wf_b", displayName: "B", offeringId: "off_b", prefetch: true)
        ]))
        self.mockWorkflowsAPI.stubbedGetWorkflowResults = [
            "wf_a": .success(try Self.workflowDataResult(id: "wf_a")),
            "wf_b": .success(try Self.workflowDataResult(id: "wf_b"))
        ]

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        // Two prefetches, but the details are batched into one disk write.
        expect(self.mockDeviceCache.cacheWorkflowDetailsCount) == 1
        expect(self.mockDeviceCache.cachedWorkflowDetailsParameter?.keys).to(contain("wf_a", "wf_b"))
    }

    func testPrefetchDropsDiskWriteWhenIdentityChangesMidFlight() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_a", displayName: "A", offeringId: "off_a", prefetch: true)
        ]))
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        // Identity change mid-prefetch clears the cache (bumping the disk generation).
        self.workflowsCache.clearCache()
        let clearCount = self.mockDeviceCache.clearWorkflowDetailsCacheCount

        // The in-flight prefetch from the previous user now lands.
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_a",
                                                        with: .success(try Self.workflowDataResult(id: "wf_a")))

        // Its detail write is dropped, so the previous user's payload is not written back after clear.
        expect(self.mockDeviceCache.cacheWorkflowDetailsCount) == 0
        expect(self.mockDeviceCache.clearWorkflowDetailsCacheCount) == clearCount
    }

    func testPrefetchDoesNotRepopulateMemoryWhenIdentityChangesMidFlight() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_a", displayName: "A", offeringId: "off_a", prefetch: true)
        ]))
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        // Identity change mid-prefetch clears the cache (bumping the generation).
        self.workflowsCache.clearCache()

        // The in-flight prefetch from the previous user now lands.
        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_a",
                                                        with: .success(try Self.workflowDataResult(id: "wf_a")))

        // Its in-memory write is dropped, so the previous user's (user-scoped) detail does not
        // repopulate memory for the new user.
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_a")).to(beNil())
    }

    func testPrefetchInMemoryWriteIsGuardedByListGenerationNotAFreshCapture() throws {
        // The list is fetched at generation 0 and cached. A login/logout then clears the cache
        // (bumping the generation) *before* this prefetch's getWorkflow is issued, so it captures the
        // already-bumped generation. The in-memory write must be guarded by the list's generation it
        // was started with, not that fresh capture, or the previous user's (user-scoped) detail leaks
        // into the new user's cache.
        //
        // This drives getWorkflow directly with the list's generation: it covers getWorkflow honoring
        // the forwarded generation for its write. The prefetch call site forwarding that generation is
        // verified by inspection, since the clear landing between caching the list and the prefetch's
        // synchronous generation capture is not a window we can hit deterministically without a
        // production-only test seam.
        self.mockWorkflowsAPI.shouldStoreGetWorkflowCompletions = true

        let listGeneration = self.workflowsCache.currentCacheGeneration()

        // Identity change clears the cache and bumps the generation before the prefetch is issued.
        self.workflowsCache.clearCache()

        self.manager.getWorkflow(appUserID: self.appUserID,
                                 workflowId: "wf_a",
                                 isAppBackgrounded: false,
                                 prefetch: true,
                                 ifGeneration: listGeneration) { _ in }

        self.mockWorkflowsAPI.completeStoredGetWorkflow(workflowId: "wf_a",
                                                        with: .success(try Self.workflowDataResult(id: "wf_a")))

        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_a")).to(beNil())
    }

    func testGetWorkflowsListDropsListAndPrefetchWhenIdentityChangesWhileListFetchInFlight() throws {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .success(.init(workflows: [
            .init(id: "wf_a", displayName: "A", offeringId: "off_a", prefetch: true)
        ]))
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(try Self.workflowDataResult(id: "wf_a"))

        // Identity change lands while the list fetch is in flight: clearCache bumps the generation
        // before the success completion runs, so the response belongs to the previous user.
        self.mockWorkflowsAPI.onGetWorkflowsBeforeCompletion = { [weak self] in
            self?.workflowsCache.clearCache()
        }

        var completed = false
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false) { completed = true }

        // The previous user's list must not be cached, no prefetch must run or persist its detail,
        // and onComplete still fires so callers (e.g. offerings delivery) are never blocked.
        expect(self.mockDeviceCache.cacheWorkflowsListResponseCount) == 0
        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 0
        expect(self.mockDeviceCache.cacheWorkflowDetailsCount) == 0
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_a")).to(beNil())
        expect(self.manager.cachedWorkflowId(forOfferingId: "off_a")).to(beNil())
        expect(completed) == true
    }

    func testGetWorkflowsListRestoresPersistedDetailsIntoInMemoryCacheOnBackendFailure() throws {
        let restored = try Self.workflowDataResult(id: "wf_1")
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: true)
        ])
        self.mockDeviceCache.stubbedCachedWorkflowDetails = ["wf_1": restored]

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")) == restored
    }

    func testRestoredDetailIsServedOfflineWithoutHittingBackend() throws {
        let restored = try Self.workflowDataResult(id: "wf_1")
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())
        self.mockDeviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: true)
        ])
        self.mockDeviceCache.stubbedCachedWorkflowDetails = ["wf_1": restored]

        // Backend-down recovery restores the detail into the in-memory cache (fresh)...
        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        // ...so a later render is a cache hit with no backend round-trip.
        var served: WorkflowDataResult?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            served = try? $0.get()
        }

        expect(served) == restored
        expect(self.mockWorkflowsAPI.invokedGetWorkflowCount) == 0
    }

    func testGetWorkflowsListRestoreIsNoOpWhenNoDetailsPersisted() {
        self.mockWorkflowsAPI.stubbedGetWorkflowsResult = .failure(.missingAppUserID())
        self.mockDeviceCache.stubbedCachedWorkflowDetails = nil

        self.manager.getWorkflowsList(appUserID: self.appUserID, isAppBackgrounded: false)

        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    // MARK: - Helpers

    private static func workflowDataResult(id: String) throws -> WorkflowDataResult {
        return .init(workflow: try self.publishedWorkflow(id: id), enrolledVariants: nil)
    }

    private static func publishedWorkflow(id: String) throws -> PublishedWorkflow {
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
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

}
