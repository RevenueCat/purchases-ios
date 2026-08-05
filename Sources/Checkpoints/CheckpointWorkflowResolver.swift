//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowResolver.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Resolves a checkpoint to the workflow that should run, or the reason no workflow should run.
protocol CheckpointWorkflowResolver: AnyObject {

    func resolve(checkpoint: CheckpointInfo) async -> CheckpointWorkflowResolution

}

enum CheckpointWorkflowResolution {

    case matched(CheckpointEnginePresentation)
    case noMatch(CheckpointNoActionReason)
    case failed(PurchasesError)

}

/// A checkpoint presentation backed by a workflow resolved from RevenueCat configuration.
@_spi(Internal) public final class ResolvedCheckpointWorkflowPresentation: CheckpointEnginePresentation {

    /// The workflow to render.
    public let workflow: PublishedWorkflow

    /// UI configuration used to render the workflow.
    public let uiConfig: UIConfig

    /// The offering referenced by the workflow.
    public let offering: Offering

    init(
        checkpoint: CheckpointInfo,
        workflow: PublishedWorkflow,
        uiConfig: UIConfig,
        offering: Offering
    ) {
        self.workflow = workflow
        self.uiConfig = uiConfig
        self.offering = offering
        super.init(checkpoint: checkpoint)
    }

}

/// Temporary production resolver used until checkpoint targeting configuration is available.
/// Every checkpoint currently resolves to a randomly selected configured workflow, except two identifiers that
/// simulate the no-match and error resolutions the future checkpoints configuration will produce.
final class RandomWorkflowCheckpointResolver: CheckpointWorkflowResolver {

    typealias GetOfferings = () async throws -> Offerings
    typealias ChooseWorkflow = ([String: String?]) -> (workflowID: String, offeringID: String?)?

    private let workflowManager: WorkflowManager?
    private let getOfferings: GetOfferings
    private let chooseWorkflow: ChooseWorkflow

    init(
        workflowManager: WorkflowManager?,
        getOfferings: @escaping GetOfferings,
        chooseWorkflow: @escaping ChooseWorkflow = { workflows in
            return workflows.randomElement().map { ($0.key, $0.value) }
        }
    ) {
        self.workflowManager = workflowManager
        self.getOfferings = getOfferings
        self.chooseWorkflow = chooseWorkflow
    }

    func resolve(checkpoint: CheckpointInfo) async -> CheckpointWorkflowResolution {
        if let simulatedResolution = Self.simulatedResolution(for: checkpoint.identifier) {
            return simulatedResolution
        }

        guard let workflowManager else {
            return .noMatch(.disabled)
        }

        let availableWorkflows = await workflowManager.availableWorkflows()
        guard let selectedWorkflow = self.chooseWorkflow(availableWorkflows) else {
            return .noMatch(.configurationUnavailable)
        }

        let workflowData: WorkflowDataResult
        do {
            workflowData = try await workflowManager.getWorkflow(workflowId: selectedWorkflow.workflowID)
        } catch {
            Logger.error(error.localizedDescription)
            return .noMatch(.configurationUnavailable)
        }

        guard let offeringID = selectedWorkflow.offeringID else {
            return .noMatch(.configurationUnavailable)
        }

        let offering: Offering
        do {
            let offerings = try await self.getOfferings()
            guard let resolvedOffering = offerings.offering(identifier: offeringID) else {
                return .noMatch(.configurationUnavailable)
            }
            offering = resolvedOffering
        } catch {
            Logger.error(error.localizedDescription)
            return .noMatch(.configurationUnavailable)
        }

        return .matched(
            ResolvedCheckpointWorkflowPresentation(
                checkpoint: checkpoint,
                workflow: workflowData.workflow,
                uiConfig: workflowData.uiConfig,
                offering: offering
            )
        )
    }

    private static func simulatedResolution(for identifier: String) -> CheckpointWorkflowResolution? {
        switch identifier {
        case Self.simulatedErrorCheckpointIdentifier:
            return .failed(
                PurchasesError(
                    error: .configurationError,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Simulated error: checkpoint workflow not presentable."
                    ]
                )
            )
        case Self.simulatedNoMatchCheckpointIdentifier:
            return .noMatch(.noMatch)
        default:
            return nil
        }
    }

    private static let simulatedNoMatchCheckpointIdentifier = "unknown_checkpoint"
    private static let simulatedErrorCheckpointIdentifier = "error_checkpoint"

}
