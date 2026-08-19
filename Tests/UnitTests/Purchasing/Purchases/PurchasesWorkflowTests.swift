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

    func testRemoteConfigEnabledReturnsFalseWhenDisabledByKillSwitch() {
        self.systemInfo.stubbedRemoteConfigEnabled = true
        self.setupPurchases()

        expect(self.purchases.remoteConfigEnabled) == true

        self.mockRemoteConfigManager.isDisabled = true

        expect(self.purchases.remoteConfigEnabled) == false
    }

    func testWorkflowForOfferingIdentifierThrowsWhenOfferingHasNoWorkflow() async throws {
        self.setupPurchases()

        // The `workflows` topic has synced, but no item maps to the "default" offering (its item carries
        // no matching `offeringIdentifier`). With no mapping, resolution fails fast with a distinct
        // `offeringHasNoWorkflow` and does NOT attempt a fetch by offering id — the prior lazy
        // offering-id-as-workflow-key behavior was dropped to match purchases-android #3760.
        self.mockRemoteConfigManager.stubbedTopics[.workflows] = ["default": .init(blobRef: "default", content: [:])]
        self.mockRemoteConfigManager.stubbedBlobData[.workflows] = ["default": try Self.workflowJSON(id: "default")]

        do {
            _ = try await self.purchases.workflow(forOfferingIdentifier: "default")
            fail("Expected workflow(forOfferingIdentifier:) to throw")
        } catch {
            expect(error as? BackendError) == .unexpectedBackendResponse(
                .offeringHasNoWorkflow(offeringId: "default"),
                extraContext: nil,
                .init(file: "", function: "", line: 0)
            )
        }

        // Failed fast on the missing mapping: no workflow blob was fetched.
        let requestedWorkflowKeys = self.mockRemoteConfigManager.invokedBlobDataParameters
            .filter { $0.topic == .workflows }
            .map(\.itemKey)
        expect(requestedWorkflowKeys).to(beEmpty())
    }

    // MARK: - Helpers

    private static let uiConfigTopic: [String: RemoteConfiguration.ConfigItem] = [
        "app": .init(blobRef: "app-ref", content: [:]),
        "localizations": .init(blobRef: "localizations-ref", content: [:]),
        "variable_config": .init(blobRef: "variable-config-ref", content: [:]),
        "custom_variables": .init(blobRef: "custom-variables-ref", content: [:])
    ]

    private static let uiConfigBlobs: [String: Data] = [
        "app": Data(#"{"colors": {}, "fonts": {}}"#.utf8),
        "localizations": Data(#"{}"#.utf8),
        "variable_config": Data(
            #"{"variable_compatibility_map": {}, "function_compatibility_map": {}}"#.utf8
        ),
        "custom_variables": Data(#"{}"#.utf8)
    ]

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
