//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesWorkflowTests.swift
//
//  Created by RevenueCat.

import Nimble
import XCTest

@testable @_spi(Internal) import RevenueCat

class PurchasesWorkflowTests: BasePurchasesTests {

    private var mockWorkflowsAPI: MockWorkflowsAPI!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
        self.mockWorkflowsAPI = try XCTUnwrap(self.backend.workflowsAPI as? MockWorkflowsAPI)
    }

    func testWorkflowForOfferingIdentifierFallsBackToOfferingIdAsWorkflowId() async throws {
        let expected = try Self.workflowDataResult(id: "default")
        self.mockWorkflowsAPI.stubbedGetWorkflowResult = .success(expected)

        // No workflows list has been fetched yet, so the offeringId → workflowId map is empty and the
        // offering identifier itself is used as the workflow lookup key, preserving the prior behavior.
        let result = try await self.purchases.workflow(forOfferingIdentifier: "default")

        expect(self.mockWorkflowsAPI.invokedGetWorkflowParameters?.workflowId) == "default"
        expect(result) == expected
    }

    // MARK: - Helpers

    private static func workflowDataResult(id: String) throws -> WorkflowDataResult {
        let json = """
        {
          "id": "\(id)",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" }
          },
          "screens": {
            "screen_1": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": {
                    "type": "stack",
                    "components": [],
                    "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                    "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                    "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
                  },
                  "background": {
                    "type": "color",
                    "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
                  }
                }
              },
              "offering_identifier": "default"
            }
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let workflow = try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
        return .init(workflow: workflow, enrolledVariants: nil)
    }

}
