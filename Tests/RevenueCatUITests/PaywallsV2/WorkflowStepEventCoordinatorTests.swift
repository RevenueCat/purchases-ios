//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowStepEventCoordinatorTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WorkflowStepEventCoordinatorTests: TestCase {

    private var recorded: [WorkflowEvent] = []

    override func setUp() {
        super.setUp()
        self.recorded = []
    }

    // MARK: - Initial step

    func testInitialStepEmitsStartWhenPageRendered() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackInitialStep(step, hasRenderedPage: true)

        expect(self.recorded).to(haveCount(1))
        let data = try XCTUnwrap(Self.startedData(self.recorded[0]))
        expect(data.stepId) == "step_1"
        expect(data.entryReason) == "start"
        expect(data.isFirstStep) == true
    }

    func testInitialStepDoesNotEmitWhenNoPageRendered() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackInitialStep(step, hasRenderedPage: false)

        expect(self.recorded).to(beEmpty())
    }

    func testInitialStepFiresOnlyOnceAcrossRebuilds() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackInitialStep(step, hasRenderedPage: true)
        coordinator.trackInitialStep(step, hasRenderedPage: true)

        expect(self.recorded).to(haveCount(1))
    }

    // MARK: - Forward / back transitions

    func testForwardTransitionEmitsCompletedThenStartedInOrder() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let from = try XCTUnwrap(workflow.steps["step_1"])
        let toStep = try XCTUnwrap(workflow.steps["step_2"])

        coordinator.trackTransition(from: from, to: toStep, renderedPageIsNil: false, entryReason: .forward)

        expect(self.recorded).to(haveCount(2))
        let completed = try XCTUnwrap(Self.completedData(self.recorded[0]))
        expect(completed.stepId) == "step_1"
        expect(completed.toStepId) == "step_2"
        let started = try XCTUnwrap(Self.startedData(self.recorded[1]))
        expect(started.stepId) == "step_2"
        expect(started.fromStepId) == "step_1"
        expect(started.entryReason) == "forward"
    }

    func testBackTransitionUsesBackReason() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let from = try XCTUnwrap(workflow.steps["step_2"])
        let toStep = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackTransition(from: from, to: toStep, renderedPageIsNil: false, entryReason: .back)

        expect(self.recorded).to(haveCount(2))
        let started = try XCTUnwrap(Self.startedData(self.recorded[1]))
        expect(started.stepId) == "step_1"
        expect(started.entryReason) == "back"
    }

    func testTransitionWithFailedRenderEmitsCompletedOnly() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let from = try XCTUnwrap(workflow.steps["step_1"])
        let toStep = try XCTUnwrap(workflow.steps["step_2"])

        coordinator.trackTransition(from: from, to: toStep, renderedPageIsNil: true, entryReason: .forward)

        expect(self.recorded).to(haveCount(1))
        let completed = try XCTUnwrap(Self.completedData(self.recorded[0]))
        expect(completed.stepId) == "step_1"
        expect(completed.toStepId).to(beNil())
    }

    func testTransitionWithNilFromStepEmitsNothing() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let toStep = try XCTUnwrap(workflow.steps["step_2"])

        coordinator.trackTransition(from: nil, to: toStep, renderedPageIsNil: false, entryReason: .forward)

        expect(self.recorded).to(beEmpty())
    }

    // MARK: - Terminal completion (migrated from WorkflowPaywallView.shouldTrackTerminalCompletion)

    func testTerminalCompletionEmitsWhenPageRenderedAndNotYetTracked() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_2"])

        coordinator.trackTerminalCompletion(currentStep: step, hasRenderedPage: true)

        expect(self.recorded).to(haveCount(1))
        let completed = try XCTUnwrap(Self.completedData(self.recorded[0]))
        expect(completed.stepId) == "step_2"
        expect(completed.toStepId).to(beNil())
    }

    func testTerminalCompletionDoesNotEmitWhenNoPageRendered() throws {
        // A step that never rendered (initial build failure) or a forward/back destination that failed to
        // render clears `currentPage`. Terminal completion must not fire, otherwise it emits a
        // `stepCompleted` with no preceding `stepStarted`. Mirrors Android's null `_workflowState`.
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_2"])

        coordinator.trackTerminalCompletion(currentStep: step, hasRenderedPage: false)

        expect(self.recorded).to(beEmpty())
    }

    func testTerminalCompletionFiresOnlyOnce() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_2"])

        coordinator.trackTerminalCompletion(currentStep: step, hasRenderedPage: true)
        coordinator.trackTerminalCompletion(currentStep: step, hasRenderedPage: true)

        expect(self.recorded).to(haveCount(1))
    }

    // MARK: - Abandonment (workflow_close)

    func testAbandonmentEmitsCloseForCurrentStepWhenNotPurchased() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackAbandonment(currentStep: step, hasRenderedPage: true, hasCompletedInSession: false)

        expect(self.recorded).to(haveCount(1))
        let data = try XCTUnwrap(Self.closeData(self.recorded[0]))
        expect(data.stepId) == "step_1"
        // step_1 navigates to step_2, so it is the first but not the terminal step.
        expect(data.isFirstStep) == true
        expect(data.isLastStep) == false
    }

    func testAbandonmentStampsTerminalStepPosition() throws {
        // workflow_close is not gated by step position; it just stamps it. On the terminal step
        // isLastStep is true (analytics decides downstream whether that counts as abandonment).
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_2"])

        coordinator.trackAbandonment(currentStep: step, hasRenderedPage: true, hasCompletedInSession: false)

        let data = try XCTUnwrap(Self.closeData(self.recorded.first))
        expect(data.stepId) == "step_2"
        expect(data.isFirstStep) == false
        expect(data.isLastStep) == true
    }

    func testAbandonmentDoesNotEmitWhenCompleted() throws {
        // A completed purchase or successful restore is a natural exit, not an abandonment.
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackAbandonment(currentStep: step, hasRenderedPage: true, hasCompletedInSession: true)

        expect(self.recorded).to(beEmpty())
    }

    func testAbandonmentDoesNotEmitWhenNoPageRendered() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackAbandonment(currentStep: step, hasRenderedPage: false, hasCompletedInSession: false)

        expect(self.recorded).to(beEmpty())
    }

    func testAbandonmentFiresOnlyOnce() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        coordinator.trackAbandonment(currentStep: step, hasRenderedPage: true, hasCompletedInSession: false)
        coordinator.trackAbandonment(currentStep: step, hasRenderedPage: true, hasCompletedInSession: false)

        expect(self.recorded).to(haveCount(1))
    }

    // MARK: - Trace id continuity

    func testFullJourneyEmitsExpectedSequenceSharingOneTraceId() throws {
        let workflow = try Self.makeWorkflow()
        let coordinator = self.makeCoordinator(workflow: workflow, traceId: "trace-journey")
        let step1 = try XCTUnwrap(workflow.steps["step_1"])
        let step2 = try XCTUnwrap(workflow.steps["step_2"])

        // appear -> forward -> back -> dismiss
        coordinator.trackInitialStep(step1, hasRenderedPage: true)
        coordinator.trackTransition(from: step1, to: step2, renderedPageIsNil: false, entryReason: .forward)
        coordinator.trackTransition(from: step2, to: step1, renderedPageIsNil: false, entryReason: .back)
        coordinator.trackTerminalCompletion(currentStep: step1, hasRenderedPage: true)

        expect(self.recorded).to(haveCount(6))
        let kinds = self.recorded.map { Self.kind($0) }
        expect(kinds) == ["started", "completed", "started", "completed", "started", "completed"]
        let traceIds = self.recorded.map { $0.data.traceId }
        expect(traceIds.allSatisfy { $0 == "trace-journey" }) == true
    }

    func testNewImpressionGetsNewTraceId() throws {
        let workflow = try Self.makeWorkflow()
        let step = try XCTUnwrap(workflow.steps["step_1"])

        // Two coordinators created via the production initializer (which generates a fresh traceId each).
        self.makeCoordinator(workflow: workflow, freshTraceId: true).trackInitialStep(step, hasRenderedPage: true)
        self.makeCoordinator(workflow: workflow, freshTraceId: true).trackInitialStep(step, hasRenderedPage: true)

        expect(self.recorded).to(haveCount(2))
        expect(self.recorded[0].data.traceId) != self.recorded[1].data.traceId
    }

    // MARK: - Storage boundary (journey -> MockPurchases.track(workflowEvent:))

    func testJourneyReachesWorkflowEventBoundaryWithoutLeakingPaywallEvents() async throws {
        let workflow = try Self.makeWorkflow()
        let step1 = try XCTUnwrap(workflow.steps["step_1"])
        let step2 = try XCTUnwrap(workflow.steps["step_2"])

        let trackedPaywallEvents: Atomic<[PaywallEvent]> = .init([])
        let trackedWorkflowEvents: Atomic<[WorkflowEvent]> = .init([])
        let mock = MockPurchases(
            purchase: { _, _, _ in
                (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
            },
            restorePurchases: { TestData.customerInfo },
            trackEvent: { event in trackedPaywallEvents.modify { $0.append(event) } },
            customerInfo: { TestData.customerInfo }
        )
        mock.trackWorkflowEventBlock = { event in trackedWorkflowEvents.modify { $0.append(event) } }
        let eventTracker = PaywallEventTracker(
            purchases: mock,
            eventDispatcher: PaywallEventTrackerTestDispatcher.value
        )
        let coordinator = WorkflowStepEventCoordinator(workflow: workflow) { event in
            eventTracker.track(event)
        }

        coordinator.trackInitialStep(step1, hasRenderedPage: true)
        coordinator.trackTransition(from: step1, to: step2, renderedPageIsNil: false, entryReason: .forward)
        coordinator.trackTerminalCompletion(currentStep: step2, hasRenderedPage: true)

        // The async dispatcher does not guarantee delivery order, so assert content/count, not sequence.
        await expect(trackedWorkflowEvents.value).toEventually(haveCount(4), timeout: .seconds(2))
        let traceIds = Set(trackedWorkflowEvents.value.map { $0.data.traceId })
        expect(traceIds).to(haveCount(1))
        let stepIds = Set(trackedWorkflowEvents.value.map { $0.data.stepId })
        expect(stepIds) == Set(["step_1", "step_2"])
        expect(trackedPaywallEvents.value).to(beEmpty())
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowStepEventCoordinatorTests {

    func makeCoordinator(
        workflow: PublishedWorkflow,
        traceId: String = "trace-test",
        freshTraceId: Bool = false
    ) -> WorkflowStepEventCoordinator {
        let sink: (WorkflowEvent) -> Void = { [weak self] event in self?.recorded.append(event) }
        if freshTraceId {
            return WorkflowStepEventCoordinator(workflow: workflow, sink: sink)
        }
        return WorkflowStepEventCoordinator(workflow: workflow, traceId: traceId, sink: sink)
    }

    /// step_1 navigates to step_2 (a terminal step with no further `.step` action).
    static func makeWorkflow() throws -> PublishedWorkflow {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test Workflow",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": {
              "id": "step_1",
              "type": "screen",
              "triggers": [
                {"name":"Button","type":"on_press","action_id":"btn","component_id":"btn"}
              ],
              "trigger_actions": { "btn": {"type":"step","step_id":"step_2"} }
            },
            "step_2": { "id": "step_2", "type": "screen", "triggers": [], "trigger_actions": {} }
          },
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    static func startedData(_ event: WorkflowEvent) -> WorkflowEvent.Data? {
        guard case let .stepStarted(_, data) = event else { return nil }
        return data
    }

    static func completedData(_ event: WorkflowEvent) -> WorkflowEvent.Data? {
        guard case let .stepCompleted(_, data) = event else { return nil }
        return data
    }

    static func closeData(_ event: WorkflowEvent?) -> WorkflowEvent.Data? {
        guard case let .close(_, data) = event else { return nil }
        return data
    }

    static func kind(_ event: WorkflowEvent) -> String {
        switch event {
        case .stepStarted: return "started"
        case .stepCompleted: return "completed"
        case .close: return "close"
        }
    }

}

#endif
