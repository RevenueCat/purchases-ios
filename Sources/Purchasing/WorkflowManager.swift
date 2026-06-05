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
    /// On a cache miss (or stale entry) it fetches from the backend, caches the result, and warms up
    /// its assets before delivering it.
    ///
    /// When `persistDetail` is `true` (the prefetch path) a successful fetch is also persisted to
    /// disk, so a later cold start with the backend down can restore and render it offline. Only the
    /// prefetch path sets this: prefetched workflows are the curated, bounded set the backend marked
    /// as mattering, so persisting all of them is safe. The on-demand path leaves it `false` to avoid
    /// unbounded disk growth (a session can open many distinct paywalls); persisting those behind an
    /// LRU cap is a planned follow-up.
    func getWorkflow(appUserID: String,
                     workflowId: String,
                     isAppBackgrounded: Bool,
                     persistDetail: Bool = false,
                     completion: @escaping (Result<WorkflowDataResult, BackendError>) -> Void) {
        if let cached = self.workflowsCache.cachedWorkflow(workflowId: workflowId),
           !self.workflowsCache.isWorkflowCacheStale(workflowId: workflowId, isAppBackgrounded: isAppBackgrounded) {
            completion(.success(cached))
            return
        }

        self.backend.workflowsAPI.getWorkflow(appUserID: appUserID,
                                              workflowId: workflowId,
                                              isAppBackgrounded: isAppBackgrounded) { [weak self] result in
            guard let self else {
                completion(result)
                return
            }
            if case let .success(dataResult) = result {
                self.workflowsCache.cache(workflow: dataResult, workflowId: workflowId)
                if persistDetail {
                    self.workflowsCache.cache(workflowDetail: dataResult, workflowId: workflowId)
                }
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

        self.backend.workflowsAPI.getWorkflows(appUserID: appUserID,
                                               isAppBackgrounded: isAppBackgrounded,
                                               type: Self.paywallWorkflowType) { [weak self] result in
            guard let self else {
                onComplete()
                return
            }
            switch result {
            case let .success(response):
                self.workflowsCache.cache(workflowsList: response)
                self.prefetchWorkflows(response.workflows,
                                       appUserID: appUserID,
                                       isAppBackgrounded: isAppBackgrounded,
                                       onComplete: onComplete)
            case let .failure(error):
                Logger.error(Strings.paywalls.error_fetching_workflows_list(error))
                // Restore the in-memory offeringId -> workflowId map from the last list persisted on
                // disk, so `cachedWorkflowId(forOfferingId:)` keeps resolving previously-fetched data after
                // a backend failure instead of returning nil. The entry stays stale so the next
                // fetch still retries the backend.
                self.workflowsCache.restoreWorkflowsListFromDisk()
                // Restore the prefetched workflow details persisted on disk into the in-memory cache
                // so a cold start with the backend down can still render them. They're restored fresh
                // (like a normal fetch) so `getWorkflow` serves them offline; the refresh is driven by
                // the list being restored stale above, which refetches once the backend is back.
                self.restoreWorkflowDetailsFromDisk()
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
    func prefetchWorkflows(_ workflows: [WorkflowSummary],
                           appUserID: String,
                           isAppBackgrounded: Bool,
                           onComplete: @escaping () -> Void) {
        let prefetchWorkflows = workflows.filter { $0.prefetch && $0.offeringId != nil }
        guard !prefetchWorkflows.isEmpty else {
            onComplete()
            return
        }

        // Lock-guarded counter so `onComplete` fires exactly once, after the last prefetch lands,
        // regardless of which thread each completion arrives on.
        let remaining: Atomic<Int> = .init(prefetchWorkflows.count)
        for summary in prefetchWorkflows {
            self.getWorkflow(appUserID: appUserID,
                             workflowId: summary.id,
                             isAppBackgrounded: isAppBackgrounded,
                             persistDetail: true) { _ in
                let left = remaining.modify { value -> Int in
                    value -= 1
                    return value
                }
                if left == 0 {
                    onComplete()
                }
            }
        }
    }

    /// Restores the prefetched workflow details persisted on disk into the in-memory cache, so a
    /// later ``getWorkflow(appUserID:workflowId:isAppBackgrounded:persistDetail:completion:)`` is a
    /// cache hit with no failed network call on the render path. No-op when nothing is persisted.
    func restoreWorkflowDetailsFromDisk() {
        guard let details = self.workflowsCache.cachedWorkflowDetailsFromDisk() else { return }
        for (workflowId, result) in details {
            self.workflowsCache.cache(workflow: result, workflowId: workflowId)
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
