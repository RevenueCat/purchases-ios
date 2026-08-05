//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowExecutor.swift
//
//  Created by Rick van der Linden.
//

/// Runs a workflow resolved for a checkpoint.
protocol CheckpointWorkflowExecutor: AnyObject {

    @MainActor
    func execute(_ presentation: CheckpointWorkflowPresentation) async throws -> CheckpointWorkflowOutcome

}

/// The terminal outcome of executing a checkpoint workflow.
///
/// Paywalls are the only supported workflow today. Additional workflow types can add internal cases here without
/// changing the public checkpoint result hierarchy.
enum CheckpointWorkflowOutcome {

    case paywallFinished(CheckpointPaywallOutcome)

}
