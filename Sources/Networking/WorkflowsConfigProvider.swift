//
//  WorkflowsConfigProvider.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

// swiftlint:disable file_length

import Foundation

protocol WorkflowsConfigProviderType {

    func workflowId(forOfferingId offeringId: String) async -> String?
    func getWorkflow(workflowId: String) async -> Result<WorkflowDataResult, WorkflowResolutionError>
    func decodeCachedWorkflowForAssetPrewarming(
        workflowId: String
    ) async -> Result<WorkflowDataResult, WorkflowResolutionError>
    @discardableResult
    func cacheEligibleWorkflowBodyData(currentOfferingId: String?) async -> Set<String>
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
///
/// Eligible workflows—items marked `prefetch` plus the current offering's workflow—are cached as raw body `Data`.
/// Normal reads decode and retain their result lazily. Asset prewarming instead uses a transient decode so it can
/// discover referenced assets without keeping every eligible workflow's component graph in memory.
final class WorkflowsConfigProvider: WorkflowsConfigProviderType {

    typealias WorkflowDecoder = (Data) throws -> PublishedWorkflow

    private let manager: RemoteConfigManagerType
    private let uiConfigProvider: UiConfigProvider
    private let workflowDecoder: WorkflowDecoder

    /// The offeringId → workflowId map built from the last topic snapshot seen, keyed by that snapshot
    /// so a repeat call with an unchanged topic reuses it instead of rescanning every item's content.
    private let cachedOfferingIdMap: Atomic<(topic: RemoteConfiguration.ConfigTopic, map: [String: String])?> = nil

    private let eligibleWorkflowsCache = GenerationGuardedCache<
        RemoteConfiguration.ConfigTopic,
        EligibleWorkflowCache
    >()

    init(
        manager: RemoteConfigManagerType,
        uiConfigProvider: UiConfigProvider? = nil,
        workflowDecoder: @escaping WorkflowDecoder = WorkflowsConfigProvider.decodeWorkflow
    ) {
        self.manager = manager
        self.uiConfigProvider = uiConfigProvider ?? UiConfigProvider(manager: manager)
        self.workflowDecoder = workflowDecoder
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
        // Deliberately sequential, not `async let`: a miss or malformed body returns without paying for
        // `ui_config`. A cached-body hit decodes synchronously from in-memory bytes on the caller's thread.
        if let cached = self.cachedWorkflowResult(workflowId: workflowId) {
            return await self.makeWorkflowResult(cached.result) {
                self.manager.configGeneration == cached.generation
            }
        }

        guard let snapshot = await self.manager.topicCacheSnapshot(.workflows),
              snapshot.key[workflowId] != nil else {
            return .failure(.notFound)
        }

        return await self.makeWorkflowResult(await self.fetchWorkflow(workflowId: workflowId)) {
            await self.manager.isCurrent(snapshot, for: .workflows)
        }
    }

    /// Decodes body data cached by ``cacheEligibleWorkflowBodyData(currentOfferingId:)`` without retaining the
    /// decoded workflow. The result stays alive only while the asset warmer uses it; an eventual render decodes
    /// normally.
    func decodeCachedWorkflowForAssetPrewarming(
        workflowId: String
    ) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        guard let cached = self.cachedWorkflowResult(workflowId: workflowId, retainDecodedResult: false) else {
            return .failure(.notFound)
        }

        return await self.makeWorkflowResult(cached.result) {
            self.manager.configGeneration == cached.generation
        }
    }

    /// Ensures raw body data is cached for workflows marked `prefetch` and for the current offering's workflow.
    ///
    /// This method never decodes a workflow. It returns only workflow IDs whose body data is available in the
    /// current config generation, allowing `WorkflowManager` to schedule transient decoding and asset prewarming.
    /// Missing bodies are omitted so one failed download does not prevent the remaining workflows from proceeding.
    @discardableResult
    func cacheEligibleWorkflowBodyData(currentOfferingId: String?) async -> Set<String> {
        return await Task.detached(priority: .utility) {
            await self.cacheEligibleWorkflowBodyDataOnBackgroundExecutor(currentOfferingId: currentOfferingId)
        }.value
    }

