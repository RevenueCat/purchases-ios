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

    case matched(CheckpointWorkflowPresentation)
    case noMatch(CheckpointNoActionReason)
    case failed(PurchasesError)

}

/// Input supplied to a checkpoint presenter.
@_spi(Internal) public class CheckpointWorkflowPresentation {

    /// The checkpoint that resolved this presentation.
    public let checkpoint: CheckpointInfo

    init(checkpoint: CheckpointInfo) {
        self.checkpoint = checkpoint
    }

}

/// A checkpoint presentation backed by a workflow resolved from RevenueCat configuration.
@_spi(Internal) public final class ResolvedCheckpointWorkflowPresentation: CheckpointWorkflowPresentation {

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
/// Every checkpoint currently resolves to the first configured workflow.
final class FirstWorkflowCheckpointResolver: CheckpointWorkflowResolver {

    typealias GetOfferings = @Sendable () async throws -> Offerings

    private let workflowManager: WorkflowManager?
    private let getOfferings: GetOfferings

    init(workflowManager: WorkflowManager?, getOfferings: @escaping GetOfferings) {
        self.workflowManager = workflowManager
        self.getOfferings = getOfferings
    }

    func resolve(checkpoint: CheckpointInfo) async -> CheckpointWorkflowResolution {
        guard let workflowManager else {
            return .noMatch(.disabled)
        }

        guard let workflowID = await workflowManager.firstAvailableWorkflowID() else {
            return .noMatch(.configurationUnavailable)
        }

        let workflowData: WorkflowDataResult
        do {
            workflowData = try await workflowManager.getWorkflow(workflowId: workflowID)
        } catch {
            Logger.error(error.localizedDescription)
            return .noMatch(.configurationUnavailable)
        }

        guard let offeringID = workflowData.workflow.initialOfferingIdentifier else {
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

}

private extension PublishedWorkflow {

    var initialOfferingIdentifier: String? {
        guard let initialStep = self.steps[self.initialStepId],
              let screenID = initialStep.screenId,
              let screen = self.screens[screenID] else {
            return nil
        }

        return screen.offeringIdentifier
    }

}
