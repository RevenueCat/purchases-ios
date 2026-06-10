//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowManager.swift
//
//  Created by RevenueCat.

import Foundation

/// Orchestrates fetching paywall workflows on top of the `WorkflowsAPI` networking layer, mirroring
/// the role `OfferingsManager` plays for offerings. It serves a fresh cached workflow without a
/// backend round-trip via ``WorkflowsCache``, and prefetches workflows flagged `prefetch == true`
/// so they are warm by the time their paywall opens.
class WorkflowManager {

    private let backend: Backend
    private let workflowsCache: WorkflowsCache
    private let paywallCache: PaywallCacheWarmingType?
    private let operationDispatcher: OperationDispatcher

    init(backend: Backend,
         workflowsCache: WorkflowsCache,
         paywallCache: PaywallCacheWarmingType?,
         operationDispatcher: OperationDispatcher) {
        self.backend = backend
        self.workflowsCache = workflowsCache
        self.paywallCache = paywallCache
        self.operationDispatcher = operationDispatcher
    }

    /// Resolves a workflow using stale-while-revalidate, mirroring how ``OfferingsManager`` vends
    /// offerings: a fresh cache hit is served directly; a stale-but-present hit is served immediately
    /// and the cache is refreshed in the background (no callbacks, failures logged); a miss fetches
    /// from the backend, caches the result, warms its assets, and delivers the outcome.
    ///
    /// - Parameter staleWhileRevalidate: when `true` (the default, used by the on-demand render path),
    ///   a stale-but-present cached workflow is served immediately with a background refresh. When
    ///   `false` (the prefetch path), a stale workflow blocks on a full refetch instead, so prefetch
    ///   keeps forcing a fresh fetch and persisting its envelope rather than serving a stale value.
    ///
    /// Disk persistence of prefetched details is handled by
    /// ``prefetchWorkflows(_:appUserID:isAppBackgrounded:generation:onComplete:)``, not here.
    func getWorkflow(appUserID: String,
                     workflowId: String,
                     isAppBackgrounded: Bool,
                     prefetch: Bool = false,
                     ifGeneration generation: Int? = nil,
                     staleWhileRevalidate: Bool = true,
                     completion: @escaping (Result<WorkflowDataResult, BackendError>) -> Void) {
        let cached = self.workflowsCache.cachedWorkflow(workflowId: workflowId)
        if let cached,
           !self.workflowsCache.isWorkflowCacheStale(workflowId: workflowId, isAppBackgrounded: isAppBackgrounded) {
            completion(.success(cached))
            return
        }

        if let cached, staleWhileRevalidate {
            // Serve the stale value immediately, then refresh the cache in the background. The caller
            // already has a usable value, so the refresh delivers no result: a success only updates the
            // cache, a failure is logged and swallowed. Mirrors `OfferingsManager`'s stale offerings
            // path. Concurrent stale callers each call this, but their network requests are coalesced
            // by `WorkflowsAPI`'s callback cache (keyed by the request), so only one fetch fires.
            //
            // Capture the refresh's guarding generation *before* serving, so it reflects the generation
            // observed at serve time rather than after `completion` runs. The background write is then
            // dropped if a `clearCache()` (login/logout) bumps the generation before the response lands,
            // exactly like the blocking path binds its write to the generation at fetch-issue time.
            let refreshGeneration = generation ?? self.workflowsCache.currentCacheGeneration()
            completion(.success(cached))
            self.fetchAndCacheWorkflow(appUserID: appUserID,
                                       workflowId: workflowId,
                                       isAppBackgrounded: isAppBackgrounded,
                                       prefetch: prefetch,
                                       ifGeneration: refreshGeneration) { result in
                if case let .failure(error) = result {
                    Logger.error(Strings.paywalls.error_refreshing_workflow(workflowId: workflowId, error: error))
                }
            }
            return
        }

        // Miss, or stale with stale-while-revalidate disabled (the prefetch path): block on the fetch.
        self.fetchAndCacheWorkflow(appUserID: appUserID,
                                   workflowId: workflowId,
                                   isAppBackgrounded: isAppBackgrounded,
                                   prefetch: prefetch,
                                   ifGeneration: generation,
                                   completion: completion)
    }

