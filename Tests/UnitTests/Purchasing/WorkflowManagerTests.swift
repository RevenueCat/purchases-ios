//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowManagerTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class WorkflowManagerTests: TestCase {

    private var mockProvider: MockWorkflowsConfigProvider!
    private var mockPaywallCache: MockPaywallCacheWarming!
    private var mockOperationDispatcher: MockOperationDispatcher!
    private var manager: WorkflowManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockProvider = MockWorkflowsConfigProvider()
        self.mockPaywallCache = MockPaywallCacheWarming()
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.manager = WorkflowManager(
            workflowsConfigProvider: self.mockProvider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher
        )
    }

    // MARK: - getWorkflow

    func testGetWorkflowDelegatesToProviderAndSucceeds() async throws {
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]

        let result = try await self.manager.getWorkflow(workflowId: "wf_1")

        expect(result) == expected
        expect(self.mockProvider.invokedGetWorkflowParameters) == ["wf_1"]
    }

    func testGetWorkflowWarmsUpAssetsOnSuccess() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("warmUpWorkflowCaches requires iOS 15+")
        }
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]

        // MockOperationDispatcher's async dispatchOnWorkerThread blocks until the block finishes, so
        // warm-up has already run by the time this returns.
        _ = try await self.manager.getWorkflow(workflowId: "wf_1")

        expect(self.mockPaywallCache.invokedWarmUpWorkflowCaches) == true
        expect(self.mockPaywallCache.invokedWarmUpWorkflowCachesWorkflow?.id) == "wf_1"
        expect(self.mockPaywallCache.invokedWarmUpWorkflowCachesUiConfig) == expected.uiConfig
    }

    func testGetWorkflowFailsWithWorkflowNotFoundWhenProviderReportsNotFound() async {
        do {
            _ = try await self.manager.getWorkflow(workflowId: "missing")
            fail("Expected getWorkflow to throw")
        } catch {
            expect(error as? BackendError) == .unexpectedBackendResponse(
                .workflowNotFound(workflowId: "missing"),
                extraContext: nil,
                .init(file: "", function: "", line: 0)
            )
        }
    }

    func testGetWorkflowFailsWithDecodingFailedWhenProviderReportsADecodingFailure() async {
        let underlyingError = NSError(domain: "test", code: 1)
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .decodingFailed(underlyingError)]

        do {
            _ = try await self.manager.getWorkflow(workflowId: "wf_1")
            fail("Expected getWorkflow to throw")
        } catch {
            expect(error as? BackendError) == .unexpectedBackendResponse(
                .workflowDecodingFailed(workflowId: "wf_1", error: underlyingError),
                extraContext: nil,
                .init(file: "", function: "", line: 0)
            )
        }
    }

    func testGetWorkflowFailsWithUiConfigUnavailableWhenProviderReportsItsMissing() async {
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .uiConfigUnavailable]

        do {
            _ = try await self.manager.getWorkflow(workflowId: "wf_1")
            fail("Expected getWorkflow to throw")
        } catch WorkflowError.uiConfigUnavailable(let workflowId) {
            expect(workflowId) == "wf_1"
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    // MARK: - workflowId(forOfferingId:)

    func testWorkflowIdForOfferingIdDelegatesToProvider() async {
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]

        let workflowId = await self.manager.workflowId(forOfferingId: "default")

        expect(workflowId) == "wf_1"
        expect(self.mockProvider.invokedWorkflowIdForOfferingIdParameters) == ["default"]
    }

    func testWorkflowIdForOfferingIdReturnsNilWhenUnresolved() async {
        let workflowId = await self.manager.workflowId(forOfferingId: "unknown")

        expect(workflowId).to(beNil())
    }

    // MARK: - getWorkflow(forOfferingId:)

    func testGetWorkflowForOfferingIdResolvesWorkflowIdThenFetchesTheWorkflow() async throws {
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]

        let result = try await self.manager.getWorkflow(forOfferingId: "default")

        expect(result) == expected
        expect(self.mockProvider.invokedWorkflowIdForOfferingIdParameters) == ["default"]
        expect(self.mockProvider.invokedGetWorkflowParameters) == ["wf_1"]
    }

    func testGetWorkflowForOfferingIdFallsBackToOfferingIdAsWorkflowId() async throws {
        // No entry in stubbedWorkflowIdForOfferingId, so the mapping is unresolved.
        let expected = try Self.workflowDataResult(id: "default")
        self.mockProvider.stubbedGetWorkflowResult = ["default": expected]

        let result = try await self.manager.getWorkflow(forOfferingId: "default")

        expect(result) == expected
        expect(self.mockProvider.invokedGetWorkflowParameters) == ["default"]
    }

    // MARK: - Helpers

    private static func workflowDataResult(id: String) throws -> WorkflowDataResult {
        return .init(workflow: try self.publishedWorkflow(id: id), uiConfig: .empty, enrolledVariants: nil)
    }

    private static func publishedWorkflow(id: String) throws -> PublishedWorkflow {
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
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

}
