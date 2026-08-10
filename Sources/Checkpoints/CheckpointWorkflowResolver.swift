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

/// The reason that checkpoint resolution selected no workflow.
@_spi(Internal) public enum CheckpointResolutionReason: Sendable {

    /// No targeting rule matched.
    case noMatch
    /// Checkpoint configuration could not be loaded.
    case configurationUnavailable
    /// Checkpoints are disabled.
    case disabled
    /// The checkpoint identifier is not configured.
    case unknownCheckpoint

}

/// A workflow resolved from RevenueCat configuration and ready for RevenueCatUI to present.
@_spi(Internal) public final class ResolvedCheckpointWorkflow: @unchecked Sendable {

    /// The workflow to render.
    public let workflow: PublishedWorkflow
    /// UI configuration used to render the workflow.
    public let uiConfig: UIConfig
    /// The offering referenced by the workflow.
    public let offering: Offering
    /// All offerings available while executing the workflow.
    public let offerings: Offerings

    init(workflow: PublishedWorkflow, uiConfig: UIConfig, offering: Offering, offerings: Offerings) {
        self.workflow = workflow
        self.uiConfig = uiConfig
        self.offering = offering
        self.offerings = offerings
    }

}

/// Resolves a checkpoint to the workflow that should run, or the reason no workflow should run.
protocol CheckpointWorkflowResolver: AnyObject {

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution

}

final class DisabledCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution {
        return .noAction(.disabled)
    }

}
