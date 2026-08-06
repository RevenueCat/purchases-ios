//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RandomWorkflowCheckpointResolver.swift
//
//  Created by Rick van der Linden.
//

import Foundation

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
        chooseWorkflow: @escaping ChooseWorkflow = RandomWorkflowCheckpointResolver.chooseRandomWorkflow
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

    static func chooseRandomWorkflow(
        from workflows: [String: String?]
    ) -> (workflowID: String, offeringID: String?)? {
        return workflows.compactMap { workflowID, offeringID in
            return offeringID.map { (workflowID, $0) }
        }.randomElement()
    }

}
