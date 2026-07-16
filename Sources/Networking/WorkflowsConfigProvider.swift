//
//  WorkflowsConfigProvider.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol WorkflowsConfigProviderType {

    func workflowId(forOfferingId offeringId: String) async -> String?
    func getWorkflow(workflowId: String) async -> Result<WorkflowDataResult, WorkflowResolutionError>
    func warmPrefetchedWorkflows() async
    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult?

}

/// Why ``WorkflowsConfigProviderType/getWorkflow(workflowId:)`` couldn't resolve a workflow, so callers
/// can tell a genuinely missing workflow apart from a transient or malformed-data failure.
enum WorkflowResolutionError: Error, Equatable {

    /// No item for this `workflowId` exists in the synced `workflows` topic.
    case notFound

    /// An item exists, but its body couldn't be decoded as a ``PublishedWorkflow``.
    case decodingFailed(NSError)

    /// The workflow itself resolved, but its `ui_config` couldn't be assembled.
    case uiConfigUnavailable

}

/// The topic-specific front door for workflows, reading through `RemoteConfigManager`'s `workflows`
/// topic instead of a dedicated `/v1/workflows` list+detail fetch. It knows only the `workflows` topic
/// name, that an item's offering id lives in its inline content under `offeringIdentifier`, and how to
/// parse a ``PublishedWorkflow``. Everything else is delegated to `RemoteConfigManager`.
final class WorkflowsConfigProvider: WorkflowsConfigProviderType {

    private let manager: RemoteConfigManagerType
    private let uiConfigProvider: UiConfigProvider
    private let paywallCache: PaywallCacheWarmingType?
    private let operationDispatcher: OperationDispatcher

    /// The offeringId → workflowId map built from the last topic snapshot seen, keyed by that snapshot
    /// so a repeat call with an unchanged topic reuses it instead of rescanning every item's content.
    private let cachedOfferingIdMap: Atomic<(topic: RemoteConfiguration.ConfigTopic, map: [String: String])?> = nil

    private let prefetchedWorkflowsCache = GenerationGuardedCache<
        RemoteConfiguration.ConfigTopic,
        PrefetchedWorkflowCache
    >()

    init(
        manager: RemoteConfigManagerType,
        uiConfigProvider: UiConfigProvider? = nil,
        paywallCache: PaywallCacheWarmingType? = nil,
        operationDispatcher: OperationDispatcher = .default
    ) {
        self.manager = manager
        self.uiConfigProvider = uiConfigProvider ?? UiConfigProvider(manager: manager)
        self.paywallCache = paywallCache
        self.operationDispatcher = operationDispatcher
    }

    /// Resolves `offeringId` to its workflow id via an offeringId → workflowId map built from the
    /// `workflows` topic's inline content, rebuilt only when the topic itself has changed.
    /// `content` keys go through `JSONDecoder`'s `.convertFromSnakeCase`, so the wire field
    /// `offering_identifier` is read as `offeringIdentifier`.
    func workflowId(forOfferingId offeringId: String) async -> String? {
        guard let topic = await self.manager.topic(.workflows) else { return nil }

        if let cached = self.cachedOfferingIdMap.value, cached.topic == topic {
            return cached.map[offeringId]
        }

        let map = self.buildOfferingIdMap(from: topic)
        self.cachedOfferingIdMap.value = (topic: topic, map: map)
        return map[offeringId]
    }

    /// Builds the offeringId → workflowId map in a stable pass over `topic`. A duplicate `offeringId`
    /// across items signals a backend issue and is logged once per rebuild; the last workflow id wins
    /// without relying on Swift dictionary iteration order.
    private func buildOfferingIdMap(from topic: RemoteConfiguration.ConfigTopic) -> [String: String] {
        var map: [String: String] = [:]
        var duplicateOfferingIds: Set<String> = []

        for workflowId in topic.keys.sorted() {
            guard let item = topic[workflowId] else { continue }
            guard case let .string(offeringId)? = item.content[Self.offeringIdentifierKey] else { continue }

            if map[offeringId] != nil {
                duplicateOfferingIds.insert(offeringId)
            }
            map[offeringId] = workflowId
        }

        for offeringId in duplicateOfferingIds.sorted() {
            Logger.warn(Strings.backendError.duplicate_offering_id_in_workflows(offeringId: offeringId))
        }

        return map
    }

    /// Resolves `workflowId` into a ``WorkflowDataResult``, or the specific ``WorkflowResolutionError``
    /// that prevented it: the item is unknown, its body can't be parsed, or `ui_config` isn't available.
    /// A workflow is only rendered with styling resolved from the `ui_config` topic, matching Android's
    /// `PaywallViewModel` failing the whole render when its concurrent `ui_config` fetch fails.
    ///
    /// `enrolled_variants` is not populated here: per-user A/B enrollment doesn't fit this shared,
    /// content-addressed read model and is being designed separately.
    ///
    /// Cache misses validate the workflow topic's generation after `ui_config` resolves, so an in-flight
    /// config change fails the resolution instead of returning a mixed-generation workflow/config pair.
    func getWorkflow(workflowId: String) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        if let cached = self.cachedWorkflow(workflowId: workflowId) {
            return .success(cached)
        }

        guard let snapshot = await self.manager.topicCacheSnapshot(.workflows),
              snapshot.key[workflowId] != nil else {
            return .failure(.notFound)
        }

        // Deliberately sequential, not `async let`: an `async let` for `ui_config` started alongside the
        // workflow-body read would still be implicitly awaited (Swift cancels but does not fast-fail an
        // unconsumed `async let` when its scope exits) if the body turns out missing or malformed, so a
        // miss would pay for `ui_config`'s network reads anyway instead of returning immediately.
        let workflow: PublishedWorkflow
        switch await self.fetchWorkflow(workflowId: workflowId) {
        case let .success(fetched):
            workflow = fetched
        case let .failure(error):
            return .failure(error)
        }

