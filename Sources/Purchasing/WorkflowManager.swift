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

/// Starts asset prewarming for workflows selected by remote config without making offerings delivery wait for
/// workflow decoding or asset downloads. Implementations may await the workflow body data needed to enqueue that
/// work, but the asset-prewarming work itself is fire-and-forget.
protocol WorkflowAssetPrewarmingType: Sendable {

    func scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: String?) async

}

/// The consumer-facing entry point for reading workflows. It stays as the seam the SDK calls (so
/// `Purchases` and its public API are unchanged), but it is now a thin adapter that reads from the
/// `/v1/config` layer through ``WorkflowsConfigProvider`` instead of calling a dedicated
/// `/v1/workflows` backend endpoint.
///
/// Freshness comes from the shared remote-config sync, not from a workflows-specific cache: there is
/// no stale-while-revalidate, no disk fallback, and no synchronous cache seed here anymore — a
/// workflow body is a shared, content-addressed blob resolved (and downloaded on demand, deduped) by
/// `RemoteConfigManager`.
///
/// Workflow asset prewarming has two entry paths:
///
/// - **Read path:** `getWorkflow` and `cachedWorkflow` already have a decoded workflow. They schedule its asset
///   prewarming while returning that same decoded value to the caller.
/// - **Body-data path:** ``scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId:)`` first caches raw body
///   data for workflows marked `prefetch` plus the current offering's workflow. It then transiently decodes those
///   workflows on a background worker solely to discover their assets. That decode is never retained in
///   `LazyPublishedWorkflow`; the graph is released after the asset-prewarming task finishes.
///
/// Both paths use the same `PaywallCacheWarming` entry point, which deduplicates asset prewarming by workflow ID.
class WorkflowManager: WorkflowAssetPrewarmingType {

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

    /// Resolves `workflowId`, or throws the error explaining why it couldn't be resolved: genuinely
    /// missing, malformed, or missing its `ui_config`.
    func getWorkflow(workflowId: String) async throws -> WorkflowDataResult {
        switch await self.workflowsConfigProvider.getWorkflow(workflowId: workflowId) {
        case let .success(result):
            self.scheduleAssetPrewarming(for: result)
            return result
        case .failure(.notFound):
            throw BackendError.workflowNotFound(workflowId: workflowId)
        case let .failure(.decodingFailed(error)):
            throw BackendError.workflowDecodingFailed(workflowId: workflowId, error: error)
        case .failure(.uiConfigUnavailable):
            throw WorkflowError.uiConfigUnavailable(workflowId: workflowId)
        }
    }

    func workflowId(forOfferingId offeringId: String) async -> String? {
        return await self.workflowsConfigProvider.workflowId(forOfferingId: offeringId)
    }

    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? {
        guard let result = self.workflowsConfigProvider.cachedWorkflow(forOfferingId: offeringId) else {
            return nil
        }

        self.scheduleAssetPrewarming(for: result)
        return result
    }

    /// Resolves `offeringId` to its workflow for `Purchases.workflow(forOfferingIdentifier:)`. Fails
    /// fast when the offering has no mapped workflow: the config path has no lazy offering→workflow
    /// conversion, so a missing mapping means the offering simply has no workflow attached. It surfaces
    /// a distinct `offeringHasNoWorkflow` error (instead of a guaranteed-miss fetch by offering id) so
    /// the paywall can fall back to the offering's own paywall / the default paywall. A mapped workflow
    /// that fails to resolve still throws `workflowNotFound` and surfaces. Mirrors purchases-android's
    /// `presentWorkflow` (#3760).
    func getWorkflow(forOfferingId offeringId: String) async throws -> WorkflowDataResult {
        guard let workflowId = await self.workflowId(forOfferingId: offeringId) else {
            throw BackendError.offeringHasNoWorkflow(offeringId: offeringId)
        }
        return try await self.getWorkflow(workflowId: workflowId)
    }

    /// Caches the prefetched and current-offering workflow body data before scheduling its decode and asset
    /// prewarming in the background.
    ///
    /// The returned body IDs belong to the current config generation and are decoded transiently: the decoded
    /// graphs are passed to the shared asset-prewarming path without replacing their cached raw body data. A later
    /// presentation therefore performs the normal retained decode. Individual failures are ignored so one malformed
    /// workflow cannot prevent sibling workflows from prewarming or delay offerings delivery. The included
    /// offering's workflow is warmed first, then the remaining prefetched workflows are warmed sequentially.
    ///
    /// Only body-data readiness is awaited; decoding and downloads never delay offerings.
    func scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: String?) async {
        let workflowIDsWithCachedBodyData = await self.workflowsConfigProvider.cachePrefetchedWorkflowBodyData(
            includingOfferingId: includingOfferingId
        )
        guard !workflowIDsWithCachedBodyData.isEmpty else { return }

        self.operationDispatcher.dispatchOnWorkerThread { [weak self] in
            guard let self else { return }
            guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *), let paywallCache else { return }

            for workflowId in workflowIDsWithCachedBodyData {
                guard case let .success(result) = await self.workflowsConfigProvider
                    .decodeCachedWorkflowForAssetPrewarming(
                    workflowId: workflowId
                ) else { continue }

                await paywallCache.prewarmWorkflowAssets(workflow: result.workflow, uiConfig: result.uiConfig)
            }
        }
    }

}

private extension WorkflowManager {

    /// Fire-and-forget pre-download of a resolved workflow's images/videos/fonts. Remote config's own
    /// blob prefetch only covers the workflow's JSON body, not the assets it references.
    func scheduleAssetPrewarming(for result: WorkflowDataResult) {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *), let paywallCache else { return }

        self.operationDispatcher.dispatchOnWorkerThread {
            await paywallCache.prewarmWorkflowAssets(workflow: result.workflow, uiConfig: result.uiConfig)
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WorkflowManager: @unchecked Sendable {}

extension BackendError {

    /// Whether this error signals that an offering has no workflow attached (as opposed to a mapped
    /// workflow that failed to resolve, or a config outage, which must surface).
    var isOfferingWithoutWorkflow: Bool {
        guard case let .unexpectedBackendResponse(response, _, _) = self,
              case .offeringHasNoWorkflow = response else {
            return false
        }
        return true
    }

}

extension Error {

    /// SPI bridge so RevenueCatUI's paywall fallback can detect the no-workflow case without seeing the
    /// internal `BackendError` type. Forwards to ``BackendError/isOfferingWithoutWorkflow``.
    @_spi(Internal) public var isOfferingWithoutWorkflowError: Bool {
        (self as? BackendError)?.isOfferingWithoutWorkflow ?? false
    }

}
