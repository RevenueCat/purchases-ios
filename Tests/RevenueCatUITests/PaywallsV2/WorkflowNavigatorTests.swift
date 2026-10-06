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
@MainActor
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

    func testTriggerActionDestinationDoesNotMutateNavigator() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_abc", "btn_abc")], triggerActions: [("btn_abc", "step_2")]),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let destination = navigator.triggerActionDestination(componentId: "btn_abc")

        expect(destination?.step.id) == "step_2"
        expect(navigator.currentStepId) == "step_1"
        expect(navigator.canNavigateBack) == false
    }

    func testFirstForwardDestinationHasBackNavigationAfterNavigation() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1", triggers: [("btn_abc", "btn_abc")], triggerActions: [("btn_abc", "step_2")]),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)

        let destination = navigator.triggerActionDestination(componentId: "btn_abc")

        // The destination is resolved without mutation, but committing it pushes the current step.
        expect(destination?.canNavigateBackAfterNavigation) == true
        expect(navigator.canNavigateBack) == false
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

    // MARK: - Branch exits

    func testAResolvedBranchNavigatesToItsRouteInsteadOfTheFallback() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithBranchExit(id: "step_1", componentId: "btn_abc", actionId: "btn_abc"),
                makeStep(id: "step_2"),
                makeStep(id: "step_3")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(
            workflow: workflow,
            resolveBranch: { _ in "step_3" }
        )
        await navigator.waitForBranchResolution()

        let result = navigator.triggerAction(componentId: "btn_abc")

        expect(result?.id) == "step_3"
        expect(navigator.currentStepId) == "step_3"
    }

    func testReturningToAStepDropsItsPreviousBranchResolution() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithBranchExit(id: "step_1", componentId: "btn_abc", actionId: "btn_abc"),
                makeStep(id: "step_2"),
                makeStep(id: "step_3")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(
            workflow: workflow,
            resolveBranch: { _ in "step_3" }
        )
        await navigator.waitForBranchResolution()

        _ = navigator.triggerAction(componentId: "btn_abc")
        _ = navigator.navigateBack()

        // Back on step_1 with nothing resolved yet, so the fallback stands until the new pass lands.
        expect(navigator.triggerAction(componentId: "btn_abc")?.id) == "step_2"
    }

    func testWithNoResolverEveryBranchTakesItsFallback() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithBranchExit(id: "step_1", componentId: "btn_abc", actionId: "btn_abc"),
                makeStep(id: "step_2"),
                makeStep(id: "step_3")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow)
        await navigator.waitForBranchResolution()

        expect(navigator.triggerAction(componentId: "btn_abc")?.id) == "step_2"
    }

    /// Config drift: the audiences pick a step the workflow no longer contains. The button must still
    /// navigate, using the configured fallback, rather than doing nothing.
    func testARouteNamingAMissingStepFallsBack() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithBranchExit(id: "step_1", componentId: "btn_abc", actionId: "btn_abc"),
                makeStep(id: "step_2")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(
            workflow: workflow,
            resolveBranch: { _ in "step_gone" }
        )
        await navigator.waitForBranchResolution()

        expect(navigator.triggerAction(componentId: "btn_abc")?.id) == "step_2"
    }

    /// A step that targets itself is still a new visit, so its branches resolve again.
    func testAStepTargetingItselfResolvesAgain() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithBranchExit(
                    id: "step_1",
                    componentId: "btn_abc",
                    actionId: "btn_abc",
                    fallbackStepId: "step_1"
                ),
                makeStep(id: "step_2"),
                makeStep(id: "step_3")
            ],
            initialStepId: "step_1"
        )
        let calls = Atomic<Int>(0)
        let navigator = WorkflowNavigator(workflow: workflow) { _ in
            calls.modify { $0 += 1 }
            return "step_1"
        }
        await navigator.waitForBranchResolution()

        _ = navigator.triggerAction(componentId: "btn_abc")
        await navigator.waitForBranchResolution()

        expect(navigator.currentStepId) == "step_1"
        expect(calls.value) == 2
    }

    /// Resolution must run against the step just entered, not the one being left.
    func testNavigatingResolvesTheStepBeingEntered() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(
                    id: "step_1",
                    triggers: [(componentId: "btn_go", actionId: "btn_go")],
                    triggerActions: [(actionId: "btn_go", targetStepId: "step_2")]
                ),
                makeStepWithBranchExit(
                    id: "step_2",
                    componentId: "btn_abc",
                    actionId: "btn_abc",
                    fallbackStepId: "step_3",
                    routeStepId: "step_4"
                ),
                makeStep(id: "step_3"),
                makeStep(id: "step_4")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(
            workflow: workflow,
            resolveBranch: { $0.routes.first?.stepId ?? $0.fallbackStepId }
        )

        _ = navigator.triggerAction(componentId: "btn_go")
        await navigator.waitForBranchResolution()

        expect(navigator.triggerAction(componentId: "btn_abc")?.id) == "step_4"
    }

    /// Nothing waits on resolution. The body is synchronous from init to the tap, so the resolve task
    /// provably has not run, and the branch must still navigate.
    func testATapBeforeResolutionTakesTheFallback() throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithBranchExit(id: "step_1", componentId: "btn_abc", actionId: "btn_abc"),
                makeStep(id: "step_2"),
                makeStep(id: "step_3")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(
            workflow: workflow,
            resolveBranch: { _ in "step_3" }
        )

        expect(navigator.triggerAction(componentId: "btn_abc")?.id) == "step_2"
    }

    /// A screen can have more than one audience-routed button, and entering it resolves all of them.
    func testEveryBranchOnTheStepResolves() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStepWithTwoBranchExits(id: "step_1"),
                makeStep(id: "step_a"),
                makeStep(id: "step_b")
            ],
            initialStepId: "step_1"
        )
        let navigator = WorkflowNavigator(workflow: workflow) { $0.routes.first?.stepId ?? $0.fallbackStepId }
        await navigator.waitForBranchResolution()

        expect(navigator.triggerActionDestination(componentId: "btn_one")?.step.id) == "step_a"
        expect(navigator.triggerActionDestination(componentId: "btn_two")?.step.id) == "step_b"
    }

    // MARK: - initial trigger

    func testAnInitialTriggerPicksTheFirstStep() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [makeStep(id: "step_1"), makeStep(id: "step_3")],
            initialRouteStepId: "step_3"
        )
        let navigator = WorkflowNavigator(workflow: workflow) { _ in "step_3" }

        expect(navigator.currentStepId) == "step_1"

        await navigator.waitForInitialStep()

        expect(navigator.currentStepId) == "step_3"
    }

    /// Config drift: the audiences pick a step the workflow does not have.
    func testAnInitialRouteNamingAMissingStepStaysOnTheFallback() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [makeStep(id: "step_1")],
            initialRouteStepId: "step_gone"
        )
        let navigator = WorkflowNavigator(workflow: workflow) { _ in "step_gone" }
        await navigator.waitForInitialStep()

        expect(navigator.currentStepId) == "step_1"
    }

    /// The routed step's own branches have to resolve too, otherwise entering through the initial
    /// trigger leaves every exit on its fallback.
    func testTheStepTheInitialTriggerPicksResolvesItsOwnBranches() async throws {
        let workflow = try Self.makeWorkflow(
            steps: [
                makeStep(id: "step_1"),
                makeStepWithBranchExit(id: "step_4", componentId: "btn_abc", actionId: "btn_abc"),
                makeStep(id: "step_2"),
                makeStep(id: "step_3")
            ],
            initialRouteStepId: "step_4"
        )
        let navigator = WorkflowNavigator(workflow: workflow) { branch in
            branch.routes.first?.stepId ?? branch.fallbackStepId
        }
        await navigator.waitForInitialStep()
        await navigator.waitForBranchResolution()

        expect(navigator.currentStepId) == "step_4"
        expect(navigator.triggerAction(componentId: "btn_abc")?.id) == "step_3"
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
        initialStepId: String = "step_1",
        initialRouteStepId: String? = nil
    ) throws -> PublishedWorkflow {
        let stepsJSON = steps
            .map { "\"\($0.id)\": \($0.json)" }
            .joined(separator: ",\n")

        let initialTriggerJSON = initialRouteStepId.map {
            """
            "initial_trigger": {
              "type": "branch",
              "routes": [{"audience_id": "aud_a", "step_id": "\($0)"}],
              "fallback_step_id": "\(initialStepId)"
            },
            """
        } ?? ""

        let json = """
        {
          "id": "wf_test",
          "display_name": "Test Workflow",
          "initial_step_id": "\(initialStepId)",
          \(initialTriggerJSON)
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

    /// Creates a `StepDescriptor` for a screen whose exit is a branch, rather than a routing step.
    ///
    /// The route names a different step than the fallback, so a test can tell the two apart.
    func makeStepWithBranchExit(
        id: String,
        componentId: String,
        actionId: String,
        fallbackStepId: String = "step_2",
        routeStepId: String = "step_3"
    ) -> StepDescriptor {
        let json = """
        {
          "id": "\(id)",
          "type": "screen",
          "screen_id": "screen_\(id)",
          "triggers": [
            {"name":"Button","type":"on_press","action_id":"\(actionId)","component_id":"\(componentId)"}
          ],
          "trigger_actions": {
            "\(actionId)": {
              "type": "branch",
              "routes": [{"audience_id": "aud_a", "step_id": "\(routeStepId)"}],
              "fallback_step_id": "\(fallbackStepId)"
            }
          }
        }
        """
        return StepDescriptor(id: id, json: json)
    }

    /// Creates a `StepDescriptor` for a screen with two buttons, each carrying its own branch.
    func makeStepWithTwoBranchExits(id: String) -> StepDescriptor {
        let json = """
        {
          "id": "\(id)",
          "type": "screen",
          "screen_id": "screen_\(id)",
          "triggers": [
            {"name":"One","type":"on_press","action_id":"btn_one","component_id":"btn_one"},
            {"name":"Two","type":"on_press","action_id":"btn_two","component_id":"btn_two"}
          ],
          "trigger_actions": {
            "btn_one": {
              "type": "branch",
              "routes": [{"audience_id": "aud_a", "step_id": "step_a"}],
              "fallback_step_id": "step_1"
            },
            "btn_two": {
              "type": "branch",
              "routes": [{"audience_id": "aud_b", "step_id": "step_b"}],
              "fallback_step_id": "step_1"
            }
          }
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