        guard let uiConfig = await self.uiConfigProvider.getUiConfig() else {
            return .failure(.uiConfigUnavailable)
        }
        guard await self.manager.isCurrent(snapshot, for: .workflows) else {
            return .failure(.notFound)
        }

        return .success(WorkflowDataResult(workflow: workflow, uiConfig: uiConfig, enrolledVariants: nil))
    }

    func warmPrefetchedWorkflows() async {
        await Task.detached(priority: .utility) {
            await self.warmPrefetchedWorkflowsOnBackgroundExecutor()
        }.value
    }

    private func warmPrefetchedWorkflowsOnBackgroundExecutor() async {
        guard self.currentWorkflowCache() == nil else { return }
        guard let topic = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows) else { return }
        guard self.currentWorkflowCache() == nil else { return }

        let snapshot = GenerationGuardedCacheSnapshot(
            generation: self.manager.configGeneration,
            key: topic
        )

        let offeringIdMap = self.buildOfferingIdMap(from: topic)
        let workflows = await self.decodePrefetchedWorkflows(from: topic)

        guard await self.manager.isCurrent(snapshot, for: .workflows) else {
            self.prefetchedWorkflowsCache.clearIfStale(currentGeneration: self.manager.configGeneration)
            return
        }

        self.prefetchedWorkflowsCache.store(
            .init(offeringIdMap: offeringIdMap, workflows: workflows),
            for: snapshot
        )

        self.warmPrefetchedWorkflowAssetsInBackground(workflows)
    }

    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? {
        return self.manager.withCurrentConfigGeneration { generation in
            guard let cache = self.currentWorkflowCache(currentGeneration: generation) else { return nil }
            let workflowId = cache.offeringIdMap[offeringId] ?? offeringId
            guard let workflow = cache.workflows[workflowId],
                  let uiConfig = self.uiConfigProvider.cachedUiConfig(currentGeneration: generation) else {
                return nil
            }

            return WorkflowDataResult(workflow: workflow, uiConfig: uiConfig, enrolledVariants: nil)
        }
    }

    private func fetchWorkflow(workflowId: String) async -> Result<PublishedWorkflow, WorkflowResolutionError> {
        do {
            guard let workflow = try await self.manager.blobData(
                for: .workflows, itemKey: workflowId, as: PublishedWorkflow.self
            ) else {
                return .failure(.notFound)
            }
            return .success(workflow)
        } catch {
            Logger.error(Strings.codable.decoding_error(error, PublishedWorkflow.self))
            return .failure(.decodingFailed(error as NSError))
        }
    }

    private func cachedWorkflow(workflowId: String) -> WorkflowDataResult? {
        return self.manager.withCurrentConfigGeneration { generation in
            guard let cache = self.currentWorkflowCache(currentGeneration: generation),
                  let workflow = cache.workflows[workflowId],
                  let uiConfig = self.uiConfigProvider.cachedUiConfig(currentGeneration: generation) else {
                return nil
            }

            return WorkflowDataResult(workflow: workflow, uiConfig: uiConfig, enrolledVariants: nil)
        }
    }

    private func currentWorkflowCache() -> PrefetchedWorkflowCache? {
        return self.manager.withCurrentConfigGeneration { generation in
            self.currentWorkflowCache(currentGeneration: generation)
        }
    }

    private func currentWorkflowCache(currentGeneration: Int) -> PrefetchedWorkflowCache? {
        return self.prefetchedWorkflowsCache.value(currentGeneration: currentGeneration)
    }

    private func decodePrefetchedWorkflows(
        from topic: RemoteConfiguration.ConfigTopic
    ) async -> [String: PublishedWorkflow] {
        await withTaskGroup(of: (String, PublishedWorkflow?).self) { group in
            // swiftlint:disable:next todo
            // TODO: Measure warmup performance with large remote configs and cap this fan-out into batches
            // if decoding many prefetched workflows at once creates CPU or memory pressure.
            for workflowId in topic.keys.sorted() {
                guard topic[workflowId]?.prefetch == true else { continue }
                group.addTask {
                    do {
                        return (
                            workflowId,
                            try await self.manager.blobData(
                                for: .workflows,
                                itemKey: workflowId,
                                as: PublishedWorkflow.self
                            )
                        )
                    } catch {
                        Logger.error(Strings.codable.decoding_error(error, PublishedWorkflow.self))
                        return (workflowId, nil)
                    }
                }
            }

            var workflows: [String: PublishedWorkflow] = [:]
            for await (workflowId, workflow) in group {
                if let workflow {
                    workflows[workflowId] = workflow
                }
            }
            return workflows
        }
    }

    private func warmPrefetchedWorkflowAssetsInBackground(_ workflows: [String: PublishedWorkflow]) {
        self.operationDispatcher.dispatchOnWorkerThread {
            await self.warmPrefetchedWorkflowAssets(workflows)
        }
    }

    private func warmPrefetchedWorkflowAssets(_ workflows: [String: PublishedWorkflow]) async {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *),
              let paywallCache,
              let uiConfig = await self.uiConfigProvider.getUiConfig() else {
            return
        }

        for workflowId in workflows.keys.sorted() {
            guard let workflow = workflows[workflowId] else { continue }
            await paywallCache.warmUpWorkflowCaches(workflow: workflow, uiConfig: uiConfig)
        }
    }

    private static let offeringIdentifierKey = "offeringIdentifier"

}

private struct PrefetchedWorkflowCache {
    let offeringIdMap: [String: String]
    let workflows: [String: PublishedWorkflow]
}
