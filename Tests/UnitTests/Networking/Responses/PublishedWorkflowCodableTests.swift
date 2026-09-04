//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PublishedWorkflowCodableTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

/// `PublishedWorkflow`'s `Codable` conformance is hand-written, not synthesized, so a decode/encode
/// mismatch is no longer ruled out for free — these tests catch that.
class PublishedWorkflowCodableTests: TestCase {

    func testEncodeThenDecodeRoundTripsCodableFields() throws {
        let original = PublishedWorkflow(
            id: "wf-1",
            displayName: "Test workflow",
            initialStepId: "step-1",
            singleStepFallbackId: "step-2",
            steps: [:],
            screens: [:],
            contentMaxWidth: 400
        )

        let data = try JSONEncoder.default.encode(value: original)
        let decoded = try JSONDecoder.default.decode(PublishedWorkflow.self, jsonData: data)

        expect(decoded) == original
    }

    func testBranchTriggerActionSurvivesAnEncodeDecodeRoundTrip() throws {
        // Workflows are cached as encoded models, so a branch has to come back intact.
        let json = """
        {
          "type": "branch",
          "branches": [
            { "audience_id": "aud_a", "step_id": "step_a" },
            { "audience_id": "aud_b", "step_id": "step_b" }
          ],
          "fallback_step_id": "step_default"
        }
        """.data(using: .utf8)!

        let original = try JSONDecoder.default.decode(WorkflowTriggerAction.self, from: json)
        let encoded = try JSONEncoder.default.encode(value: original)
        let decoded = try JSONDecoder.default.decode(WorkflowTriggerAction.self, from: encoded)

        expect(decoded) == original
    }

    func testEncodingOmitsUiConfig() throws {
        let workflow = PublishedWorkflow(
            id: "wf-1",
            displayName: "Test workflow",
            initialStepId: "step-1",
            singleStepFallbackId: nil,
            steps: [:],
            screens: [:]
        )

        let data = try JSONEncoder.default.encode(value: workflow)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        expect(json).toNot(contain("ui_config"))
    }

    func testDecodingWithoutUiConfigSucceeds() throws {
        let json = """
        {
          "id": "wf-1",
          "display_name": "Test",
          "initial_step_id": "step-1",
          "steps": {},
          "screens": {}
        }
        """
        let decoded = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            jsonData: try XCTUnwrap(json.data(using: .utf8))
        )

        expect(decoded.id) == "wf-1"
    }

    func testDecodingIgnoresEmbeddedUiConfig() throws {
        let json = """
        {
          "id": "wf-1",
          "display_name": "Test",
          "initial_step_id": "step-1",
          "steps": {},
          "screens": {},
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": { "en_US": { "day": "Day" } },
            "variable_config": { "variable_compatibility_map": {}, "function_compatibility_map": {} }
          }
        }
        """
        let decoded = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            jsonData: try XCTUnwrap(json.data(using: .utf8))
        )

        expect(decoded.id) == "wf-1"
    }

    func testDecodingWithMetadataPreservesIt() throws {
        let json = """
        {
          "id": "wf-1",
          "display_name": "Test",
          "initial_step_id": "step-1",
          "steps": {},
          "screens": {},
          "metadata": { "source": "cdn" }
        }
        """
        let decoded = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            jsonData: try XCTUnwrap(json.data(using: .utf8))
        )

        expect(decoded.metadata?["source"]) == .string("cdn")
    }

    func testDecodingScreenWithNullDefaultLocaleDoesNotFailWholeWorkflow() throws {
        let json = """
        {
          "id": "wf-1",
          "display_name": "Test",
          "initial_step_id": "step-1",
          "steps": {},
          "screens": {
            "pwa-1": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": null,
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": {
                    "type": "stack", "components": [],
                    "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                    "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                    "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
                  },
                  "background": {
                    "type": "color", "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
                  }
                }
              }
            }
          }
        }
        """
        let decoded = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            jsonData: try XCTUnwrap(json.data(using: .utf8))
        )

        expect(decoded.screens["pwa-1"]?.defaultLocale) == "en"
    }

}