    /// Fetches a workflow from the backend, caches the result in memory (guarded by `generation`), and
    /// warms its assets before delivering the outcome. Shared by the blocking miss path and the
    /// stale-while-revalidate background refresh.
    private func fetchAndCacheWorkflow(
        appUserID: String,
        workflowId: String,
        isAppBackgrounded: Bool,
        prefetch: Bool = false,
        ifGeneration generation: Int? = nil,
        completion: @escaping (Result<WorkflowDataResult, BackendError>) -> Void
    ) {
        // The generation guarding the in-memory write: prefetch forwards the generation captured when
        // the list fetch was issued (`generation`), so a clear landing between caching the list and
        // issuing this prefetch still drops the write. On-demand callers pass `nil` and capture it
        // fresh here, since their request is only issued now. Either way, if an identity change clears
        // the cache before the write lands it's dropped, so a result fetched for the previous user
        // (workflow detail is user-scoped) can't repopulate memory.
        let writeGeneration = generation ?? self.workflowsCache.currentCacheGeneration()
        self.backend.workflowsAPI.getWorkflow(appUserID: appUserID,
                                              workflowId: workflowId,
                                              isAppBackgrounded: isAppBackgrounded,
                                              prefetch: prefetch) { [weak self] result in
            guard let self else {
                completion(result)
                return
            }
            if case let .success(dataResult) = result {
                self.workflowsCache.cache(workflow: dataResult,
                                          workflowId: workflowId,
                                          ifGeneration: writeGeneration)
                self.warmUpAssets(for: dataResult)
            }
            completion(result)
        }
    }

    /// Fetches the workflows list, persists it, then prefetches every entry flagged `prefetch == true`.
    /// `onComplete` fires only after the list fetch **and** all prefetch fetches finish (success or
    /// failure), making it safe to call ``cachedWorkflowId(forOfferingId:)`` from `onComplete`.
    ///
    /// When the in-memory list cache is still fresh, no network request is made and `onComplete` fires
    /// immediately. On a backend failure `onComplete` still fires (so callers waiting on it, e.g.
    /// offerings delivery, are never blocked); ``cachedWorkflowId(forOfferingId:)`` keeps resolving from the
    /// last list persisted on disk until the next fetch succeeds.
    func getWorkflowsList(appUserID: String,
                          isAppBackgrounded: Bool,
                          onComplete: @escaping () -> Void = {}) {
        guard self.workflowsCache.isWorkflowsListCacheStale(isAppBackgrounded: isAppBackgrounded) else {
            onComplete()
            return
        }

        // Capture the cache generation when the request is issued. If an identity change clears the
        // cache while this list fetch is in flight, the success path below is dropped, so a list
        // (and its prefetched, user-scoped details) fetched for the previous user can't populate the
        // new session's cache.
        let generation = self.workflowsCache.currentCacheGeneration()
        self.backend.workflowsAPI.getWorkflows(appUserID: appUserID,
                                               isAppBackgrounded: isAppBackgrounded,
                                               type: Self.paywallWorkflowType) { [weak self] result in
            guard let self else {
                onComplete()
                return
            }
            switch result {
            case let .success(response):
                // The list write re-checks `generation` atomically under the cache's lock and reports
                // whether it landed. If an identity change cleared the cache mid-flight, the write is
                // dropped (this response is the previous user's) and we skip prefetching its details,
                // still firing onComplete so callers waiting on it aren't blocked.
                guard self.workflowsCache.cache(workflowsList: response, ifGeneration: generation) else {
                    onComplete()
                    return
                }
                self.prefetchWorkflows(response.workflows,
                                       appUserID: appUserID,
                                       isAppBackgrounded: isAppBackgrounded,
                                       generation: generation,
                                       onComplete: onComplete)
            case let .failure(error):
                Logger.error(Strings.paywalls.error_fetching_workflows_list(error))
                guard error.shouldFallBackToCache else {
                    // A 4xx means the backend authoritatively rejected the request (workflows
                    // disabled for the app, unauthorized for this user, ...), so don't serve stale
                    // prefetched data from disk. Only transient errors (5xx / offline) restore below.
                    // Mirrors how offerings gate their disk fallback on `shouldFallBackToCache`.
                    onComplete()
                    return
                }
                // Restore the in-memory offeringId -> workflowId map from the last list persisted on
                // disk, so `cachedWorkflowId(forOfferingId:)` keeps resolving previously-fetched data after
                // a backend failure instead of returning nil. The entry stays stale so the next
                // fetch still retries the backend.
                self.workflowsCache.restoreWorkflowsListFromDisk()
                // Restore the prefetched workflow details persisted on disk into the in-memory cache
                // so a cold start with the backend down can still render them. They're restored fresh
                // (like a normal fetch) so `getWorkflow` serves them offline. The stale list above
                // drives the next list/map refetch when the backend is back; the details themselves
                // keep serving as cache hits until their own TTL expires (see `restoreWorkflowDetailsFromDisk`).
                self.workflowsCache.restoreWorkflowDetailsFromDisk()
                onComplete()
            }
        }
    }

