//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowStepEventTrackerTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowStepEventTrackerTests: TestCase {

    private var recorded: [WorkflowEvent] = []

    override func setUp() {
        super.setUp()
        self.recorded = []
    }

    // MARK: - Initial step

    func testTrackInitialStepEmitsStepStartedWithStartReason() throws {
        let workflow = try Self.makeWorkflow()
        let tracker = self.makeTracker(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        tracker.trackInitialStep(step)

        expect(self.recorded).to(haveCount(1))
        let data = try XCTUnwrap(Self.startedData(self.recorded[0]))
        expect(data.stepId) == "step_1"
        expect(data.fromStepId).to(beNil())
        expect(data.entryReason) == "start"
        expect(data.isFirstStep) == true
        expect(data.isLastStep) == false
        expect(data.workflowId) == "wf_test"
    }

    // MARK: - Forward / back navigation

    func testTrackForwardNavigationEmitsCompletedThenStartedInOrder() throws {
        let workflow = try Self.makeWorkflow()
        let tracker = self.makeTracker(workflow: workflow)
        let from = try XCTUnwrap(workflow.steps["step_1"])
        let toStep = try XCTUnwrap(workflow.steps["step_2"])

        tracker.trackNavigation(from: from, to: toStep, entryReason: .forward)

        expect(self.recorded).to(haveCount(2))
        let completed = try XCTUnwrap(Self.completedData(self.recorded[0]))
        expect(completed.stepId) == "step_1"
        expect(completed.toStepId) == "step_2"

        let started = try XCTUnwrap(Self.startedData(self.recorded[1]))
        expect(started.stepId) == "step_2"
        expect(started.fromStepId) == "step_1"
        expect(started.entryReason) == "forward"
        expect(started.isLastStep) == true
    }

    func testTrackBackNavigationUsesBackEntryReason() throws {
        let workflow = try Self.makeWorkflow()
        let tracker = self.makeTracker(workflow: workflow)
        let from = try XCTUnwrap(workflow.steps["step_2"])
        let toStep = try XCTUnwrap(workflow.steps["step_1"])

        tracker.trackNavigation(from: from, to: toStep, entryReason: .back)

        expect(self.recorded).to(haveCount(2))
        let started = try XCTUnwrap(Self.startedData(self.recorded[1]))
        expect(started.stepId) == "step_1"
        expect(started.fromStepId) == "step_2"
        expect(started.entryReason) == "back"
    }

    // MARK: - Terminal completion / build failure

    func testTrackStepCompletedWithNilToStepIdEmitsCompletedOnly() throws {
        let workflow = try Self.makeWorkflow()
        let tracker = self.makeTracker(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_2"])

        tracker.trackStepCompleted(step, toStepId: nil)

        expect(self.recorded).to(haveCount(1))
        let completed = try XCTUnwrap(Self.completedData(self.recorded[0]))
        expect(completed.stepId) == "step_2"
        expect(completed.toStepId).to(beNil())
        expect(completed.isLastStep) == true
    }

    // MARK: - Trace id continuity

    func testTraceIdIsStableAcrossSequence() throws {
        let workflow = try Self.makeWorkflow()
        let tracker = self.makeTracker(workflow: workflow, traceId: "trace-abc")
        let step1 = try XCTUnwrap(workflow.steps["step_1"])
        let step2 = try XCTUnwrap(workflow.steps["step_2"])

        tracker.trackInitialStep(step1)
        tracker.trackNavigation(from: step1, to: step2, entryReason: .forward)
        tracker.trackStepCompleted(step2, toStepId: nil)

        expect(self.recorded).to(haveCount(4))
        let traceIds = self.recorded.map { $0.data.traceId }
        expect(traceIds.allSatisfy { $0 == "trace-abc" }) == true
    }

    // MARK: - Experiment fields

    func testExperimentFieldsAreNilToMatchAndroid() throws {
        let workflow = try Self.makeWorkflow()
        let tracker = self.makeTracker(workflow: workflow)
        let step = try XCTUnwrap(workflow.steps["step_1"])

        tracker.trackInitialStep(step)

        let data = self.recorded[0].data
        expect(data.experimentId).to(beNil())
        expect(data.experimentVariant).to(beNil())
        expect(data.isLastVariantStep).to(beNil())
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowStepEventTrackerTests {

    func makeTracker(
        workflow: PublishedWorkflow,
        traceId: String = "trace-test"
    ) -> WorkflowStepEventTracker {
        return WorkflowStepEventTracker(
            workflow: workflow,
            traceId: traceId,
            sink: { [weak self] event in self?.recorded.append(event) }
        )
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

}

#endif
