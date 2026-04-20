//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowResponseTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class WorkflowResponseTests: TestCase {

    func testDecodeWorkflowsListResponse() throws {
        let json = """
        {
          "workflows": [
            { "id": "wf_1", "display_name": "Flow A" }
          ],
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {},
            "variable_config": { "variable_compatibility_map": {}, "function_compatibility_map": {} }
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.default.decode(
            WorkflowsListResponse.self, from: json
        )

        expect(response.workflows).to(haveCount(1))
        expect(response.workflows.first?.id) == "wf_1"
        expect(response.workflows.first?.displayName) == "Flow A"
    }

    func testDecodePublishedWorkflowWithStepsAndTriggerActions() throws {
        let json = """
        {
          "id": "wf_test",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": {
              "id": "step_1",
              "type": "screen",
              "trigger_actions": {
                "btn_1": { "type": "step", "step_id": "step_2" }
              }
            }
          },
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {},
            "variable_config": { "variable_compatibility_map": {}, "function_compatibility_map": {} }
          },
          "content_max_width": 100
        }
        """.data(using: .utf8)!

        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self, from: json
        )

        expect(workflow.id) == "wf_test"
        expect(workflow.initialStepId) == "step_1"
        expect(workflow.steps["step_1"]?.triggerActions["btn_1"]?.stepId) == "step_2"
        expect(workflow.contentMaxWidth) == 100
        expect(workflow.metadata).to(beNil())
    }

    func testDecodePublishedWorkflowWithoutOptionals() throws {
        let json = """
        {
          "id": "wf_min",
          "display_name": "Minimal",
          "initial_step_id": "step_1",
          "steps": {},
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {},
            "variable_config": { "variable_compatibility_map": {}, "function_compatibility_map": {} }
          }
        }
        """.data(using: .utf8)!

        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self, from: json
        )

        expect(workflow.id) == "wf_min"
        expect(workflow.contentMaxWidth).to(beNil())
    }

    func testDecodePublishedWorkflowWithMetadata() throws {
        let json = """
        {
          "id": "wf_meta",
          "display_name": "Meta",
          "initial_step_id": "step_1",
          "steps": {},
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {},
            "variable_config": { "variable_compatibility_map": {}, "function_compatibility_map": {} }
          },
          "metadata": { "some_key": "some_value" }
        }
        """.data(using: .utf8)!

        let workflow = try JSONDecoder.default.decode(PublishedWorkflow.self, from: json)

        expect(workflow.metadata).toNot(beNil())
    }

    func testDecodeWorkflowTriggerAction() throws {
        let json = """
        { "type": "step", "step_id": "step_3" }
        """.data(using: .utf8)!

        let action = try JSONDecoder.default.decode(WorkflowTriggerAction.self, from: json)

        expect(action.type) == "step"
        expect(action.stepId) == "step_3"
        expect(action.value).to(beNil())
    }

    func testDecodeWorkflowTriggerActionWithValue() throws {
        let json = """
        { "type": "step", "value": "step_override" }
        """.data(using: .utf8)!

        let action = try JSONDecoder.default.decode(WorkflowTriggerAction.self, from: json)

        expect(action.type) == "step"
        expect(action.stepId).to(beNil())
        expect(action.value) == "step_override"
    }

    func testDecodeWorkflowTrigger() throws {
        let json = """
        {
          "name": "Button",
          "type": "on_press",
          "action_id": "btn_wagcLsIVjN",
          "component_id": "wagcLsIVjN"
        }
        """.data(using: .utf8)!

        let trigger = try JSONDecoder.default.decode(WorkflowTrigger.self, from: json)

        expect(trigger.name) == "Button"
        expect(trigger.type) == "on_press"
        expect(trigger.actionId) == "btn_wagcLsIVjN"
        expect(trigger.componentId) == "wagcLsIVjN"
    }

    func testDecodeWorkflowStepDefaults() throws {
        let json = """
        { "id": "step_1", "type": "screen" }
        """.data(using: .utf8)!

        let step = try JSONDecoder.default.decode(WorkflowStep.self, from: json)

        expect(step.id) == "step_1"
        expect(step.type) == "screen"
        expect(step.screenId).to(beNil())
        expect(step.paramValues).to(beEmpty())
        expect(step.triggers).to(beEmpty())
        expect(step.outputs).to(beEmpty())
        expect(step.triggerActions).to(beEmpty())
        expect(step.metadata).to(beNil())
    }

    func testDecodeWorkflowStepMatchingActualBackendResponse() throws {
        let json = """
        {
          "id": "bdMPgNB",
          "type": "screen",
          "param_values": {
            "experiment_id": "expeae100d588",
            "experiment_variant": "b",
            "is_last_variant_step": true
          },
          "triggers": [
            {
              "name": "Button",
              "type": "on_press",
              "action_id": "btn_wagcLsIVjN",
              "component_id": "wagcLsIVjN"
            }
          ],
          "outputs": {},
          "trigger_actions": {
            "btn_wagcLsIVjN": {
              "type": "step",
              "step_id": "ztBPCwD"
            }
          },
          "metadata": null,
          "screen_id": "pw458e23295b7841f8"
        }
        """.data(using: .utf8)!

        let step = try JSONDecoder.default.decode(WorkflowStep.self, from: json)

        expect(step.id) == "bdMPgNB"
        expect(step.type) == "screen"
        expect(step.screenId) == "pw458e23295b7841f8"
        expect(step.triggers).to(haveCount(1))
        expect(step.triggers.first?.name) == "Button"
        expect(step.triggers.first?.type) == "on_press"
        expect(step.triggers.first?.actionId) == "btn_wagcLsIVjN"
        expect(step.triggers.first?.componentId) == "wagcLsIVjN"
        expect(step.outputs).to(beEmpty())
        expect(step.triggerActions["btn_wagcLsIVjN"]?.type) == "step"
        expect(step.triggerActions["btn_wagcLsIVjN"]?.stepId) == "ztBPCwD"
        expect(step.metadata).to(beNil())
    }

}
