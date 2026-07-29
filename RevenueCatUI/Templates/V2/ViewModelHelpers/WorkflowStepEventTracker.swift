//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowStepEventTracker.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

/// Builds and emits ``WorkflowEvent`` step lifecycle events for a single workflow impression.
///
/// Ported from purchases-android's `PaywallViewModelImpl` step tracking. iOS splits navigation
/// (``WorkflowNavigator``) and rendering (``WorkflowPaywallView``) across two objects, so this
/// tracker is a small collaborator the view drives at each navigation/dismiss point rather than a
/// method on the navigator. The `traceId` is fixed for the tracker's lifetime, which on iOS equals
/// one workflow presentation (it is owned by `@State` in the view), matching Android's per-impression
/// `workflowTraceId`. The `sink` is injectable so the event sequence can be unit tested.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowStepEventTracker {

    enum EntryReason: String {
        case start
        case forward
        case back
    }

    private let workflow: PublishedWorkflow
    private let traceId: String
    private let sink: (WorkflowEvent) -> Void

    init(
        workflow: PublishedWorkflow,
        traceId: String,
        sink: @escaping (WorkflowEvent) -> Void
    ) {
        self.workflow = workflow
        self.traceId = traceId
        self.sink = sink
    }

    /// Emits `stepStarted` for the first step shown in the impression.
    func trackInitialStep(_ step: WorkflowStep) {
        self.trackStepStarted(step, fromStepId: nil, entryReason: .start)
    }

    /// Emits `stepCompleted` for the step being left, then `stepStarted` for the step being entered.
    /// Mirrors Android's `trackWorkflowStepNavigation`.
    func trackNavigation(from fromStep: WorkflowStep, to toStep: WorkflowStep, entryReason: EntryReason) {
        self.trackStepCompleted(fromStep, toStepId: toStep.id)
        self.trackStepStarted(toStep, fromStepId: fromStep.id, entryReason: entryReason)
    }

    /// Emits a standalone `stepCompleted`. Used for terminal dismissals (`toStepId == nil`) and for the
    /// error path where the next step fails to render (the step being left completes with no destination).
    func trackStepCompleted(_ step: WorkflowStep, toStepId: String?) {
        self.sink(
            .stepCompleted(
                .init(),
                self.data(for: step, fromStepId: nil, toStepId: toStepId, entryReason: nil)
            )
        )
    }

    /// Emits a `close` for the step the user abandoned the workflow on. Unlike the terminal
    /// `stepCompleted`, this is a workflow-level abandonment signal and is not gated by `screen_type`,
    /// so abandonment on a non-paywall step is still captured. The step's position is stamped via
    /// `isFirstStep`/`isLastStep`; analytics defines "abandonment" from those downstream.
    func trackClose(_ step: WorkflowStep) {
        self.sink(
            .close(
                .init(),
                self.data(for: step, fromStepId: nil, toStepId: nil, entryReason: nil)
            )
        )
    }

    private func trackStepStarted(_ step: WorkflowStep, fromStepId: String?, entryReason: EntryReason) {
        self.sink(
            .stepStarted(
                .init(),
                self.data(for: step, fromStepId: fromStepId, toStepId: nil, entryReason: entryReason.rawValue)
            )
        )
    }

    private func data(
        for step: WorkflowStep,
        fromStepId: String?,
        toStepId: String?,
        entryReason: String?
    ) -> WorkflowEvent.Data {
        // No locale is set here: Android's #3487 wiring does not populate it (its `context.locale`
        // defaults to null). iOS's `WorkflowEvent.Data` defaults `localeIdentifier` to the device
        // locale (a deliberate choice in #6858), which this wiring defers to rather than overriding.
        return .init(
            workflowId: self.workflow.id,
            stepId: step.id,
            traceId: self.traceId,
            fromStepId: fromStepId,
            toStepId: toStepId,
            entryReason: entryReason,
            isFirstStep: step.id == self.workflow.initialStepId,
            isLastStep: Self.isTerminalStep(step)
        )
    }

    /// A step is terminal when none of its trigger actions navigate to another step. Mirrors Android's
    /// `isTerminalStep` (`triggerActions.values.none { it is WorkflowTriggerAction.Step }`).
    static func isTerminalStep(_ step: WorkflowStep) -> Bool {
        return !step.stepTriggerActions.values.contains { action in
            if case .step = action { return true }
            return false
        }
    }

}

#endif
