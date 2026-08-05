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

/// The result of resolving a checkpoint against RevenueCat configuration.
@_spi(Internal) public enum CheckpointResolution {

    /// A workflow was selected for the checkpoint.
    case workflow(ResolvedCheckpointWorkflow)
    /// No workflow should run for the checkpoint.
    case noAction(CheckpointResolutionReason)

}

/// An extensible reason that checkpoint resolution selected no workflow.
@_spi(Internal) public struct CheckpointResolutionReason: Equatable, Hashable, Sendable {

    /// The raw reason value.
    public let value: String

    /// No targeting rule matched.
    public static let noMatch = Self(value: "NO_MATCH")
    /// Checkpoint configuration could not be loaded.
    public static let configurationUnavailable = Self(value: "CONFIGURATION_UNAVAILABLE")
    /// Checkpoints are disabled.
    public static let disabled = Self(value: "DISABLED")

    init(value: String) {
        self.value = value
    }

}

/// A workflow resolved from RevenueCat configuration and ready for RevenueCatUI to present.
@_spi(Internal) public final class ResolvedCheckpointWorkflow: @unchecked Sendable {

    /// The workflow to render.
    public let workflow: PublishedWorkflow
    /// UI configuration used to render the workflow.
    public let uiConfig: UIConfig
    /// The offering referenced by the workflow.
    public let offering: Offering

    init(workflow: PublishedWorkflow, uiConfig: UIConfig, offering: Offering) {
        self.workflow = workflow
        self.uiConfig = uiConfig
        self.offering = offering
    }

}

/// Resolves a checkpoint to the workflow that should run, or the reason no workflow should run.
protocol CheckpointWorkflowResolver: AnyObject {

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution

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

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution {
        switch identifier {
        case Self.simulatedErrorCheckpointIdentifier:
            throw PurchasesError(
                error: .configurationError,
                userInfo: [
                    NSLocalizedDescriptionKey: "Simulated error: checkpoint workflow not presentable."
                ]
            )
        case Self.simulatedNoMatchCheckpointIdentifier:
            return .noAction(.noMatch)
        default:
            break
        }

        guard let workflowManager else {
            return .noAction(.disabled)
        }

        let availableWorkflows = await workflowManager.availableWorkflows()
        guard let selectedWorkflow = self.chooseWorkflow(availableWorkflows) else {
            return .noAction(.configurationUnavailable)
        }

        let workflowData: WorkflowDataResult
        do {
            workflowData = try await workflowManager.getWorkflow(workflowId: selectedWorkflow.workflowID)
        } catch {
            Logger.error(error.localizedDescription)
            return .noAction(.configurationUnavailable)
        }

        guard let offeringID = selectedWorkflow.offeringID else {
            return .noAction(.configurationUnavailable)
        }

        let offering: Offering
        do {
            let offerings = try await self.getOfferings()
            guard let resolvedOffering = offerings.offering(identifier: offeringID) else {
                return .noAction(.configurationUnavailable)
            }
            offering = resolvedOffering
        } catch {
            Logger.error(error.localizedDescription)
            return .noAction(.configurationUnavailable)
        }

        return .workflow(
            ResolvedCheckpointWorkflow(
                workflow: workflowData.workflow,
                uiConfig: workflowData.uiConfig,
                offering: offering
            )
        )
    }

    private static let simulatedNoMatchCheckpointIdentifier = "unknown_checkpoint"
    private static let simulatedErrorCheckpointIdentifier = "error_checkpoint"

}

final class UnavailableCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution {
        return .noAction(.disabled)
    }

}
