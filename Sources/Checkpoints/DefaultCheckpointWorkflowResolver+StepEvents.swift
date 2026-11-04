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

extension DefaultCheckpointWorkflowResolver {

    /// A step with no UI is the whole workflow: it starts when it is entered and completes once what it serves has
    /// loaded. A step that can't be served never completes.
    static func trackingStepEvents(
        for step: WorkflowStep,
        in workflowData: WorkflowDataResult,
        traceID: String,
        resolving: () async -> CheckpointResolution
    ) async -> (resolution: CheckpointResolution, stepEvents: [WorkflowEvent]) {
        var stepEvents: [WorkflowEvent] = [.stepStarted(
            .init(),
            Self.stepEventData(for: step, in: workflowData, traceID: traceID, entryReason: .start)
        )]

        let resolution = await resolving()

        switch resolution {
        case .matchedOffering, .matchedAd:
            stepEvents.append(.stepCompleted(
                .init(),
                Self.stepEventData(for: step, in: workflowData, traceID: traceID, entryReason: nil)
            ))
        case .matchedWorkflow, .noAction:
            break
        }

        return (resolution, stepEvents)
    }

    private static func stepEventData(
        for step: WorkflowStep,
        in workflowData: WorkflowDataResult,
        traceID: String,
        entryReason: WorkflowEvent.EntryReason?
    ) -> WorkflowEvent.Data {
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
