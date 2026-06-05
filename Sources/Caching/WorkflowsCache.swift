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
        let offeringIdToWorkflowId: [String: String]
        let lastUpdated: Date
    }

    private let deviceCache: DeviceCache
    private let dateProvider: DateProvider

    private let cachedWorkflows: Atomic<[String: CachedWorkflow]> = .init([:])
    private let cachedList: Atomic<CachedList?> = .init(nil)

    /// Serializes the read-modify-write of the on-disk workflow detail map so concurrent prefetch
    /// persists (and a list-write prune) don't clobber each other.
    private let detailsDiskLock = Lock()

    /// Bumped whenever the on-disk detail store is cleared (identity transitions). Lets an in-flight
    /// prefetch detect that its results belong to a since-cleared user and skip persisting them.
    private let diskGeneration: Atomic<Int> = .init(0)

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
        self.cache(workflows: [workflowId: workflow])
    }

    /// Caches a batch of resolved workflows in memory in one pass, all stamped with the same `now()`.
    func cache(workflows: [String: WorkflowDataResult]) {
        let now = self.dateProvider.now()
        self.cachedWorkflows.modify { cache in
            for (workflowId, result) in workflows {
                cache[workflowId] = CachedWorkflow(result: result, lastUpdated: now)
            }
        }
    }

    // MARK: - Workflow detail disk cache

    /// Persists a batch of resolved workflow details to disk, merging into whatever is already there.
    /// Called only from the prefetch path after a successful fetch, so a persisted detail is always
    /// one we can render offline. Mirrors how ``cache(workflowsList:)`` writes the list to disk.
    ///
    /// `generation` guards against an identity change mid-prefetch: the caller captures
    /// ``currentDiskGeneration()`` before fetching and passes it back here; if ``clearCache()`` bumped
    /// it in between (a log-in/log-out), the write is dropped so the previous user's details can't be
    /// written back after the store was cleared.
    func persistWorkflowDetailsToDisk(_ details: [String: WorkflowDataResult], ifGeneration generation: Int) {
        guard !details.isEmpty else { return }
        self.detailsDiskLock.perform {
            guard self.diskGeneration.value == generation else { return }
            var current = self.deviceCache.cachedWorkflowDetails() ?? [:]
            for (workflowId, result) in details {
                current[workflowId] = result
            }
            self.deviceCache.cache(workflowDetails: current)
        }
    }

    /// A token that changes whenever the on-disk detail store is cleared (on identity transitions).
    /// Captured before a prefetch and re-checked at ``persistWorkflowDetailsToDisk(_:ifGeneration:)``
    /// time to drop writes that would land after a user change.
    func currentDiskGeneration() -> Int {
        return self.diskGeneration.value
    }

    /// Restores the persisted prefetched details into the in-memory cache, stamped fresh so
    /// ``cachedWorkflow(workflowId:)`` serves them without a backend round-trip. Used to recover after
    /// a list-fetch failure; the list is restored stale separately so it refetches once the backend is
    /// back. No-op when nothing is persisted. Mirrors ``restoreWorkflowsListFromDisk()``.
    func restoreWorkflowDetailsFromDisk() {
        guard let details = self.deviceCache.cachedWorkflowDetails() else { return }
        self.cache(workflows: details)
    }

    /// Drops persisted details whose workflowId is no longer in the latest list, so workflows the
    /// backend stopped sending don't linger on disk. The persisted set always stays a subset of what
    /// the latest list says exists. No-op (no rewrite) when nothing is pruned.
    private func pruneWorkflowDetails(toListIds workflowIds: Set<String>) {
        self.detailsDiskLock.perform {
            guard let current = self.deviceCache.cachedWorkflowDetails() else { return }
            let pruned = current.filter { workflowIds.contains($0.key) }
            if pruned.count != current.count {
                self.deviceCache.cache(workflowDetails: pruned)
            }
        }
    }

    // MARK: - Workflows list cache

    func isWorkflowsListCacheStale(isAppBackgrounded: Bool) -> Bool {
        guard let cached = self.cachedList.value else {
            return true
        }
        return self.isStale(lastUpdated: cached.lastUpdated, isAppBackgrounded: isAppBackgrounded)
    }

    /// Caches the workflows list in memory and persists it to disk. Also prunes any persisted
    /// workflow details whose workflowId is no longer in the latest list, keeping the on-disk detail
    /// store bounded by what the backend currently says exists.
    func cache(workflowsList response: WorkflowsListResponse) {
        self.cachedList.value = CachedList(response: response,
                                           offeringIdToWorkflowId: Self.offeringIdToWorkflowId(from: response),
                                           lastUpdated: self.dateProvider.now())
        self.deviceCache.cache(workflowsListResponse: response)
        self.pruneWorkflowDetails(toListIds: Set(response.workflows.map { $0.id }))
    }

    /// Reads the last persisted workflows list, or `nil` when nothing is cached or the payload
    /// can't be parsed.
    func cachedWorkflowsListResponseFromDisk() -> WorkflowsListResponse? {
        return self.deviceCache.cachedWorkflowsListResponse()
    }

    /// Restores the in-memory `offeringId → workflowId` map from the last list persisted on disk,
    /// keeping the entry stale so the next fetch still hits the backend. Used to recover after a
    /// backend failure: it keeps ``workflowId(forOfferingId:)`` resolving previously-fetched data
    /// without suppressing the next refresh, mirroring how the offerings cache serves its disk copy
    /// while staying stale. No-op when nothing is persisted, and the on-disk copy is left untouched.
    func restoreWorkflowsListFromDisk() {
        guard let response = self.cachedWorkflowsListResponseFromDisk() else { return }
        self.cachedList.value = CachedList(response: response,
                                           offeringIdToWorkflowId: Self.offeringIdToWorkflowId(from: response),
                                           lastUpdated: .distantPast)
    }

    /// Marks the in-memory workflows list stale so the next ``isWorkflowsListCacheStale(isAppBackgrounded:)``
    /// returns `true` and triggers a refetch, while ``workflowId(forOfferingId:)`` keeps resolving the
    /// current map until then. Used to refresh the list alongside a network offerings refresh. No-op
    /// when nothing is cached; the on-disk copy is left untouched.
    func forceWorkflowsListCacheStale() {
        self.cachedList.modify { cached in
            guard let current = cached else { return }
            cached = CachedList(response: current.response,
                                offeringIdToWorkflowId: current.offeringIdToWorkflowId,
                                lastUpdated: .distantPast)
        }
    }

    /// Resolves the workflow id for an offering from the in-memory list, or `nil` when the list
    /// hasn't been cached this session.
    func workflowId(forOfferingId offeringId: String) -> String? {
        return self.cachedList.value?.offeringIdToWorkflowId[offeringId]
    }

    // MARK: -

    func clearCache() {
        self.cachedWorkflows.value = [:]
        self.cachedList.value = nil
        self.deviceCache.clearWorkflowsListResponseCache()
        // Bump the generation and clear the disk store atomically, so a prefetch that started before
        // this clear (and captured the old generation) can't write the previous user's details back.
        self.detailsDiskLock.perform {
            self.diskGeneration.modify { $0 += 1 }
            self.deviceCache.clearWorkflowDetailsCache()
        }
    }

    private func isStale(lastUpdated: Date, isAppBackgrounded: Bool) -> Bool {
        let duration = self.deviceCache.cacheDurationInSeconds(isAppBackgrounded: isAppBackgrounded)
        return self.dateProvider.now().timeIntervalSince(lastUpdated) >= duration
    }

    /// Builds the `offeringId → workflowId` lookup from the list. Workflows without an `offeringId`
    /// are skipped, and when more than one workflow maps to the same offering the last one in the
    /// list wins.
    private static func offeringIdToWorkflowId(from response: WorkflowsListResponse) -> [String: String] {
        var map: [String: String] = [:]
        for workflow in response.workflows {
            guard let offeringId = workflow.offeringId else { continue }
            if map[offeringId] != nil {
                Logger.warn(Strings.backendError.duplicate_offering_id_in_workflows(offeringId: offeringId))
            }
            map[offeringId] = workflow.id
        }
        return map
    }

}

// @unchecked because its mutable state is held in thread-safe `Atomic` containers.
extension WorkflowsCache: @unchecked Sendable {}
