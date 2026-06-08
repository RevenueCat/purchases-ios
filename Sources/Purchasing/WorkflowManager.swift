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

    /// Resolves a workflow, serving a fresh cached result without a backend round-trip when possible.
    /// On a cache miss (or stale entry) it fetches from the backend, caches the result in memory, and
    /// warms up its assets before delivering it. Disk persistence of prefetched details is handled by
    /// ``prefetchWorkflows(_:appUserID:isAppBackgrounded:onComplete:)``, not here.
    func getWorkflow(appUserID: String,
                     workflowId: String,
                     isAppBackgrounded: Bool,
                     prefetch: Bool = false,
                     completion: @escaping (Result<WorkflowDataResult, BackendError>) -> Void) {
        if let cached = self.workflowsCache.cachedWorkflow(workflowId: workflowId),
           !self.workflowsCache.isWorkflowCacheStale(workflowId: workflowId, isAppBackgrounded: isAppBackgrounded) {
            completion(.success(cached))
            return
        }

        // Capture the cache generation when the request is issued. If an identity change clears the
        // cache while this fetch is in flight, the in-memory write below is dropped, so a result
        // fetched for the previous user (workflow detail is user-scoped) can't repopulate memory.
        let generation = self.workflowsCache.currentCacheGeneration()
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
                                          ifGeneration: generation)
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
    /// list fetch was issued (see ``getWorkflowsList(appUserID:isAppBackgrounded:onComplete:)``); it
    /// guards the disk write against an identity change landing mid-prefetch, so the previous user's
    /// details can't be written back after the store was cleared. Each ``getWorkflow`` call guards its
    /// own in-memory write the same way.
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
                             prefetch: true) { result in
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
