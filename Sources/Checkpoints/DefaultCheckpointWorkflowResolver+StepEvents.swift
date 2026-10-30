//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultCheckpointWorkflowResolver+StepEvents.swift
//
//  Created by Rosie Watson on 10/30/26.

import Foundation

/// A workflow whose only step has no UI, together with that step.
struct SingleStepWorkflow {

    let workflowData: WorkflowDataResult
    let step: WorkflowStep

}

extension DefaultCheckpointWorkflowResolver {

    /// A step with no UI is the whole workflow: it starts when it is entered and completes once what it serves has
    /// loaded. A step that can't be served never completes.
    static func trackingStepEvents(
        for workflow: SingleStepWorkflow,
        traceID: String,
        into stepEvents: inout [WorkflowEvent],
        resolving: () async -> CheckpointResolution
    ) async -> CheckpointResolution {
        stepEvents.append(.stepStarted(
            .init(),
            Self.stepEventData(for: workflow, traceID: traceID, entryReason: .start)
        ))

        let resolution = await resolving()

        switch resolution {
        case .matchedOffering, .matchedAd:
            stepEvents.append(.stepCompleted(
                .init(),
                Self.stepEventData(for: workflow, traceID: traceID, entryReason: nil)
            ))
        case .matchedWorkflow, .noAction:
            break
        }

        return resolution
    }

    private static func stepEventData(
        for workflow: SingleStepWorkflow,
        traceID: String,
        entryReason: WorkflowEvent.EntryReason?
    ) -> WorkflowEvent.Data {
        let step = workflow.step
        let workflowData = workflow.workflowData

        return .init(
            workflowId: workflowData.workflow.id,
            stepId: step.id,
            traceId: traceID,
            stepType: step.type,
            entryReason: entryReason?.rawValue,
            isFirstStep: true,
            isLastStep: true,
            workflowBlobRef: workflowData.workflowBlobRef,
            fallbackOriginalStepId: step.fallbackOriginalStepId,
            experiment: step.experimentData(workflowBlobRef: workflowData.workflowBlobRef)
        )
    }

}
