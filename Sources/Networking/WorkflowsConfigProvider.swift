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

    /// The offeringId → workflowId map built from the last topic snapshot seen, keyed by that snapshot
    /// so a repeat call with an unchanged topic reuses it instead of rescanning every item's content.
    private let cachedOfferingIdMap: Atomic<(topic: RemoteConfiguration.ConfigTopic, map: [String: String])?> = nil

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
        self.uiConfigProvider = UiConfigProvider(manager: manager)
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
    /// A workflow is only rendered with real styling, never with `PublishedWorkflow`'s decode-time
    /// `.empty` placeholder, matching Android's `PaywallViewModel` failing the whole render when its
    /// concurrent `ui_config` fetch fails.
    ///
    /// `enrolled_variants` is not populated here: per-user A/B enrollment doesn't fit this shared,
    /// content-addressed read model and is being designed separately.
    ///
    /// Known limitation: the workflow body and `ui_config` are two independent reads through
    /// `RemoteConfigManager`. If an identity change (`clearCache()`) lands between them, the result can
    /// combine a workflow body from the config committed before the clear with `ui_config` from the one
    /// committed after. This is a narrow window (a config-committing identity change racing an in-flight
    /// workflow render) and `ui_config` is app/domain-level presentation data, not per-user; a stricter
    /// fix would need `RemoteConfigManager` to expose a way to validate both reads landed in the same
    /// sync generation.
    func getWorkflow(workflowId: String) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        // Deliberately sequential, not `async let`: an `async let` for `ui_config` started alongside the
        // workflow-body read would still be implicitly awaited (Swift cancels but does not fast-fail an
        // unconsumed `async let` when its scope exits) if the body turns out missing or malformed, so a
        // miss would pay for `ui_config`'s network reads anyway instead of returning immediately.
        var workflow: PublishedWorkflow
        switch await self.fetchWorkflow(workflowId: workflowId) {
        case let .success(fetched):
            workflow = fetched
        case let .failure(error):
            return .failure(error)
        }

        guard let uiConfig = await self.uiConfigProvider.getUiConfig() else {
            return .failure(.uiConfigUnavailable)
        }
        workflow = workflow.withUiConfig(uiConfig)

        return .success(WorkflowDataResult(workflow: workflow, enrolledVariants: nil))
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

    private static let offeringIdentifierKey = "offeringIdentifier"

}
