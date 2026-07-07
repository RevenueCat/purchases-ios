//
//  WorkflowsConfigProvider.swift
//  RevenueCat
//
//  Created by RevenueCat.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol WorkflowsConfigProviderType {

    func workflowId(forOfferingId offeringId: String) async -> String?
    func getWorkflow(workflowId: String) async -> WorkflowDataResult?

}

/// The topic-specific front door for workflows, reading through `RemoteConfigManager`'s `workflows`
/// topic instead of a dedicated `/v1/workflows` list+detail fetch. It knows only the `workflows` topic
/// name, that an item's offering id lives in its inline content under `offeringIdentifier`, and how to
/// parse a ``PublishedWorkflow``. Everything else is delegated to `RemoteConfigManager`.
final class WorkflowsConfigProvider: WorkflowsConfigProviderType {

    private let manager: RemoteConfigManagerType
    private let uiConfigProvider: UiConfigProvider

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
        self.uiConfigProvider = UiConfigProvider(manager: manager)
    }

    /// Resolves `offeringId` to its workflow id by scanning the `workflows` topic's inline content.
    /// `content` keys go through `JSONDecoder`'s `.convertFromSnakeCase`, so the wire field
    /// `offering_identifier` is read as `offeringIdentifier`.
    ///
    /// A duplicate `offeringId` across items signals a backend issue and is logged; whichever match
    /// the dictionary happens to iterate first wins, since there's no principled way to prefer one
    /// over another.
    func workflowId(forOfferingId offeringId: String) async -> String? {
        guard let topic = await self.manager.topic(.workflows) else { return nil }

        let matches = topic.filter { _, item in
            guard case let .string(value)? = item.content[Self.offeringIdentifierKey] else { return false }
            return value == offeringId
        }

        if matches.count > 1 {
            Logger.warn(Strings.backendError.duplicate_offering_id_in_workflows(offeringId: offeringId))
        }

        return matches.keys.first
    }

    /// Resolves `workflowId` into a ``WorkflowDataResult``, or `nil` when the item is unknown, its body
    /// can't be read or parsed, or `ui_config` isn't available. A workflow is only rendered with real
    /// styling, never with `PublishedWorkflow`'s decode-time `.empty` placeholder, matching Android's
    /// `PaywallViewModel` failing the whole render when its concurrent `ui_config` fetch fails.
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
    func getWorkflow(workflowId: String) async -> WorkflowDataResult? {
        // Deliberately sequential, not `async let`: an `async let` for `ui_config` started alongside the
        // workflow-body read would still be implicitly awaited (Swift cancels but does not fast-fail an
        // unconsumed `async let` when its scope exits) if the body turns out missing or malformed, so a
        // miss would pay for `ui_config`'s network reads anyway instead of returning immediately.
        guard var workflow = await self.fetchWorkflow(workflowId: workflowId) else {
            return nil
        }

        guard let uiConfig = await self.uiConfigProvider.getUiConfig() else {
            return nil
        }
        workflow = workflow.withUiConfig(uiConfig)

        return WorkflowDataResult(workflow: workflow, enrolledVariants: nil)
    }

    private func fetchWorkflow(workflowId: String) async -> PublishedWorkflow? {
        do {
            return try await self.manager.blobData(for: .workflows, itemKey: workflowId, as: PublishedWorkflow.self)
        } catch {
            Logger.error(Strings.codable.decoding_error(error, PublishedWorkflow.self))
            return nil
        }
    }

    private static let offeringIdentifierKey = "offeringIdentifier"

}