    func cachedWorkflowId(forOfferingId offeringId: String) -> String? {
        return self.workflowsCache.workflowId(forOfferingId: offeringId)
    }

    /// Returns the cached workflow for `offeringId` only when seeding it synchronously is safe: the
    /// workflows list is fresh and explicitly maps `offeringId`, and that workflow's detail is
    /// cached and fresh. Otherwise returns nil so the async path refetches.
    ///
    /// A stale list mapping (or the old offering-id fallback) can resolve the wrong workflow, and a
    /// synchronous seed skips the view's async refresh, so there'd be no correction.
    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? {
        // `isAppBackgrounded: false` is intentional: this synchronous seed only runs while a paywall
        // is being presented, i.e. the app is in the foreground. The foreground TTL is the shorter,
        // stricter one, so the worst case is treating a borderline-fresh entry as stale and falling
        // through to the async refetch, never seeding something the background TTL would reject.
        guard !self.workflowsCache.isWorkflowsListCacheStale(isAppBackgrounded: false),
              let workflowId = self.workflowsCache.workflowId(forOfferingId: offeringId) else {
            return nil
        }
        guard let cached = self.workflowsCache.cachedWorkflow(workflowId: workflowId),
              !self.workflowsCache.isWorkflowCacheStale(workflowId: workflowId, isAppBackgrounded: false) else {
            return nil
        }
        return cached
    }

    /// Marks the workflows list stale so the next ``getWorkflowsList(appUserID:isAppBackgrounded:onComplete:)``
    /// refetches it. Called when offerings are refreshed from the network, to keep both in sync.
    func forceWorkflowsListCacheStale() {
        self.workflowsCache.forceWorkflowsListCacheStale()
    }

}

// MARK: - Private

private extension WorkflowManager {

    static let paywallWorkflowType = "paywall"

    /// Prefetches the workflows flagged `prefetch == true` that are tied to an offering, calling
    /// `onComplete` once every prefetch finishes (success or failure). Workflows without an
    /// `offeringId` can't be resolved via ``cachedWorkflowId(forOfferingId:)``, so they're skipped.
    /// When there is nothing to prefetch, `onComplete` fires right away.
    ///
    /// Successful results are accumulated and persisted to disk in a single batch once the last
    /// prefetch lands, so a later cold start with the backend down can restore and render them
    /// offline. Only prefetched workflows are persisted: they're the curated, bounded set the backend
    /// marked as mattering, so persisting all of them is safe. On-demand fetches are not persisted, to
    /// avoid unbounded disk growth (a session can open many distinct paywalls); persisting those
    /// behind an LRU cap is a planned follow-up. `generation` is the cache generation captured when the
    /// list fetch was issued (see ``getWorkflowsList(appUserID:isAppBackgrounded:onComplete:)``); it's
    /// forwarded to both the batched disk write and each ``getWorkflow``'s in-memory write, so an
    /// identity change landing any time after the list was fetched (including between caching the list
    /// and issuing a prefetch) drops the write and the previous user's details can't be written back
    /// after the store was cleared.
    func prefetchWorkflows(_ workflows: [WorkflowSummary],
                           appUserID: String,
                           isAppBackgrounded: Bool,
                           generation: Int,
                           onComplete: @escaping () -> Void) {
        let prefetchWorkflows = workflows.filter { $0.prefetch && $0.offeringId != nil }
        guard !prefetchWorkflows.isEmpty else {
            onComplete()
            return
        }

        // Lock-guarded counter so the batch persist + `onComplete` fire exactly once, after the last
        // prefetch lands, regardless of which thread each completion arrives on.
        let remaining: Atomic<Int> = .init(prefetchWorkflows.count)
        let resolved: Atomic<[String: WorkflowDataResult]> = .init([:])
        for summary in prefetchWorkflows {
            self.getWorkflow(appUserID: appUserID,
                             workflowId: summary.id,
                             isAppBackgrounded: isAppBackgrounded,
                             prefetch: true,
                             ifGeneration: generation,
                             staleWhileRevalidate: false) { result in
                if case let .success(dataResult) = result {
                    resolved.modify { $0[summary.id] = dataResult }
                }
                let left = remaining.modify { value -> Int in
                    value -= 1
                    return value
                }
                if left == 0 {
                    self.workflowsCache.persistWorkflowDetailsToDisk(resolved.value, ifGeneration: generation)
                    onComplete()
                }
            }
        }
    }

    func warmUpAssets(for result: WorkflowDataResult) {
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *),
           let paywallCache = self.paywallCache {
            self.operationDispatcher.dispatchOnWorkerThread {
                await paywallCache.warmUpWorkflowCaches(workflow: result.workflow)
            }
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WorkflowManager: @unchecked Sendable {}
