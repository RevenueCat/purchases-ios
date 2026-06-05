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

    func testGetWorkflowForwardsBackendError() {
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .failure(.missingAppUserID())

        var error: BackendError?
        self.manager.getWorkflow(appUserID: self.appUserID, workflowId: "wf_1", isAppBackgrounded: false) {
            if case let .failure(failure) = $0 { error = failure }
        }

        expect(error).toNot(beNil())
        expect(self.workflowsCache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    // MARK: - getWorkflowsList

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
