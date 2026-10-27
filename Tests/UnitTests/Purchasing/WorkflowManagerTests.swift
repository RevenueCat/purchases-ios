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
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]

        _ = try await self.manager.getWorkflow(workflowId: "wf_1")
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssets) == true
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsWorkflow?.id) == "wf_1"
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsUiConfig) == expected.uiConfig
        expect(self.mockWebBundleURLBatcher.invokedPublishPresentedWorkflowIDs) == ["wf_1"]
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

    // MARK: - cachedWorkflow(forOfferingId:)

    func testCachedWorkflowSchedulesAssetPrewarmingOnSuccess() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedCachedWorkflowResult = ["default": expected]

        let result = self.manager.cachedWorkflow(forOfferingId: "default")
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(result) == expected
        expect(self.mockProvider.invokedCachedWorkflowParameters) == ["default"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssets) == true
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsWorkflow?.id) == "wf_1"
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsUiConfig) == expected.uiConfig
        expect(self.mockWebBundleURLBatcher.invokedPublishPresentedWorkflowIDs) == ["wf_1"]
    }

    // MARK: - scheduleAssetPrewarmingForPrefetchedWorkflows

    func testScheduleAssetPrewarmingDecodesEveryCachedBodyAndPrewarmsAssets() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }
        let first = try Self.workflowDataResult(id: "wf_1")
        let second = try Self.workflowDataResult(id: "wf_2")
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1", "wf_2"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": first, "wf_2": second]

        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: "current")
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedCachePrefetchedWorkflowBodyDataParameters) == ["current"]
        expect(Set(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters)) == ["wf_1", "wf_2"]
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 2
    }

    func testScheduleAssetPrewarmingPreservesCurrentFirstOrder() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }
        let current = try Self.workflowDataResult(id: "wf_current")
        let prefetched = try Self.workflowDataResult(id: "wf_prefetched")
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_current", "wf_prefetched"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_current": current, "wf_prefetched": prefetched]

        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: "current")
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters)
            == ["wf_current", "wf_prefetched"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetIDs) == ["wf_current", "wf_prefetched"]
    }

    func testScheduleAssetPrewarmingDoesNotDecodeWorkflowsWhoseAssetPrewarmingStarted() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": try Self.workflowDataResult(id: "wf_1")]

        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: nil)
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: nil)
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 1
    }

    func testScheduleAssetPrewarmingDoesNotDecodeInline() async {
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1"]
        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: "current")

        expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread) == true
        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters).to(beEmpty())
    }

    func testScheduleAssetPrewarmingContinuesAfterADecodingFailure() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["broken", "working"]
        self.mockProvider.stubbedGetWorkflowError = ["broken": .notFound]
        self.mockProvider.stubbedGetWorkflowResult = ["working": try Self.workflowDataResult(id: "working")]

        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: nil)
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(Set(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters)) == ["broken", "working"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 1
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsWorkflow?.id) == "working"
        self.logger.verifyMessageWasLogged(
            Strings.paywalls.workflow_resolution_for_asset_prewarming_failed(
                workflowId: "broken",
                error: .notFound
            ),
            level: .debug
        )
    }

    func testScheduleAssetPrewarmingRetriesWorkflowResolutionFailures() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1"]
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .uiConfigUnavailable]

        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: nil)
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        self.mockProvider.stubbedGetWorkflowError = [:]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": try Self.workflowDataResult(id: "wf_1")]
        await self.manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: nil)
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1", "wf_1"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 1
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

    func testGetWorkflowForOfferingIdThrowsOfferingHasNoWorkflowWithoutFetchingWhenUnmapped() async {
        // No offeringId → workflowId mapping: the offering has no workflow attached. This fails fast
        // with a distinct error (so the paywall falls back to the default paywall) and must NOT attempt
        // a guaranteed-miss fetch by offering id. Mirrors purchases-android's presentWorkflow (#3760).
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
        // The offering maps to a workflow, but that workflow can't be resolved (a broken rollout, not
        // an unmapped offering). It must surface as `workflowNotFound` — which does NOT trigger the
        // default-paywall fallback — never `offeringHasNoWorkflow`.
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

    // MARK: - publishWebBundleURLs

    func testPublishWebBundleURLsPublishesResolvedTargetOfferingWorkflows() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("publishWebBundleURLs requires iOS 15+")
        }
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]
        let offerings = Self.offerings()

        await self.manager.publishWebBundleURLs(offerings: offerings)

        expect(self.mockProvider.invokedWorkflowIdForOfferingIdParameters) == ["default"]
        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 1
        expect(self.mockWebBundleURLBatcher.invokedPublishOfferings) === offerings
        expect(self.mockWebBundleURLBatcher.invokedPublishWorkflowsByOfferingId["default"]?.id) == "wf_1"
    }

    func testPublishWebBundleURLsDecodesSharedWorkflowOnlyOnce() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("publishWebBundleURLs requires iOS 15+")
        }
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedWorkflowIdForOfferingId = [
            "default": "wf_1",
            "placement_a": "wf_1",
            "placement_b": "wf_1"
        ]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]
        let offerings = Self.offerings(
            placements: .init(
                fallbackOfferingId: nil,
                offeringIdsByPlacement: [
                    "a": "placement_a",
                    "b": "placement_b"
                ]
            )
        )

        await self.manager.publishWebBundleURLs(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockWebBundleURLBatcher.invokedPublishWorkflowsByOfferingId.mapValues(\.id)) == [
            "default": "wf_1",
            "placement_a": "wf_1",
            "placement_b": "wf_1"
        ]
    }

    func testPublishWebBundleURLsSkipsUncachedWorkflowsWithoutFetching() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("publishWebBundleURLs requires iOS 15+")
        }
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .notFound]
        let offerings = Self.offerings()

        await self.manager.publishWebBundleURLs(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 1
        expect(self.mockWebBundleURLBatcher.invokedPublishWorkflowsByOfferingId).to(beEmpty())
    }

    func testPublishWebBundleURLsSkipsOfferingsWithoutAWorkflowMapping() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("publishWebBundleURLs requires iOS 15+")
        }
        let offerings = Self.offerings()

        await self.manager.publishWebBundleURLs(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters).to(beEmpty())
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 1
        expect(self.mockWebBundleURLBatcher.invokedPublishWorkflowsByOfferingId).to(beEmpty())
    }

    // MARK: - WorkflowPrewarmingDecodeCoordinator

    func testPrewarmingAndWebBundlePublishingShareTransientDecode() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("Workflow asset prewarming requires iOS 15+")
        }
        let provider = BlockingWorkflowPrewarmingDecodeProvider(result: try Self.workflowDataResult(id: "wf_1"))
        let coordinator = WorkflowPrewarmingDecodeCoordinator()
        let manager = WorkflowManager(
            workflowsConfigProvider: provider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher,
            workflowPrewarmingDecodeCoordinator: coordinator
        )

        await manager.scheduleAssetPrewarmingForPrefetchedWorkflows(includingOfferingId: "default")
        let prewarming = Task {
            await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        }
        let publishing = Task {
            await manager.publishWebBundleURLs(offerings: Self.offerings())
        }

        await expect { await coordinator.activeRequestCount }.toEventually(equal(2))
        expect(provider.decodeCount) == 1

        await provider.releaseDecodes()
        _ = await (prewarming.value, publishing.value)

        expect(provider.decodeCount) == 1
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 1
        expect(self.mockWebBundleURLBatcher.invokedPublishWorkflowsByOfferingId["default"]?.id) == "wf_1"
    }

    func testWorkflowPrewarmingDecodeCoordinatorCoalescesConcurrentRequestsForSameWorkflow() async throws {
        let provider = BlockingWorkflowPrewarmingDecodeProvider(result: try Self.workflowDataResult(id: "wf_1"))
        let coordinator = WorkflowPrewarmingDecodeCoordinator()
        let tasks = (0..<20).map { _ in
            Task {
                await coordinator.decode(workflowId: "wf_1", using: provider)
            }
        }

        await expect { await coordinator.activeRequestCount }.toEventually(equal(20))
        expect(provider.decodeCount) == 1
        await provider.releaseDecodes()
        for task in tasks {
            let result = try await task.value.get()
            expect(result.workflow.id) == "wf_1"
        }

        expect(provider.decodeCount) == 1
    }

    func testWorkflowPrewarmingDecodeCoordinatorDoesNotShareAcrossConfigGenerations() async throws {
        let provider = BlockingWorkflowPrewarmingDecodeProvider(result: try Self.workflowDataResult(id: "wf_1"))
        let coordinator = WorkflowPrewarmingDecodeCoordinator()
        let first = Task {
            await coordinator.decode(workflowId: "wf_1", using: provider)
        }
        await expect(provider.decodeCount).toEventually(equal(1))

        provider.configGeneration = 1
        let second = Task {
            await coordinator.decode(workflowId: "wf_1", using: provider)
        }

        await expect(provider.decodeCount).toEventually(equal(2))
        await provider.releaseDecodes()
        _ = await (first.value, second.value)

        expect(provider.decodeCount) == 2
    }

    func testWorkflowPrewarmingDecodeCoordinatorLimitsConcurrentDecodes() async throws {
        let provider = BlockingWorkflowPrewarmingDecodeProvider(result: try Self.workflowDataResult(id: "resolved"))
        let coordinator = WorkflowPrewarmingDecodeCoordinator(maxConcurrentDecodes: 4)
        let tasks = (0..<10).map { index in
            Task {
                await coordinator.decode(workflowId: "wf_\(index)", using: provider)
            }
        }

        await expect { await coordinator.activeRequestCount }.toEventually(equal(10))
        expect(provider.decodeCount) == 4

        await provider.releaseDecodes()
        for task in tasks {
            _ = await task.value
        }

        expect(provider.decodeCount) == 10
        expect(provider.maxConcurrentDecodeCount) == 4
    }

    // MARK: - Helpers

    private static func offerings(placements: Offerings.Placements? = nil) -> Offerings {
        let offering = Offering(
            identifier: "default",
            serverDescription: "default",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let response = OfferingsResponse(
            currentOfferingId: "default",
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        return Offerings(
            offerings: [offering.identifier: offering],
            currentOfferingID: "default",
            placements: placements,
            targeting: nil,
            contents: .init(response: response, httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

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

private final class BlockingWorkflowPrewarmingDecodeProvider: WorkflowsConfigProviderType, @unchecked Sendable {

    private let result: WorkflowDataResult
    private let gate = WorkflowDecodeGate()
    private let decodeCounter: Atomic<Int> = .init(0)
    private let activeDecodeCounter: Atomic<Int> = .init(0)
    private let maximumActiveDecodeCounter: Atomic<Int> = .init(0)
    private let generation: Atomic<Int> = .init(0)

    var decodeCount: Int { self.decodeCounter.value }
    var maxConcurrentDecodeCount: Int { self.maximumActiveDecodeCounter.value }
    var configGeneration: Int {
        get { self.generation.value }
        set { self.generation.value = newValue }
    }

    init(result: WorkflowDataResult) {
        self.result = result
    }

    func workflowId(forOfferingId offeringId: String) async -> String? { self.result.workflow.id }
    func workflowIds() async -> [String] { [] }

    func getWorkflow(workflowId: String) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        return .failure(.notFound)
    }

    func decodeCachedWorkflowForAssetPrewarming(
        workflowId: String
    ) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        self.decodeCounter.modify { $0 += 1 }
        let activeDecodeCount = self.activeDecodeCounter.modify {
            $0 += 1
            return $0
        }
        self.maximumActiveDecodeCounter.modify { $0 = max($0, activeDecodeCount) }
        await self.gate.wait()
        self.activeDecodeCounter.modify { $0 -= 1 }
        return .success(self.result)
    }

    func cachePrefetchedWorkflowBodyData(includingOfferingId: String?) async -> [String] {
        return [self.result.workflow.id]
    }
    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? { nil }

    func releaseDecodes() async {
        await self.gate.open()
    }

}

private actor WorkflowDecodeGate {

    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !self.isOpen else { return }
        await withCheckedContinuation { continuation in
            self.continuations.append(continuation)
        }
    }

    func open() {
        self.isOpen = true
        self.continuations.forEach { $0.resume() }
        self.continuations.removeAll()
    }

}
