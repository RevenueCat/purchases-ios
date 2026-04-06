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
            "variable_config": {}
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
                "btn_1": { "type": "step", "value": "step_2" }
              }
            }
          },
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {},
            "variable_config": {}
          },
          "content_max_width": 100
        }
        """.data(using: .utf8)!

        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self, from: json
        )

        expect(workflow.id) == "wf_test"
        expect(workflow.initialStepId) == "step_1"
        expect(workflow.steps["step_1"]?.triggerActions["btn_1"]?.resolvedTargetStepId) == "step_2"
        expect(workflow.contentMaxWidth) == 100
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
            "variable_config": {}
          }
        }
        """.data(using: .utf8)!

        let workflow = try JSONDecoder.default.decode(
            PublishedWorkflow.self, from: json
        )

        expect(workflow.id) == "wf_min"
        expect(workflow.contentMaxWidth).to(beNil())
    }

    func testDecodeWorkflowTriggerActionWithStepId() throws {
        let json = """
        { "type": "step", "step_id": "step_3" }
        """.data(using: .utf8)!

        let action = try JSONDecoder.default.decode(WorkflowTriggerAction.self, from: json)

        expect(action.type) == "step"
        expect(action.resolvedTargetStepId) == "step_3"
    }

    func testDecodeWorkflowTriggerActionValueTakesPrecedence() throws {
        let json = """
        { "type": "step", "value": "step_2", "step_id": "step_3" }
        """.data(using: .utf8)!

        let action = try JSONDecoder.default.decode(WorkflowTriggerAction.self, from: json)

        expect(action.resolvedTargetStepId) == "step_2"
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
        expect(step.triggerActions).to(beEmpty())
    }

}
