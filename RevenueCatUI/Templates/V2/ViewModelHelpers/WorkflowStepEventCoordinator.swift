//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowStepEventCoordinator.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

/// Owns the per-impression workflow step event state machine and drives ``WorkflowStepEventTracker``
/// at the four emission points (initial step, forward, back, terminal). It exists so the emission
/// *sequence* and its gating (the "fire once", "only if a page rendered" rules that on Android live in
/// `PaywallViewModelImpl`) can be unit tested without rendering a live SwiftUI view: ``WorkflowPaywallView``
/// holds it as `@State` and delegates its lifecycle/navigation hooks to it.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowStepEventCoordinator {

    private let tracker: WorkflowStepEventTracker
    private var hasTrackedInitialStep = false
    private var hasTrackedTerminalCompletion = false
    private var hasTrackedAbandonment = false

    init(workflow: PublishedWorkflow, traceId: String, sink: @escaping (WorkflowEvent) -> Void) {
        self.tracker = WorkflowStepEventTracker(workflow: workflow, traceId: traceId, sink: sink)
    }

    /// Production entry point: each impression gets a fresh `traceId`, matching Android's per-impression
    /// `workflowTraceId`. Because the view creates the coordinator in `init`, a new presentation (new view
    /// identity) yields a new coordinator and therefore a new `traceId`.
    convenience init(workflow: PublishedWorkflow, sink: @escaping (WorkflowEvent) -> Void) {
        self.init(workflow: workflow, traceId: UUID().uuidString, sink: sink)
    }

    /// Emits the initial `stepStarted` once, and only if the initial step actually rendered. Mirrors
    /// Android firing the START event only when the initial workflow state is non-nil.
    func trackInitialStep(_ step: WorkflowStep?, hasRenderedPage: Bool) {
        guard !self.hasTrackedInitialStep, hasRenderedPage, let step else {
            return
        }
        self.hasTrackedInitialStep = true
        self.tracker.trackInitialStep(step)
    }

    /// Tracks a forward/back transition. When the destination failed to render (`renderedPageIsNil`), the
    /// step being left completes with no destination and no `stepStarted` is emitted (Android parity).
    func trackTransition(
        from fromStep: WorkflowStep?,
        to toStep: WorkflowStep,
        renderedPageIsNil: Bool,
        entryReason: WorkflowStepEventTracker.EntryReason
    ) {
        guard let fromStep else {
            return
        }
        if renderedPageIsNil {
            self.tracker.trackStepCompleted(fromStep, toStepId: nil)
        } else {
            self.tracker.trackNavigation(from: fromStep, to: toStep, entryReason: entryReason)
        }
    }

    /// Emits a terminal `stepCompleted` (no destination) once, and only if a page is currently rendered.
    /// A step that never rendered (initial build failure) or a forward/back destination that failed to
    /// render clears the rendered page, so this must not emit a `stepCompleted` with no preceding
    /// `stepStarted`. Mirrors Android keying terminal completion off `_workflowState.value?.currentStepId`,
    /// which is null when a step fails to render.
    func trackTerminalCompletion(currentStep: WorkflowStep?, hasRenderedPage: Bool) {
        guard !self.hasTrackedTerminalCompletion, hasRenderedPage, let currentStep else {
            return
        }
        self.hasTrackedTerminalCompletion = true
        self.tracker.trackStepCompleted(currentStep, toStepId: nil)
    }

    /// Emits a workflow-level `close` (abandonment) once, only if the workflow was dismissed without
    /// completing it and a page is currently rendered. Unlike `trackTerminalCompletion`, it is not a
    /// step-lifecycle signal and is not gated by `screen_type`: abandonment on a non-paywall step still
    /// fires. A completed purchase or a successful restore is a natural exit, not an abandonment, so
    /// `hasCompletedInSession` suppresses the event.
    func trackAbandonment(currentStep: WorkflowStep?, hasRenderedPage: Bool, hasCompletedInSession: Bool) {
        guard !self.hasTrackedAbandonment, !hasCompletedInSession, hasRenderedPage, let currentStep else {
            return
        }
        self.hasTrackedAbandonment = true
        self.tracker.trackClose(currentStep)
    }

}

#endif
