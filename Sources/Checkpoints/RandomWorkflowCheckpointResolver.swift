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

    typealias WorkflowSelector = ([String: String?]) -> (workflowID: String, offeringID: String?)?

    private let workflowManager: WorkflowManager
    private let offeringsProvider: () async throws -> Offerings
    private let workflowSelector: WorkflowSelector

    init(
        workflowManager: WorkflowManager,
        offeringsProvider: @escaping () async throws -> Offerings,
        workflowSelector: @escaping WorkflowSelector = RandomWorkflowCheckpointResolver.chooseRandomWorkflow
    ) {
        self.workflowManager = workflowManager
        self.offeringsProvider = offeringsProvider
        self.workflowSelector = workflowSelector
    }

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution {
        switch identifier {
        case Self.simulatedErrorCheckpointIdentifier:
            throw ErrorUtils.configurationError(
                message: "Simulated error: checkpoint workflow not presentable."
            )
        case Self.simulatedNoMatchCheckpointIdentifier:
            return .noAction(.noMatch)
        default:
            break
        }

        let offeringIdByWorkflowId = await self.workflowManager.offeringIdByWorkflowId()
        guard let selectedWorkflow = self.workflowSelector(offeringIdByWorkflowId) else {
            return .noAction(.configurationUnavailable)
        }

        let workflowData: WorkflowDataResult
        do {
            workflowData = try await self.workflowManager.getWorkflow(workflowId: selectedWorkflow.workflowID)
        } catch {
            Logger.error(error.localizedDescription)
            return .noAction(.configurationUnavailable)
        }

        guard let offeringID = selectedWorkflow.offeringID else {
            return .noAction(.configurationUnavailable)
        }

        let offering: Offering
        do {
            let offerings = try await self.offeringsProvider()
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