    private func cacheEligibleWorkflowBodyDataOnBackgroundExecutor(currentOfferingId: String?) async -> Set<String> {
        if let cache = self.currentWorkflowCache(),
           cache.containsEligibleWorkflowBodyData(currentOfferingId: currentOfferingId) {
            return cache.workflowIDsWhoseBodiesShouldBeCached(currentOfferingId: currentOfferingId)
        }
        guard let topic = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows) else { return [] }

        let snapshot = GenerationGuardedCacheSnapshot(
            generation: self.manager.configGeneration,
            key: topic
        )
        let offeringIdMap = self.buildOfferingIdMap(from: topic)
        let prefetchedWorkflowIds = Set(topic.compactMap { workflowId, item in
            item.prefetch ? workflowId : nil
        })
        let workflowIDsWhoseBodiesShouldBeCached = workflowIDsEligibleForBodyDataCaching(
            prefetchedWorkflowIds: prefetchedWorkflowIds,
            offeringIdMap: offeringIdMap,
            currentOfferingId: currentOfferingId
        )
        let cachedWorkflows = self.eligibleWorkflowsCache.value(for: snapshot)?.workflows ?? [:]
        guard !workflowIDsWhoseBodiesShouldBeCached.isSubset(of: cachedWorkflows.keys) else {
            return workflowIDsWhoseBodiesShouldBeCached
        }

        // Keep only body bytes in memory here. `LazyPublishedWorkflow` performs and retains the decode
        // synchronously on first access, so caching body data doesn't build every workflow's component graph.
        let workflowIDsMissingBodyData = workflowIDsWhoseBodiesShouldBeCached.subtracting(cachedWorkflows.keys)
        let newWorkflowEntries = await self.readWorkflowBodyData(for: workflowIDsMissingBodyData)

        guard await self.manager.isCurrent(snapshot, for: .workflows) else {
            self.eligibleWorkflowsCache.clearIfStale(currentGeneration: self.manager.configGeneration)
            return []
        }

        // Another concurrent cache operation may have populated more entries while the missing body data was read.
        // Preserve those entries (and any retained lazy decode results) when merging this result.
        let latestWorkflows = self.eligibleWorkflowsCache.value(for: snapshot)?.workflows ?? cachedWorkflows
        let workflows = latestWorkflows.merging(newWorkflowEntries) { cached, _ in cached }
        self.eligibleWorkflowsCache.store(
            .init(
                offeringIdMap: offeringIdMap,
                prefetchedWorkflowIds: prefetchedWorkflowIds,
                workflows: workflows
            ),
            for: snapshot
        )

        return workflowIDsWhoseBodiesShouldBeCached.intersection(workflows.keys)
    }

    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? {
        return self.manager.withCurrentConfigGeneration { generation in
            guard let cache = self.currentWorkflowCache(currentGeneration: generation) else { return nil }
            let workflowId = self.resolvedWorkflowId(forOfferingId: offeringId, in: cache)
            guard let uiConfig = self.uiConfigProvider.cachedUiConfig(currentGeneration: generation),
                  case let .success(workflow)? = cache.workflows[workflowId]?.value() else {
                return nil
            }

            return WorkflowDataResult(workflow: workflow, uiConfig: uiConfig, enrolledVariants: nil)
        }
    }

    private func resolvedWorkflowId(forOfferingId offeringId: String, in cache: EligibleWorkflowCache) -> String {
        // Fall back to treating the input as a workflow id, matching the async resolution path.
        return cache.offeringIdMap[offeringId] ?? offeringId
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

    private func makeWorkflowResult(
        _ workflowResult: Result<PublishedWorkflow, WorkflowResolutionError>,
        isCurrent: () async -> Bool
    ) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        let workflow: PublishedWorkflow
        switch workflowResult {
        case let .success(value):
            workflow = value
        case let .failure(error):
            return .failure(error)
        }

        guard let uiConfig = await self.uiConfigProvider.getUiConfig() else {
            return .failure(.uiConfigUnavailable)
        }
        guard await isCurrent() else { return .failure(.notFound) }

        return .success(WorkflowDataResult(workflow: workflow, uiConfig: uiConfig, enrolledVariants: nil))
    }

    private func cachedWorkflowResult(
        workflowId: String,
        retainDecodedResult: Bool = true
    ) -> (result: Result<PublishedWorkflow, WorkflowResolutionError>, generation: Int)? {
        return self.manager.withCurrentConfigGeneration { generation in
            guard let cache = self.currentWorkflowCache(currentGeneration: generation),
                  let workflow = cache.workflows[workflowId] else {
                return nil
            }
            let result = retainDecodedResult ? workflow.value() : workflow.transientValue()
            return (result: result, generation: generation)
        }
    }

    private func currentWorkflowCache() -> EligibleWorkflowCache? {
        return self.manager.withCurrentConfigGeneration { generation in
            self.currentWorkflowCache(currentGeneration: generation)
        }
    }

    private func currentWorkflowCache(currentGeneration: Int) -> EligibleWorkflowCache? {
        return self.eligibleWorkflowsCache.value(currentGeneration: currentGeneration)
    }

    private func readWorkflowBodyData(for workflowIds: Set<String>) async -> [String: LazyPublishedWorkflow] {
        await withTaskGroup(of: (String, Data?).self) { group in
            for workflowId in workflowIds {
                group.addTask {
                    return (workflowId, await self.manager.blobData(for: .workflows, itemKey: workflowId))
                }
            }

            var workflows: [String: LazyPublishedWorkflow] = [:]
            for await (workflowId, data) in group {
                if let data {
                    workflows[workflowId] = LazyPublishedWorkflow(
                        data: data,
                        decoder: self.workflowDecoder
                    )
                }
            }
            return workflows
        }
    }

    private static func decodeWorkflow(data: Data) throws -> PublishedWorkflow {
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    private static let offeringIdentifierKey = "offeringIdentifier"

}

