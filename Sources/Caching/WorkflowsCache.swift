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

    /// Serializes the generation check together with the in-memory and on-disk detail writes against
    /// ``clearCache()``, so a late fetch completion (and a list-write prune) can't clobber each other
    /// or repopulate a since-cleared store.
    private let detailsLock = Lock()

    /// Bumped whenever the workflow detail stores (memory and disk) are cleared on an identity
    /// transition. A fetch captures it when issued and re-checks it before writing, so a result for a
    /// since-changed user is dropped rather than repopulating the cache with that user's (potentially
    /// targeted) workflow.
    private let cacheGeneration: Atomic<Int> = .init(0)

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

    /// Caches a freshly fetched workflow in memory, but only if `generation` still matches the current
    /// one. The caller captures ``currentCacheGeneration()`` when it issues the fetch; if
    /// ``clearCache()`` bumped it in between (a log-in/log-out), the write is dropped so a request
    /// issued for the previous user can't repopulate memory with that user's targeted workflow.
    func cache(workflow: WorkflowDataResult, workflowId: String, ifGeneration generation: Int) {
        self.detailsLock.perform {
            guard self.cacheGeneration.value == generation else { return }
            self.cachedWorkflows.modify {
                $0[workflowId] = CachedWorkflow(result: workflow, lastUpdated: self.dateProvider.now())
            }
        }
    }

    /// Marks `workflowId`'s in-memory detail entry stale so the next
    /// ``isWorkflowCacheStale(workflowId:isAppBackgrounded:)`` reports it stale and a subsequent fetch
    /// retries rather than serving the still-cached value. The
    /// per-workflow analogue of ``forceWorkflowsListCacheStale()`` (and of the offerings cache's
    /// `forceCacheStale`); the detail fetch calls it on a terminal error that produced no fresh value,
    /// matching how the list and offerings invalidate their cache on the same failures. No-op when
    /// nothing is cached for the id.
    func invalidateWorkflowTimestamp(workflowId: String) {
        self.cachedWorkflows.modify { cache in
            guard let existing = cache[workflowId] else { return }
            cache[workflowId] = CachedWorkflow(result: existing.result, lastUpdated: .distantPast)
        }
    }

    // MARK: - Workflow detail disk cache

    /// Persists a batch of resolved workflow details to disk, merging into whatever is already there.
    /// Called only from the prefetch path after a successful fetch, so a persisted detail is always
    /// one we can render offline. Mirrors how ``cache(workflowsList:)`` writes the list to disk.
    ///
    /// `generation` guards against an identity change mid-prefetch: the caller captures
    /// ``currentCacheGeneration()`` before fetching and passes it back here; if ``clearCache()`` bumped
    /// it in between (a log-in/log-out), the write is dropped so the previous user's details can't be
    /// written back after the store was cleared.
    func persistWorkflowDetailsToDisk(_ details: [String: WorkflowDataResult], ifGeneration generation: Int) {
        guard !details.isEmpty else { return }
        self.detailsLock.perform {
            guard self.cacheGeneration.value == generation else { return }
            var current = self.deviceCache.cachedWorkflowDetails() ?? [:]
            for (workflowId, result) in details {
                current[workflowId] = result
            }
            // Keep the on-disk map a subset of the latest list: a slower prefetch from an earlier,
            // overlapping list fetch must not write back an id a newer list already pruned.
            if let listIds = self.cachedListWorkflowIds() {
                current = current.filter { listIds.contains($0.key) }
            }
            self.deviceCache.cache(workflowDetails: current)
        }
    }

    /// A token that changes whenever the workflow detail stores (memory and disk) are cleared on an
    /// identity transition. Captured when a fetch is issued and re-checked before its in-memory write
    /// (``cache(workflow:workflowId:ifGeneration:)``) and its disk write
    /// (``persistWorkflowDetailsToDisk(_:ifGeneration:)``) to drop writes that would land after a user
    /// change.
    func currentCacheGeneration() -> Int {
        return self.cacheGeneration.value
    }

    /// Returns the persisted detail for `workflowId`, or `nil` when the key is absent or nothing is
    /// persisted. Convenience wrapper over the on-disk detail map, used by the detail fetch's disk
    /// fallback to recover a single resolved workflow after a transient backend failure.
    func cachedWorkflowDetailFromDisk(workflowId: String) -> WorkflowDataResult? {
        return self.deviceCache.cachedWorkflowDetails()?[workflowId]
    }

    /// Restores the persisted prefetched details into the in-memory cache, stamped fresh so
    /// ``cachedWorkflow(workflowId:)`` serves them without a backend round-trip. Used to recover after
    /// a list-fetch failure. No-op when nothing is persisted. Mirrors ``restoreWorkflowsListFromDisk()``.
    ///
    /// Fresh, not stale: stamping them stale would make ``WorkflowManager.getWorkflow`` try the backend
    /// (which is down, with no disk fallback) instead of serving them, defeating the recovery. The cost
    /// is that once the backend is back these details keep being served as cache hits until their own
    /// foreground TTL expires, only then does `getWorkflow` refetch them, so recovery refreshes the
    /// list/map promptly but the details ride their TTL.
    ///
    /// Only fills ids not already in memory: an on-demand ``cachedWorkflow(workflowId:)`` miss may have
    /// fetched a fresher detail that was never persisted, so the older disk snapshot must not clobber it.
    ///
    /// The disk read and memory write are held under ``detailsLock`` together so they're atomic w.r.t.
    /// ``clearCache()``: this runs on the list-fetch failure thread while a log-in/log-out can clear on
    /// another, and without the lock a clear landing between the read and the write would restore the
    /// previous user's (user-scoped) details into the new user's cache.
    func restoreWorkflowDetailsFromDisk() {
        self.detailsLock.perform {
            guard let details = self.deviceCache.cachedWorkflowDetails() else { return }
            let now = self.dateProvider.now()
            self.cachedWorkflows.modify { cache in
                for (workflowId, result) in details where cache[workflowId] == nil {
                    cache[workflowId] = CachedWorkflow(result: result, lastUpdated: now)
                }
            }
        }
    }

    /// Drops persisted details whose workflowId is no longer in the latest list, so workflows the
    /// backend stopped sending don't linger on disk. The persisted set always stays a subset of what
    /// the latest list says exists. No-op (no rewrite) when nothing is pruned.
    ///
    /// Does not take ``detailsLock`` itself: the caller must already hold it (the only caller is the
    /// guarded list write, which prunes while holding it, and the lock is not recursive).
    private func pruneWorkflowDetails(toListIds workflowIds: Set<String>) {
        guard let current = self.deviceCache.cachedWorkflowDetails() else { return }
        let pruned = current.filter { workflowIds.contains($0.key) }
        if pruned.count != current.count {
            self.deviceCache.cache(workflowDetails: pruned)
        }
    }

    /// The workflow ids in the currently cached list, or `nil` when no list is cached. Used to keep
    /// the on-disk detail map a subset of the latest list when persisting.
    private func cachedListWorkflowIds() -> Set<String>? {
        guard let response = self.cachedList.value?.response else { return nil }
        return Set(response.workflows.map { $0.id })
    }

    // MARK: - Workflows list cache

    func isWorkflowsListCacheStale(isAppBackgrounded: Bool) -> Bool {
        guard let cached = self.cachedList.value else {
            return true
        }
        return self.isStale(lastUpdated: cached.lastUpdated, isAppBackgrounded: isAppBackgrounded)
    }

    /// Caches the workflows list in memory and persists it to disk, but only if `generation` still
    /// matches the current one. The caller captures ``currentCacheGeneration()`` when it issues the
    /// list fetch; if ``clearCache()`` bumped it in between (a log-in/log-out), the write is dropped
    /// so a list (the user-targeted `offeringId → workflowId` map) fetched for the previous user can't
    /// repopulate the cleared cache. Returns `true` when the write happened, `false` when it was
    /// dropped, so the caller can skip prefetching a dropped list's details.
    ///
    /// The generation check, the in-memory + disk writes, and the detail prune all run under
    /// ``detailsLock`` together, so the whole update is atomic w.r.t. ``clearCache()`` (no
    /// check-then-write window). Also prunes persisted details whose workflowId is no longer in the
    /// latest list, keeping the on-disk detail store bounded by what the backend currently says exists.
    @discardableResult
    func cache(workflowsList response: WorkflowsListResponse, ifGeneration generation: Int) -> Bool {
        return self.detailsLock.perform {
            guard self.cacheGeneration.value == generation else { return false }
            self.cachedList.value = CachedList(response: response,
                                               offeringIdToWorkflowId: Self.offeringIdToWorkflowId(from: response),
                                               lastUpdated: self.dateProvider.now())
            self.deviceCache.cache(workflowsListResponse: response)
            self.pruneWorkflowDetails(toListIds: Set(response.workflows.map { $0.id }))
            return true
        }
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
        self.detailsLock.perform {
            guard let response = self.cachedWorkflowsListResponseFromDisk() else { return }
            self.cachedList.value = CachedList(response: response,
                                               offeringIdToWorkflowId: Self.offeringIdToWorkflowId(from: response),
                                               lastUpdated: .distantPast)
        }
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

    /// `true` when a workflows list is present in memory (fetched or restored this session), regardless
    /// of staleness. Lets the manager serve a stale-but-present `offeringId → workflowId` map
    /// immediately while refreshing in the background, and block only on a cold/empty cache.
    var hasCachedWorkflowsList: Bool {
        return self.cachedList.value != nil
    }

    // MARK: -

    func clearCache() {
        // Bump the generation and clear the list and detail stores (memory + disk) together under the
        // lock, so a fetch issued before this clear (and capturing the old generation) can't write the
        // previous user's list or details back into memory or disk.
        self.detailsLock.perform {
            self.cacheGeneration.modify { $0 += 1 }
            self.cachedList.value = nil
            self.deviceCache.clearWorkflowsListResponseCache()
            self.cachedWorkflows.value = [:]
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
