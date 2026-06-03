//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowNavigatorTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowNavigatorTests: TestCase {

    // MARK: - Initialization

    func testCurrentStepIdStartsAtInitialStepId() throws {
        let workflow = try Self.makeWorkflow(initialStepId: "step_1")
        let navigator = WorkflowNavigator(workflow: workflow)

        expect(navigator.currentStepId) == "step_1"
    }

    func testCurrentStepReturnsCorrectStep() throws {
        let workflow = try Self.makeWorkflow(initialStepId: "step_1")
        let navigator = WorkflowNavigator(workflow: workflow)

        expect(navigator.currentStep?.id) == "step_1"
    }

    func testCanNavigateBackIsFalseInitially() throws {
        let workflow = try Self.makeWorkflow(initialStepId: "step_1")
        let navigator = WorkflowNavigator(workflow: workflow)

        expect(navigator.canNavigateBack) == false
    }

    // MARK: - triggerAction happy path

    func testTriggerActionAdvancesStepAndReturnsNewStep() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_abc", "btn_abc")], triggerActions: [("btn_abc", "step_2")]),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.triggerAction(componentId: "btn_abc")

        expect(result?.id) == "step_2"
        expect(navigator.currentStepId) == "step_2"
    }

    func testTriggerActionGrowsBackStack() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_abc", "btn_abc")], triggerActions: [("btn_abc", "step_2")]),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        navigator.triggerAction(componentId: "btn_abc")

        expect(navigator.canNavigateBack) == true
    }

    // MARK: - triggerAction failure cases

    func testTriggerActionWithUnknownComponentIdReturnsNil() throws {
        let workflow = try Self.makeWorkflow(initialStepId: "step_1")
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.triggerAction(componentId: "unknown_btn")

        expect(result).to(beNil())
        expect(navigator.currentStepId) == "step_1"
        expect(navigator.canNavigateBack) == false
    }

    func testTriggerActionWithMissingActionIdReturnsNil() throws {
        // Trigger has componentId matching but no actionId
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithNilActionId(id: "step_1", componentId: "btn_abc"),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.triggerAction(componentId: "btn_abc")

        expect(result).to(beNil())
        expect(navigator.currentStepId) == "step_1"
    }

    func testTriggerActionWithWrongTypedActionReturnsNil() throws {
        // trigger action type is "other", which decodes to .unknown — not .step
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(
                    id: "step_1",
                    triggers: [("btn_abc", "btn_abc")],
                    triggerActions: [("btn_abc", "step_2")],
                    actionType: "other"
                ),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.triggerAction(componentId: "btn_abc")

        expect(result).to(beNil())
        expect(navigator.currentStepId) == "step_1"
    }

    func testTriggerActionWithTargetStepNotInWorkflowReturnsNil() throws {
        // triggerAction.stepId points to a step that doesn't exist in workflow.steps
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(
                    id: "step_1",
                    triggers: [("btn_abc", "btn_abc")],
                    triggerActions: [("btn_abc", "step_missing")]
                )
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.triggerAction(componentId: "btn_abc")

        expect(result).to(beNil())
        expect(navigator.currentStepId) == "step_1"
    }

    func testTriggerActionWithMismatchedTriggerTypeReturnsNil() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_abc", "btn_abc")], triggerActions: [("btn_abc", "step_2")]),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.triggerAction(componentId: "btn_abc", triggerType: .unknown)

        expect(result).to(beNil())
        expect(navigator.currentStepId) == "step_1"
        expect(navigator.canNavigateBack) == false
    }

    func testTriggerActionWithConditionsTypeReturnsNil() throws {
        // A "conditions" trigger action has no step_id. The navigator must not crash
        // and must return nil (no navigation), leaving the current step unchanged.
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithConditionsTriggerAction(id: "step_1", componentId: "btn_abc", actionId: "btn_abc"),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.triggerAction(componentId: "btn_abc")

        expect(result).to(beNil())
        expect(navigator.currentStepId) == "step_1"
        expect(navigator.canNavigateBack) == false
    }

    // MARK: - navigateBack

    func testNavigateBackFromInitialStepReturnsNil() throws {
        let workflow = try Self.makeWorkflow(initialStepId: "step_1")
        let navigator = WorkflowNavigator(workflow: workflow)

        let result = navigator.navigateBack()

        expect(result).to(beNil())
        expect(navigator.currentStepId) == "step_1"
    }

    func testNavigateBackAfterForwardNavigationRestoresPreviousStep() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_abc", "btn_abc")], triggerActions: [("btn_abc", "step_2")]),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)
        navigator.triggerAction(componentId: "btn_abc")

        let result = navigator.navigateBack()

        expect(result?.id) == "step_1"
        expect(navigator.currentStepId) == "step_1"
        expect(navigator.canNavigateBack) == false
    }

    func testBackNavigationDestinationIsNilFromInitialStep() throws {
        let workflow = try Self.makeWorkflow(initialStepId: "step_1")
        let navigator = WorkflowNavigator(workflow: workflow)

        expect(navigator.backNavigationDestination).to(beNil())
    }

    func testBackNavigationDestinationDoesNotMutateNavigator() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_abc", "btn_abc")], triggerActions: [("btn_abc", "step_2")]),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)
        navigator.triggerAction(componentId: "btn_abc")

        let destination = navigator.backNavigationDestination

        expect(destination?.step.id) == "step_1"
        expect(destination?.canNavigateBackAfterNavigation) == false
        expect(navigator.currentStepId) == "step_2"
        expect(navigator.canNavigateBack) == true
    }

    func testBackNavigationDestinationReportsCanNavigateBackAfterNavigation() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_1", "btn_1")], triggerActions: [("btn_1", "step_2")]),
                makeStep(id: "step_2", triggers: [("btn_2", "btn_2")], triggerActions: [("btn_2", "step_3")]),
                makeStep(id: "step_3")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)
        navigator.triggerAction(componentId: "btn_1")
        navigator.triggerAction(componentId: "btn_2")

        let destination = navigator.backNavigationDestination

        expect(destination?.step.id) == "step_2"
        expect(destination?.canNavigateBackAfterNavigation) == true
    }

    // MARK: - Experiment step resolution
    // Variant selection is handled by WorkflowDetailProcessor (pruning non-enrolled steps).
    // Navigator tests cover structural behaviour: auto-advance, back-stack exclusion, chaining.

    func testExperimentStepIsSkippedAndLandsOnContentStep() throws {
        // After pruning, experiment step has exactly one action — the enrolled variant's.
        let workflow = try Self.makeWorkflow(
            steps: [
                makeExperimentStep(id: "exp_1", experimentId: "exp_abc", variantActions: [
                    ("control", "step_control")
                ]),
                makeStep(id: "step_control")
            ],
            initialStepId: "exp_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        expect(navigator.currentStepId) == "step_control"
    }

    func testExperimentStepNotInBackStackAfterResolution() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeExperimentStep(id: "exp_1", experimentId: "exp_abc", variantActions: [
                    ("control", "step_control")
                ]),
                makeStep(id: "step_control")
            ],
            initialStepId: "exp_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        expect(navigator.currentStepId) == "step_control"
        expect(navigator.canNavigateBack) == false
    }

    func testExperimentStepAfterForwardNavigationIsResolvedSilently() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn", "btn")], triggerActions: [("btn", "exp_1")]),
                makeExperimentStep(id: "exp_1", experimentId: "exp_abc", variantActions: [
                    ("variant_b", "step_variant_b")
                ]),
                makeStep(id: "step_variant_b")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)
        navigator.triggerAction(componentId: "btn")

        expect(navigator.currentStepId) == "step_variant_b"
        expect(navigator.canNavigateBack) == true
        navigator.navigateBack()
        expect(navigator.currentStepId) == "step_1"
    }

    func testChainedExperimentStepsAreResolvedToFirstContentStep() throws {
        // Chained experiment nodes are not a valid workflow configuration in practice,
        // but the navigator should handle them gracefully rather than getting stuck.
        let workflow = try Self.makeWorkflow(
            steps: [
                makeExperimentStep(id: "exp_1", experimentId: "exp_a", variantActions: [
                    ("v1", "exp_2")
                ]),
                makeExperimentStep(id: "exp_2", experimentId: "exp_b", variantActions: [
                    ("v2", "step_content")
                ]),
                makeStep(id: "step_content")
            ],
            initialStepId: "exp_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        expect(navigator.currentStepId) == "step_content"
        expect(navigator.canNavigateBack) == false
    }

    // MARK: - Multiple navigations

    func testMultipleForwardAndBackNavigationsWorkCorrectly() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_1", "btn_1")], triggerActions: [("btn_1", "step_2")]),
                makeStep(id: "step_2", triggers: [("btn_2", "btn_2")], triggerActions: [("btn_2", "step_3")]),
                makeStep(id: "step_3")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        navigator.triggerAction(componentId: "btn_1")
        expect(navigator.currentStepId) == "step_2"
        expect(navigator.canNavigateBack) == true

        navigator.triggerAction(componentId: "btn_2")
        expect(navigator.currentStepId) == "step_3"
        expect(navigator.canNavigateBack) == true

        navigator.navigateBack()
        expect(navigator.currentStepId) == "step_2"
        expect(navigator.canNavigateBack) == true

        navigator.navigateBack()
        expect(navigator.currentStepId) == "step_1"
        expect(navigator.canNavigateBack) == false
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowNavigatorTests {

    /// Builds a `PublishedWorkflow` from a list of pre-encoded step descriptors and an initialStepId.
    static func makeWorkflow(
        steps: [StepDescriptor] = [StepDescriptor(id: "step_1", json: #"{"id":"step_1","type":"screen"}"#)],
        initialStepId: String = "step_1"
    ) throws -> PublishedWorkflow {
        let stepsJSON = steps
            .map { "\"\($0.id)\": \($0.json)" }
            .joined(separator: ",\n")

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test Workflow",
          "initial_step_id": "\(initialStepId)",
          "steps": {
            \(stepsJSON)
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

    struct StepDescriptor {
        let id: String
        let json: String
    }

    /// Creates a `StepDescriptor` for a step with triggers and trigger actions (type "step").
    /// - Parameters:
    ///   - id: The step id.
    ///   - triggers: Array of (componentId, actionId) pairs.
    ///   - triggerActions: Array of (actionId, targetStepId) pairs.
    ///   - actionType: The type to use in trigger actions. Defaults to "step".
    func makeStep(
        id: String,
        triggers: [(componentId: String, actionId: String)] = [],
        triggerActions: [(actionId: String, targetStepId: String)] = [],
        actionType: String = "step"
    ) -> StepDescriptor {
        let triggersJSON: String
        if triggers.isEmpty {
            triggersJSON = "[]"
        } else {
            let items = triggers.map { trigger in
                // swiftlint:disable:next line_length
                "{\"name\":\"Button\",\"type\":\"on_press\",\"action_id\":\"\(trigger.actionId)\",\"component_id\":\"\(trigger.componentId)\"}"
            }.joined(separator: ",")
            triggersJSON = "[\(items)]"
        }

        let actionsJSON: String
        if triggerActions.isEmpty {
            actionsJSON = "{}"
        } else {
            let items = triggerActions.map { action in
                """
                "\(action.actionId)":{"type":"\(actionType)","step_id":"\(action.targetStepId)"}
                """
            }.joined(separator: ",")
            actionsJSON = "{\(items)}"
        }

        let json = """
        {
          "id": "\(id)",
          "type": "screen",
          "triggers": \(triggersJSON),
          "trigger_actions": \(actionsJSON)
        }
        """
        return StepDescriptor(id: id, json: json)
    }

    /// Creates a `StepDescriptor` for an experiment step with the given variant → target-step-id actions.
    func makeExperimentStep(
        id: String,
        experimentId: String,
        variantActions: [(variantId: String, targetStepId: String)]
    ) -> StepDescriptor {
        let actionsJSON = variantActions
            .map { #""\#($0.variantId)":{"type":"step","step_id":"\#($0.targetStepId)"}"# }
            .joined(separator: ",")

        let json = """
        {
          "id": "\(id)",
          "type": "experiment",
          "param_values": {"experiment_id": "\(experimentId)"},
          "triggers": [],
          "trigger_actions": {\(actionsJSON)}
        }
        """
        return StepDescriptor(id: id, json: json)
    }

    /// Creates a `StepDescriptor` where the trigger action has type "conditions" (no step_id field).
    func makeStepWithConditionsTriggerAction(
        id: String,
        componentId: String,
        actionId: String
    ) -> StepDescriptor {
        let json = """
        {
          "id": "\(id)",
          "type": "screen",
          "triggers": [
            {"name":"Button","type":"on_press","action_id":"\(actionId)","component_id":"\(componentId)"}
          ],
          "trigger_actions": {
            "\(actionId)": {"type":"conditions","conditions":{"if":[]}}
          }
        }
        """
        return StepDescriptor(id: id, json: json)
    }

    /// Creates a `StepDescriptor` for a step that has a trigger with a matching componentId but **no** actionId.
    func makeStepWithNilActionId(id: String, componentId: String) -> StepDescriptor {
        let json = """
        {
          "id": "\(id)",
          "type": "screen",
          "triggers": [
            {"name":"Button","type":"on_press","component_id":"\(componentId)"}
          ],
          "trigger_actions": {}
        }
        """
        return StepDescriptor(id: id, json: json)
    }

}

#endif
