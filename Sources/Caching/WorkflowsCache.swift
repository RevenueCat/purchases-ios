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

/// In-memory cache for workflow data: the resolved per-workflow ``WorkflowDataResult``s and the
/// workflows list (plus its `offeringId → workflowId` map). It is the single owner of this state,
/// so ``clearCache()`` wipes everything at once on identity transitions.
///
/// Like the offerings cache, it sits on top of the durable copy in `DeviceCache` and serves
/// already-fetched data synchronously within a session. Time-based staleness uses the same
/// foreground/background TTL as offerings, stamped via an injected ``DateProvider`` (rather than
/// `InMemoryCachedObject`, whose staleness is tied to the real wall clock) so expiry is
/// deterministically testable.
final class WorkflowsCache {

    private struct CachedWorkflow {
        let result: WorkflowDataResult
        let lastUpdated: Date
    }

    private struct CachedList {
        let response: WorkflowsListResponse
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

    /// Caches the workflows list in memory and persists it to disk.
    ///
    /// A fetch in flight during an identity transition can complete *after* ``clearCache()`` and
    /// repopulate the cache with the previous user's list (last-write-wins). This is not guarded
    /// here; it self-heals on the next fetch, as the offerings cache does.
    func cache(workflowsList response: WorkflowsListResponse) {
        self.cachedList.value = CachedList(response: response, lastUpdated: self.dateProvider.now())
        self.deviceCache.cache(workflowsListResponse: response)
    }

    /// Reads the last persisted workflows list, or `nil` when nothing is cached or the payload
    /// can't be parsed. Used to recover the list after a backend failure.
    func cachedWorkflowsListResponseFromDisk() -> WorkflowsListResponse? {
        return self.deviceCache.cachedWorkflowsListResponse()
    }

    /// Resolves the workflow id for an offering, derived from ``WorkflowSummary/offeringId`` in the
    /// cached list. Falls back to the disk copy so it still resolves after a restore, before the
    /// next fetch repopulates the in-memory cache. If more than one workflow maps to the same
    /// offering, the last one in the list wins.
    func workflowId(forOfferingId offeringId: String) -> String? {
        let response = self.cachedList.value?.response ?? self.deviceCache.cachedWorkflowsListResponse()
        return response?.workflows.last { $0.offeringId == offeringId }?.id
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

// @unchecked because its mutable state is held in thread-safe `Atomic` containers.
extension WorkflowsCache: @unchecked Sendable {}
