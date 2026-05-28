//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowRuleEvaluatorTests.swift
//
//  Created by Codex on 3/31/26.

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class WorkflowRuleEvaluatorTests: TestCase {

    func testDecodesWeatherCatDemoBundle() throws {
        let bundle = try JSONDecoder.default.decode(
            WorkflowRuleBundle.self,
            from: Self.weatherCatDemoBundle.asData
        )

        expect(bundle.bundleKey) == "weathercat-demo"
        expect(bundle.rules).to(haveCount(1))
        expect(bundle.rules[0].trigger.type) == "attempt_change_environment"
        expect(bundle.rules[0].action.workflowID) == "wf_weathercat_demo"
    }

    func testMatchesFirstPremiumThemeAttempt() throws {
        let bundle = try self.decodeBundle()

        let action = WorkflowRuleEvaluator.firstMatchingAction(
            in: bundle,
            triggerType: "attempt_change_environment",
            evaluationContext: Self.context(
                premiumEntitlementIsActive: false,
                premiumThemeAttemptCount: 1,
                environmentName: "Electric Storm",
                environmentRequiresEntitlement: true
            )
        )

        expect(action?.workflowID) == "wf_weathercat_demo"
        expect(action?.workflowName) == "WeatherCat Premium Theme Interstitial"
    }

    func testDoesNotMatchForPremiumUser() throws {
        let bundle = try self.decodeBundle()

        let action = WorkflowRuleEvaluator.firstMatchingAction(
            in: bundle,
            triggerType: "attempt_change_environment",
            evaluationContext: Self.context(
                premiumEntitlementIsActive: true,
                premiumThemeAttemptCount: 1,
                environmentName: "Electric Storm",
                environmentRequiresEntitlement: true
            )
        )

        expect(action).to(beNil())
    }

    func testDoesNotMatchAfterFirstAttempt() throws {
        let bundle = try self.decodeBundle()

        let action = WorkflowRuleEvaluator.firstMatchingAction(
            in: bundle,
            triggerType: "attempt_change_environment",
            evaluationContext: Self.context(
                premiumEntitlementIsActive: false,
                premiumThemeAttemptCount: 2,
                environmentName: "Polar Aurora",
                environmentRequiresEntitlement: true
            )
        )

        expect(action).to(beNil())
    }

    func testDoesNotMatchDifferentTriggerType() throws {
        let bundle = try self.decodeBundle()

        let action = WorkflowRuleEvaluator.firstMatchingAction(
            in: bundle,
            triggerType: "app_launch",
            evaluationContext: Self.context(
                premiumEntitlementIsActive: false,
                premiumThemeAttemptCount: 1,
                environmentName: "Electric Storm",
                environmentRequiresEntitlement: true
            )
        )

        expect(action).to(beNil())
    }

}

private extension WorkflowRuleEvaluatorTests {

    func decodeBundle() throws -> WorkflowRuleBundle {
        return try JSONDecoder.default.decode(
            WorkflowRuleBundle.self,
            from: Self.weatherCatDemoBundle.asData
        )
    }

    static func context(
        premiumEntitlementIsActive: Bool,
        premiumThemeAttemptCount: Int,
        environmentName: String,
        environmentRequiresEntitlement: Bool
    ) -> WorkflowRuleValue {
        return .object([
            "subscriber": .object([
                "entitlements": .object([
                    "premium": .object([
                        "is_active": .bool(premiumEntitlementIsActive)
                    ])
                ])
            ]),
            "session": .object([
                "premium_theme_attempt_count": .int(premiumThemeAttemptCount)
            ]),
            "trigger": .object([
                "environment_name": .string(environmentName),
                "environment_requires_entitlement": .bool(environmentRequiresEntitlement)
            ])
        ])
    }

    static let weatherCatDemoBundle = #"""
    {
      "artifact_version": 1,
      "bundle_key": "weathercat-demo",
      "generated_at": "2026-03-30T23:26:01.212282+00:00",
      "rules": [
        {
          "action": {
            "type": "launch_workflow",
            "workflow_id": "wf_weathercat_demo",
            "workflow_name": "WeatherCat Premium Theme Interstitial"
          },
          "artifact_version": 1,
          "kind": "targeting",
          "predicate": {
            "and": [
              {
                "==": [
                  {
                    "var": "trigger.environment_requires_entitlement"
                  },
                  true
                ]
              },
              {
                "==": [
                  {
                    "var": "subscriber.entitlements.premium.is_active"
                  },
                  false
                ]
              },
              {
                "==": [
                  {
                    "var": "session.premium_theme_attempt_count"
                  },
                  1
                ]
              }
            ]
          },
          "required_fields": [
            "trigger.environment_name",
            "trigger.environment_requires_entitlement",
            "subscriber.entitlements.premium.is_active",
            "session.premium_theme_attempt_count"
          ],
          "rule_id": "weathercat_premium_environment_first_attempt",
          "rule_version": 1,
          "supported_runtimes": {
            "clickhouse": false,
            "sdk": true,
            "server": false
          },
          "trigger": {
            "fields": [
              "trigger.environment_name",
              "trigger.environment_requires_entitlement"
            ],
            "type": "attempt_change_environment"
          }
        }
      ]
    }
    """#

}