private func workflowIDsEligibleForBodyDataCaching(
    prefetchedWorkflowIds: Set<String>,
    offeringIdMap: [String: String],
    currentOfferingId: String?
) -> Set<String> {
    var workflowIds = prefetchedWorkflowIds

    if let currentOfferingId,
       let currentWorkflowId = offeringIdMap[currentOfferingId] {
        workflowIds.insert(currentWorkflowId)
    }

    return workflowIds
}

private struct EligibleWorkflowCache {
    let offeringIdMap: [String: String]
    let prefetchedWorkflowIds: Set<String>
    let workflows: [String: LazyPublishedWorkflow]

    func containsEligibleWorkflowBodyData(currentOfferingId: String?) -> Bool {
        return self.workflowIDsWhoseBodiesShouldBeCached(currentOfferingId: currentOfferingId)
            .isSubset(of: self.workflows.keys)
    }

    func workflowIDsWhoseBodiesShouldBeCached(currentOfferingId: String?) -> Set<String> {
        return workflowIDsEligibleForBodyDataCaching(
            prefetchedWorkflowIds: self.prefetchedWorkflowIds,
            offeringIdMap: self.offeringIdMap,
            currentOfferingId: currentOfferingId
        )
    }
}

/// Retains raw workflow bytes until first use, then atomically retains either the decoded workflow or
/// its decoding failure. This keeps cached-body reads synchronous without eagerly building every workflow graph.
private final class LazyPublishedWorkflow {

    private enum State {
        case data(Data)
        case decoded(Result<PublishedWorkflow, WorkflowResolutionError>)
    }

    private let decoder: WorkflowsConfigProvider.WorkflowDecoder
    private let state: Atomic<State>

    init(data: Data, decoder: @escaping WorkflowsConfigProvider.WorkflowDecoder) {
        self.decoder = decoder
        self.state = .init(.data(data))
    }

    func value() -> Result<PublishedWorkflow, WorkflowResolutionError> {
        return self.state.modify { state in
            switch state {
            case let .decoded(result):
                return result
            case let .data(data):
                let result = self.decode(data)
                state = .decoded(result)
                return result
            }
        }
    }

    /// Decodes raw bytes without changing the cached state. If a real read already retained a decoded value,
    /// reuse it; otherwise release this temporary graph after its caller finishes prewarming assets.
    func transientValue() -> Result<PublishedWorkflow, WorkflowResolutionError> {
        return self.state.modify { state in
            switch state {
            case let .decoded(result):
                return result
            case let .data(data):
                return self.decode(data)
            }
        }
    }

    private func decode(_ data: Data) -> Result<PublishedWorkflow, WorkflowResolutionError> {
        do {
            return .success(try self.decoder(data))
        } catch {
            Logger.error(Strings.codable.decoding_error(error, PublishedWorkflow.self))
            return .failure(.decodingFailed(error as NSError))
        }
    }

}

extension LazyPublishedWorkflow: @unchecked Sendable {}
