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
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

#if !os(tvOS)

/// Owns the per-impression workflow step event state machine and drives ``WorkflowStepEventTracker``
/// at the four emission points (initial step, forward, back, terminal). It exists so the emission
/// *sequence* and its gating (the "fire once", "only if a page rendered" rules) can be unit tested without
/// rendering a live SwiftUI view: ``WorkflowPaywallView`` holds it as `@State` and delegates its
/// lifecycle/navigation hooks to it.
///
/// For forward/back navigation it also measures how long the user waited: from the navigation being
/// triggered (the tap) until the main thread has committed the first frame showing the destination step.
/// The destination's `stepStarted` is held until that frame and sent with `navigationDurationMs`. A held
/// event is sent without the duration before any later workflow event, so event order and count do not
/// change.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowStepEventCoordinator {

    /// Calls `onFrame` once, after the next frame is committed.
    typealias NextFrameObserver = (_ onFrame: @escaping () -> Void) -> Void

    private let tracker: WorkflowStepEventTracker
    /// `nil` where frames cannot be observed; navigation is then tracked without a duration.
    private let nextFrameObserver: NextFrameObserver?
    private let uptime: () -> TimeInterval
    private var pendingStepStarted: PendingStepStarted?
    private var hasTrackedInitialStep = false
    private var hasTrackedTerminalCompletion = false
    private var hasTrackedAbandonment = false

    var traceId: String { self.tracker.traceId }

    init(
        workflow: PublishedWorkflow,
        traceId: String,
        workflowBlobRef: String? = nil,
        nextFrameObserver: NextFrameObserver? = WorkflowNextFrameObserver.observe,
        uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        sink: @escaping (WorkflowEvent) -> Void
    ) {
        self.tracker = WorkflowStepEventTracker(
            workflow: workflow,
            traceId: traceId,
            workflowBlobRef: workflowBlobRef,
            sink: sink
        )
        self.nextFrameObserver = nextFrameObserver
        self.uptime = uptime
    }

    /// Mints a fresh `traceId` for the impression.
    convenience init(
        workflow: PublishedWorkflow,
        workflowBlobRef: String? = nil,
        sink: @escaping (WorkflowEvent) -> Void
    ) {
        self.init(workflow: workflow, traceId: UUID().uuidString, workflowBlobRef: workflowBlobRef, sink: sink)
    }

    deinit {
        self.flushPendingStepStarted()
    }

    /// The time to pass back as `navigationStartedAt`. Take it first thing in a navigation handler, so the
    /// work of building the destination counts.
    func navigationStartTime() -> TimeInterval {
        return self.uptime()
    }

    /// Emits the initial `stepStarted` once, and only if the initial step actually rendered.
    func trackInitialStep(_ step: WorkflowStep?, hasRenderedPage: Bool) {
        guard !self.hasTrackedInitialStep, hasRenderedPage, let step else {
            return
        }
        self.hasTrackedInitialStep = true
        self.tracker.trackInitialStep(step)
    }

    /// Tracks a forward/back transition. When the destination failed to render (`renderedPageIsNil`), the
    /// step being left completes with no destination and no `stepStarted` is emitted.
    ///
    /// With `navigationStartedAt` and a frame observer, the destination's `stepStarted` waits for the next
    /// frame and carries `navigationDurationMs`.
    func trackTransition(
        from fromStep: WorkflowStep?,
        to toStep: WorkflowStep,
        renderedPageIsNil: Bool,
        entryReason: WorkflowEvent.EntryReason,
        navigationStartedAt: TimeInterval? = nil
    ) {
        guard let fromStep else {
            return
        }
        self.flushPendingStepStarted()
        if renderedPageIsNil {
            self.tracker.trackStepCompleted(fromStep, toStepId: nil)
            return
        }
        guard let nextFrameObserver = self.nextFrameObserver, let navigationStartedAt else {
            self.tracker.trackNavigation(from: fromStep, to: toStep, entryReason: entryReason)
            return
        }

        self.tracker.trackStepCompleted(fromStep, toStepId: toStep.id)
        let pending = PendingStepStarted(
            step: toStep,
            fromStepId: fromStep.id,
            entryReason: entryReason,
            navigationStartedAt: navigationStartedAt
        )
        self.pendingStepStarted = pending
        nextFrameObserver { [weak self] in
            guard let self, self.pendingStepStarted?.id == pending.id else { return }
            let elapsed = self.uptime() - pending.navigationStartedAt
            self.sendPendingStepStarted(navigationDurationMs: max(0, Int((elapsed * 1000).rounded())))
        }
    }

    /// Emits a terminal `stepCompleted` (no destination) once, and only if a page is currently rendered.
    /// A step that never rendered (initial build failure) or a forward/back destination that failed to
    /// render clears the rendered page, so this must not emit a `stepCompleted` with no preceding
    /// `stepStarted`.
    func trackTerminalCompletion(currentStep: WorkflowStep?, hasRenderedPage: Bool) {
        self.flushPendingStepStarted()
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
        self.flushPendingStepStarted()
        guard !self.hasTrackedAbandonment, !hasCompletedInSession, hasRenderedPage, let currentStep else {
            return
        }
        self.hasTrackedAbandonment = true
        self.tracker.trackClose(currentStep)
    }

    // MARK: - Navigation duration

    private struct PendingStepStarted {
        let id = UUID()
        /// Stamped at navigation, so a held event keeps the time the step was entered.
        let creationData = WorkflowEvent.CreationData()
        let step: WorkflowStep
        let fromStepId: String
        let entryReason: WorkflowEvent.EntryReason
        let navigationStartedAt: TimeInterval
    }

    /// Sends a held `stepStarted` without a duration, before anything that must come after it.
    private func flushPendingStepStarted() {
        self.sendPendingStepStarted(navigationDurationMs: nil)
    }

    private func sendPendingStepStarted(navigationDurationMs: Int?) {
        guard let pending = self.pendingStepStarted else { return }
        self.pendingStepStarted = nil
        self.tracker.trackStepStarted(
            pending.step,
            fromStepId: pending.fromStepId,
            entryReason: pending.entryReason,
            navigationDurationMs: navigationDurationMs,
            creationData: pending.creationData
        )
    }

}

/// Reports the next display refresh after the current main run loop pass. SwiftUI commits pending view
/// updates at the end of that pass, so the callback marks the first frame that includes them, minus the
/// render server's time to draw it.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WorkflowNextFrameObserver {

    #if canImport(UIKit) && !os(watchOS)
    static let observe: WorkflowStepEventCoordinator.NextFrameObserver? = { onFrame in
        let target = DisplayLinkTarget(onFrame: onFrame)
        // The display link retains its target until it is invalidated on the first callback.
        CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.fire(_:)))
            .add(to: .main, forMode: .common)
    }

    private final class DisplayLinkTarget: NSObject {

        private let onFrame: () -> Void

        init(onFrame: @escaping () -> Void) {
            self.onFrame = onFrame
        }

        @objc func fire(_ link: CADisplayLink) {
            link.invalidate()
            self.onFrame()
        }

    }
    #else
    static let observe: WorkflowStepEventCoordinator.NextFrameObserver? = nil
    #endif

}

#endif
