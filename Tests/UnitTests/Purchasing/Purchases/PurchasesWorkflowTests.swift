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

/// `Purchases.workflow(forOfferingIdentifier:)` reads through `WorkflowManager`/`WorkflowsConfigProvider`
/// off `RemoteConfigManager` now, not a dedicated `WorkflowsAPI` backend call.
class PurchasesWorkflowTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    func testWorkflowForOfferingIdentifierFallsBackToOfferingIdAsWorkflowId() async throws {
        // The `workflows` topic has synced, but its "default" item has no `offeringIdentifier` match,
        // so the offeringId → workflowId scan misses and the offering identifier itself is used as the
        // workflow lookup key, preserving the prior behavior. (A real `RemoteConfigManager` can't return
        // blob data for an item absent from the topic or without a `blobRef`, so the topic item must be
        // stubbed with one too, not just the blob bytes.)
        self.mockRemoteConfigManager.stubbedTopics[.workflows] = ["default": .init(blobRef: "default", content: [:])]
        self.mockRemoteConfigManager.stubbedBlobData[.workflows] = ["default": try Self.workflowJSON(id: "default")]
        self.mockRemoteConfigManager.stubbedBlobData[.uiConfig] = [
            "app": Data(#"{"colors": {}, "fonts": {}}"#.utf8),
            "localizations": Data(#"{}"#.utf8)
        ]

        let result = try await self.purchases.workflow(forOfferingIdentifier: "default")

        expect(result.workflow.id) == "default"
        let requestedWorkflowKeys = self.mockRemoteConfigManager.invokedBlobDataParameters
            .filter { $0.topic == .workflows }
            .map(\.itemKey)
        expect(requestedWorkflowKeys) == ["default"]
    }

    // MARK: - Helpers

    private static func workflowJSON(id: String) throws -> Data {
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
          }
        }
        """
        return try XCTUnwrap(json.data(using: .utf8))
    }

}
