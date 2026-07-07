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

/// The consumer-facing entry point for reading workflows. It stays as the seam the SDK calls (so
/// `Purchases` and its public API are unchanged), but it is now a thin adapter that reads from the
/// `/v1/config` layer through ``WorkflowsConfigProvider`` instead of calling a dedicated
/// `/v1/workflows` backend endpoint.
///
/// Freshness comes from the shared remote-config sync, not from a workflows-specific cache: there is
/// no stale-while-revalidate, no disk fallback, and no synchronous cache seed here anymore — a
/// workflow body is a shared, content-addressed blob resolved (and downloaded on demand, deduped) by
/// `RemoteConfigManager`.
class WorkflowManager {

    private let workflowsConfigProvider: WorkflowsConfigProviderType
    private let paywallCache: PaywallCacheWarmingType?
    private let operationDispatcher: OperationDispatcher

    init(
        workflowsConfigProvider: WorkflowsConfigProviderType,
        paywallCache: PaywallCacheWarmingType?,
        operationDispatcher: OperationDispatcher
    ) {
        self.workflowsConfigProvider = workflowsConfigProvider
        self.paywallCache = paywallCache
        self.operationDispatcher = operationDispatcher
    }

    /// Resolves `workflowId` and delivers it through `completion`, or a `BackendError` distinguishing
    /// why it couldn't be resolved: genuinely missing, malformed, or missing its `ui_config`.
    func getWorkflow(workflowId: String, completion: @escaping (Result<WorkflowDataResult, BackendError>) -> Void) {
        Async.call(with: completion) {
            switch await self.workflowsConfigProvider.getWorkflow(workflowId: workflowId) {
            case let .success(result):
                self.warmUpAssets(for: result)
                return .success(result)
            case .failure(.notFound):
                return .failure(.workflowNotFound(workflowId: workflowId))
            case let .failure(.decodingFailed(error)):
                return .failure(.workflowDecodingFailed(workflowId: workflowId, error: error))
            case .failure(.uiConfigUnavailable):
                return .failure(.workflowUiConfigUnavailable(workflowId: workflowId))
            }
        }
    }

    func workflowId(forOfferingId offeringId: String) async -> String? {
        return await self.workflowsConfigProvider.workflowId(forOfferingId: offeringId)
    }

    /// Synchronous cache seed used to render a workflow paywall without waiting on the async path.
    /// There is no synchronous read on the remote-config layer, so this always returns `nil`; callers
    /// already treat a `nil` result as a normal cache miss and fall back to the async
    /// ``getWorkflow(workflowId:completion:)``.
    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? {
        return nil
    }

}

private extension WorkflowManager {

    /// Fire-and-forget pre-download of a resolved workflow's images/videos/fonts. Remote config's own
    /// blob prefetch only covers the workflow's JSON body, not the assets it references.
    func warmUpAssets(for result: WorkflowDataResult) {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *), let paywallCache else { return }

        self.operationDispatcher.dispatchOnWorkerThread {
            await paywallCache.warmUpWorkflowCaches(workflow: result.workflow)
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WorkflowManager: @unchecked Sendable {}
