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
    private var mockWebBundleURLBatcher: MockWebBundleURLBatcher!
    private var manager: WorkflowManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockProvider = MockWorkflowsConfigProvider()
        self.mockPaywallCache = MockPaywallCacheWarming()
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = false
        self.mockWebBundleURLBatcher = MockWebBundleURLBatcher()
        self.manager = WorkflowManager(
            workflowsConfigProvider: self.mockProvider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher
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

    func testGetWorkflowSchedulesAssetPrewarmingOnSuccess() async throws {
        try requireWorkflowPrewarmingAvailability()
        let expected = try Self.workflowDataResult(
            id: "wf_1",
            webViewURLs: ["https://example.com/presented"]
        )
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]

        _ = try await self.manager.getWorkflow(workflowId: "wf_1")
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssets) == true
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsWorkflow?.id) == "wf_1"
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsUiConfig) == expected.uiConfig
        expect(Self.webBundleURLStrings(in: self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/presented"]]
        ]
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

    func testGetWorkflowFailsWithConfigurationUnavailableWhenProviderReportsAStaleRead() async {
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .configurationUnavailable]

        do {
            _ = try await self.manager.getWorkflow(workflowId: "wf_1")
            fail("Expected getWorkflow to throw")
        } catch WorkflowError.configurationUnavailable(let workflowId) {
            expect(workflowId) == "wf_1"
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testGetWorkflowPropagatesCancellationWhenProviderReportsCancellation() async {
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .cancelled]

        do {
            _ = try await self.manager.getWorkflow(workflowId: "wf_1")
            fail("Expected getWorkflow to throw")
        } catch is CancellationError {
            // Expected.
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    // MARK: - cachedWorkflow

    func testCachedWorkflowSchedulesAssetPrewarmingOnSuccess() async throws {
        try requireWorkflowPrewarmingAvailability()
        let expected = try Self.workflowDataResult(
            id: "wf_1",
            webViewURLs: ["https://example.com/cached"]
        )
        self.mockProvider.stubbedCachedWorkflowResult = ["default": expected]

        let result = self.manager.cachedWorkflow(forOfferingId: "default")
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(result) == expected
        expect(self.mockProvider.invokedCachedWorkflowParameters) == ["default"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssets) == true
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsWorkflow?.id) == "wf_1"
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsUiConfig) == expected.uiConfig
        expect(Self.webBundleURLStrings(in: self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/cached"]]
        ]
    }

    // MARK: - schedulePrewarming

    func testSchedulePrewarmingForwardsOfferingsToCoordinator() async {
        let offerings = Self.offerings()

        await self.manager.schedulePrewarming(offerings: offerings)

        expect(self.mockProvider.invokedCachePrefetchedWorkflowBodyDataParameters) == ["default"]
        expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread) == true
    }

    // MARK: - workflowId

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

    func testGetWorkflowForOfferingIdThrowsOfferingHasNoWorkflowWithoutFetchingWhenUnmapped() async {
        do {
            _ = try await self.manager.getWorkflow(forOfferingId: "default")
            fail("Expected getWorkflow(forOfferingId:) to throw")
        } catch {
            expect(error as? BackendError) == .unexpectedBackendResponse(
                .offeringHasNoWorkflow(offeringId: "default"),
                extraContext: nil,
                .init(file: "", function: "", line: 0)
            )
        }
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
    }

    func testGetWorkflowForOfferingIdSurfacesWorkflowNotFoundWhenMappedWorkflowUnresolvable() async {
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .notFound]

        do {
            _ = try await self.manager.getWorkflow(forOfferingId: "default")
            fail("Expected getWorkflow(forOfferingId:) to throw")
        } catch {
            expect(error as? BackendError) == .unexpectedBackendResponse(
                .workflowNotFound(workflowId: "wf_1"),
                extraContext: nil,
                .init(file: "", function: "", line: 0)
            )
        }
    }

    // MARK: - Helpers

    private static func webBundleURLStrings(
        in invocations: [[WebBundleScreenURLBatch]]
    ) -> [[[String]]] {
        return invocations.map { batches in
            batches.map { batch in batch.urls.map(\.url.absoluteString) }
        }
    }

    private static func offerings() -> Offerings {
        let offering = Offering(
            identifier: "default",
            serverDescription: "default",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let response = OfferingsResponse(
            currentOfferingId: offering.identifier,
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        return Offerings(
            offerings: [offering.identifier: offering],
            currentOfferingID: offering.identifier,
            placements: nil,
            targeting: nil,
            contents: .init(response: response, httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

    private static func workflowDataResult(
        id: String,
        webViewURLs: [String] = []
    ) throws -> WorkflowDataResult {
        return .init(
            workflow: try self.publishedWorkflow(id: id, webViewURLs: webViewURLs),
            uiConfig: .empty,
            enrolledVariants: nil
        )
    }

    private static func publishedWorkflow(
        id: String,
        webViewURLs: [String]
    ) throws -> PublishedWorkflow {
        #if os(watchOS) || os(tvOS) || !canImport(WebKit)
        if !webViewURLs.isEmpty {
            throw XCTSkip("Web view components are not supported on this platform")
        }
        #endif

        let components = webViewURLs.enumerated().map { index, url in
            """
            {
              "type": "web_view",
              "id": "web-\(index)",
              "protocol_version": 1,
              "url": "\(url)",
              "size": { "width": { "type": "fill" }, "height": { "type": "fill" } }
            }
            """
        }.joined(separator: ",\n")
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
                    "components": [
                      \(components)
                    ],
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
