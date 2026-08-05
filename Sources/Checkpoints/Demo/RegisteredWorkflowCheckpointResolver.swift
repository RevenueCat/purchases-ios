//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RegisteredWorkflowCheckpointResolver.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Demo-only resolver for the bundled JSON workflows registered by CheckpointTester.
final class RegisteredWorkflowCheckpointResolver: CheckpointWorkflowResolver {

    private let workflowDataByIdentifier: [String: Data]

    init(workflowDataByIdentifier: [String: Data]) {
        self.workflowDataByIdentifier = workflowDataByIdentifier
    }

    func resolve(checkpoint: CheckpointInfo) async -> CheckpointWorkflowResolution {
        if checkpoint.identifier == Self.simulatedErrorCheckpointIdentifier {
            return .failed(
                ErrorUtils.configurationError(message: "Simulated error: checkpoint UI not presentable.")
            )
        }

        guard !self.workflowDataByIdentifier.isEmpty else {
            return .noMatch(.configurationUnavailable)
        }
        guard let workflowData = self.workflowDataByIdentifier[checkpoint.identifier] else {
            return .noMatch(.noMatch)
        }

        return .matched(
            DemoCheckpointWorkflowPresentation(
                checkpoint: checkpoint,
                workflowData: workflowData
            )
        )
    }

    private static let simulatedErrorCheckpointIdentifier = "error_checkpoint"

}
