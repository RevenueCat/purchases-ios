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

/// `PublishedWorkflow` decodes through hand-written keys, so these pin the shapes the backend sends.
class PublishedWorkflowCodableTests: TestCase {

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
