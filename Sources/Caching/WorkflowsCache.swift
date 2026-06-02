//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowsCache.swift
//
//  Created by RevenueCat.

import Foundation

/// In-memory cache for all workflow data: the resolved per-workflow ``WorkflowDataResult``s and the
/// workflows list (plus its derived offeringId → workflowId map). It is the single owner of this
/// state so that clearing it on identity transitions wipes everything at once, mirroring how
/// `DeviceCache` owns the in-memory offerings cache.
///
/// Why in-memory, like offerings: this layer sits on top of the durable copy that lives on disk in
/// `DeviceCache`, for the same reason the offerings cache does, to serve already-fetched and
/// prefetched data synchronously within a session, so opening a paywall reuses a resolved workflow
/// instead of paying another backend/CDN round-trip. Time-based staleness
/// (``isWorkflowsListCacheStale(isAppBackgrounded:)`` / ``isWorkflowCacheStale(workflowId:isAppBackgrounded:)``)
/// then decides when a refetch is due, using the same 5 min / 25 hr foreground/background TTL as offerings.
///
/// It also owns the disk copy of the workflows list: ``cache(workflowsList:offeringIdMap:)`` persists
/// it, ``cachedWorkflowsListResponseFromDisk()`` restores it on backend failure, and ``clearCache()``
/// wipes it.
///
/// Timestamps are stamped via an injected ``DateProvider`` (rather than reusing `InMemoryCachedObject`,
/// whose staleness is tied to the real wall clock) so cache-expiry behavior is deterministically
/// testable, mirroring the Android SDK's `WorkflowsCache`.
final class WorkflowsCache {

    private struct CachedWorkflow {
        let result: WorkflowDataResult
        let lastUpdated: Date
    }

    private struct CachedList {
        let response: WorkflowsListResponse
        let offeringIdToWorkflowId: [String: String]
        let lastUpdated: Date
    }

    private let deviceCache: DeviceCache
    private let dateProvider: DateProvider

    private let cachedWorkflows: Atomic<[String: CachedWorkflow]> = .init([:])
    private let cachedList: Atomic<CachedList?> = .init(nil)

    init(deviceCache: DeviceCache,
         dateProvider: DateProvider = DateProvider()) {
        self.deviceCache = deviceCache
        self.dateProvider = dateProvider
    }

    // MARK: - Workflow detail cache

    func cachedWorkflow(workflowId: String) -> WorkflowDataResult? {
        return self.cachedWorkflows.value[workflowId]?.result
    }

    func isWorkflowCacheStale(workflowId: String, isAppBackgrounded: Bool) -> Bool {
        guard let cached = self.cachedWorkflows.value[workflowId] else {
            return true
        }
        return self.isStale(lastUpdated: cached.lastUpdated, isAppBackgrounded: isAppBackgrounded)
    }

    func cache(workflow: WorkflowDataResult, workflowId: String) {
        self.cachedWorkflows.modify {
            $0[workflowId] = CachedWorkflow(result: workflow, lastUpdated: self.dateProvider.now())
        }
    }

    // MARK: - Workflows list cache

    func isWorkflowsListCacheStale(isAppBackgrounded: Bool) -> Bool {
        guard let cached = self.cachedList.value else {
            return true
        }
        return self.isStale(lastUpdated: cached.lastUpdated, isAppBackgrounded: isAppBackgrounded)
    }

    /// Caches the workflows list in memory and persists it to disk, the same way
    /// `DeviceCache.cache(offerings:...)` caches offerings.
    ///
    /// This means workflows share the same accepted appUserID limitation as offerings: a fetch that
    /// is in flight during an identity transition can complete *after* ``clearCache()`` and repopulate
    /// the cleared cache with the previous user's list (last-write-wins). It is not guarded here, so
    /// it self-heals on the next fetch, exactly as the offerings cache does. If we ever decide to
    /// close that window, it should be done consistently for both caches rather than only here.
    func cache(workflowsList response: WorkflowsListResponse, offeringIdMap: [String: String]) {
        self.cachedList.value = CachedList(response: response,
                                           offeringIdToWorkflowId: offeringIdMap,
                                           lastUpdated: self.dateProvider.now())
        self.deviceCache.cache(workflowsListResponse: response)
    }

    /// Reads the last workflows list persisted by ``cache(workflowsList:offeringIdMap:)``, or `nil`
    /// when nothing is cached or the payload can't be parsed. Used to recover the list after a
    /// backend failure, mirroring how the offerings response is restored from disk.
    func cachedWorkflowsListResponseFromDisk() -> WorkflowsListResponse? {
        return self.deviceCache.cachedWorkflowsListResponse()
    }

    func workflowId(forOfferingId offeringId: String) -> String? {
        return self.cachedList.value?.offeringIdToWorkflowId[offeringId]
    }

    // MARK: -

    func clearCache() {
        self.cachedWorkflows.value = [:]
        self.cachedList.value = nil
        self.deviceCache.clearWorkflowsListResponseCache()
    }

    private func isStale(lastUpdated: Date, isAppBackgrounded: Bool) -> Bool {
        let duration = self.deviceCache.cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded)
        return self.dateProvider.now().timeIntervalSince(lastUpdated) >= duration
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WorkflowsCache: @unchecked Sendable {}
