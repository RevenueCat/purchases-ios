//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPrewarmingCoordinatorTests.swift
//
//  Created by Rick van der Linden on 11/3/26.

@preconcurrency import Combine
import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class WorkflowPrewarmingCoordinatorTests: TestCase {

    private var mockProvider: MockWorkflowsConfigProvider!
    private var mockPaywallCache: MockPaywallCacheWarming!
    private var mockOperationDispatcher: MockOperationDispatcher!
    private var mockWebBundleURLBatcher: MockWebBundleURLBatcher!
    private var coordinator: WorkflowPrewarmingCoordinator!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockProvider = MockWorkflowsConfigProvider()
        self.mockPaywallCache = MockPaywallCacheWarming()
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = false
        self.mockWebBundleURLBatcher = MockWebBundleURLBatcher()
        self.coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: self.mockProvider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher,
            decodeCoordinator: .init()
        )
    }

    // MARK: - schedulePrewarming

    func testScheduleAssetPrewarmingDecodesEveryCachedBodyAndPrewarmsAssets() async throws {
        try requireWorkflowPrewarmingAvailability()
        let first = try Self.workflowDataResult(id: "wf_1")
        let second = try Self.workflowDataResult(id: "wf_2")
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1", "wf_2"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": first, "wf_2": second]

        await self.coordinator.schedulePrewarming(offerings: Self.offerings())
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedCachePrefetchedWorkflowBodyDataParameters) == ["default"]
        expect(Set(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters)) == ["wf_1", "wf_2"]
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 2
    }

    func testScheduleAssetPrewarmingPreservesCurrentFirstOrder() async throws {
        try requireWorkflowPrewarmingAvailability()
        let current = try Self.workflowDataResult(id: "wf_current")
        let prefetched = try Self.workflowDataResult(id: "wf_prefetched")
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_current", "wf_prefetched"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_current": current, "wf_prefetched": prefetched]

        await self.coordinator.schedulePrewarming(offerings: Self.offerings())
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters)
            == ["wf_current", "wf_prefetched"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetIDs) == ["wf_current", "wf_prefetched"]
    }

    func testSchedulePrewarmingCompletesTargetWorkBeforeDecodingRemainingPrefetchedWorkflow() async throws {
        try requireWorkflowPrewarmingAvailability()
        let target = try Self.workflowDataResult(
            id: "wf_target",
            webViewURLs: ["https://example.com/target"]
        )
        let prefetched = try Self.workflowDataResult(
            id: "wf_prefetched",
            webViewURLs: ["https://example.com/prefetched"]
        )
        let eventLog = OrderedEventLog()
        let paywallCache = MockPaywallCacheWarming(onPrewarmWorkflowAssets: {
            eventLog.record("prewarm:\($0)")
        })
        let webBundleURLBatcher = MockWebBundleURLBatcher {
            eventLog.record("publish")
        }
        let provider = PriorityWorkflowPrewarmingDecodeProvider(
            results: ["wf_target": target, "wf_prefetched": prefetched],
            workflowIdByOfferingId: ["default": "wf_target"],
            cachedWorkflowIDs: ["wf_target", "wf_prefetched"],
            blockedWorkflowID: "wf_prefetched",
            eventLog: eventLog
        )
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: provider,
            paywallCache: paywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: webBundleURLBatcher,
            decodeCoordinator: .init()
        )

        await coordinator.schedulePrewarming(offerings: Self.offerings())
        let prewarming = Task {
            await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        }

        await expect(provider.decodedWorkflowIDs).toEventually(equal(["wf_target", "wf_prefetched"]))
        expect(eventLog.events) == [
            "decode:wf_target",
            "prewarm:wf_target",
            "publish",
            "decode:wf_prefetched"
        ]
        expect(Self.webBundleURLStrings(in: webBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/target"]]
        ]
        expect(paywallCache.invokedPrewarmWorkflowAssetIDs) == ["wf_target"]

        await provider.releaseBlockedDecode()
        await prewarming.value

        expect(paywallCache.invokedPrewarmWorkflowAssetIDs) == ["wf_target", "wf_prefetched"]
    }

    func testSchedulePrewarmingProcessesTargetAssetsSequentially() async throws {
        try requireWorkflowPrewarmingAvailability()
        let first = try Self.workflowDataResult(
            id: "wf_first",
            webViewURLs: ["https://example.com/first"]
        )
        let second = try Self.workflowDataResult(
            id: "wf_second",
            webViewURLs: ["https://example.com/second"]
        )
        let firstAssetDownloadGate = WorkflowDecodeGate()
        let startedAssetWorkflowIDs: Atomic<[String]> = .init([])
        let paywallCache = MockPaywallCacheWarming(workflowAssetPrewarmingHandler: { workflowID in
            startedAssetWorkflowIDs.modify { $0.append(workflowID) }
            if workflowID == "wf_first" {
                await firstAssetDownloadGate.wait()
            }
        })
        let webBundleURLBatcher = MockWebBundleURLBatcher()
        let provider = PriorityWorkflowPrewarmingDecodeProvider(
            results: ["wf_first": first, "wf_second": second],
            workflowIdByOfferingId: ["default": "wf_first", "placement": "wf_second"],
            cachedWorkflowIDs: ["wf_first", "wf_second"],
            blockedWorkflowID: "unused"
        )
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: provider,
            paywallCache: paywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: webBundleURLBatcher,
            decodeCoordinator: .init()
        )
        let offerings = Self.offerings(placements: .init(
            fallbackOfferingId: nil,
            offeringIdsByPlacement: ["placement_id": "placement"]
        ))

        await coordinator.schedulePrewarming(offerings: offerings)
        let prewarming = Task {
            await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        }

        await expect(webBundleURLBatcher.invokedPublishCount).toEventually(equal(1))
        await expect(startedAssetWorkflowIDs.value).toEventually(equal(["wf_first"]))
        expect(provider.decodedWorkflowIDs) == ["wf_first"]

        await firstAssetDownloadGate.open()
        await prewarming.value

        expect(provider.decodedWorkflowIDs) == ["wf_first", "wf_second"]
        expect(webBundleURLBatcher.invokedPublishCount) == 2
        expect(paywallCache.invokedPrewarmWorkflowAssetIDs) == ["wf_first", "wf_second"]
        expect(startedAssetWorkflowIDs.value) == ["wf_first", "wf_second"]
        expect(Self.webBundleURLStrings(in: webBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/first"]],
            [["https://example.com/second"]]
        ]
    }

    func testConcurrentBackgroundPassesRemainSequentialWhileOnDemandPrewarmingBypassesQueue() async throws {
        try requireWorkflowPrewarmingAvailability()
        let first = try Self.workflowDataResult(id: "wf_first")
        let second = try Self.workflowDataResult(id: "wf_second")
        let firstAssetDownloadGate = WorkflowDecodeGate()
        let startedAssetWorkflowIDs: Atomic<[String]> = .init([])
        let paywallCache = MockPaywallCacheWarming(workflowAssetPrewarmingHandler: { workflowID in
            startedAssetWorkflowIDs.modify { $0.append(workflowID) }
            if workflowID == "wf_first" {
                await firstAssetDownloadGate.wait()
            }
        })
        let provider = PriorityWorkflowPrewarmingDecodeProvider(
            results: ["wf_first": first, "wf_second": second],
            workflowIdByOfferingId: ["default": "wf_first", "placement": "wf_second"],
            cachedWorkflowIDs: ["wf_first", "wf_second"],
            blockedWorkflowID: "unused"
        )
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: provider,
            paywallCache: paywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher,
            decodeCoordinator: .init()
        )
        let offerings = Self.offerings(placements: .init(
            fallbackOfferingId: nil,
            offeringIdsByPlacement: ["placement_id": "placement"]
        ))

        await coordinator.schedulePrewarming(offerings: offerings)
        await coordinator.schedulePrewarming(offerings: offerings)
        let firstPass = Task {
            await self.mockOperationDispatcher.invokeDispatchedAsyncWorkerThreadBlock(at: 0)
        }
        await expect(startedAssetWorkflowIDs.value).toEventually(equal(["wf_first"]))

        let secondPass = Task {
            await self.mockOperationDispatcher.invokeDispatchedAsyncWorkerThreadBlock(at: 0)
        }
        await expect(startedAssetWorkflowIDs.value)
            .toNever(equal(["wf_first", "wf_second"]), until: .milliseconds(100))

        coordinator.scheduleAssetPrewarming(for: second)
        await self.mockOperationDispatcher.invokeDispatchedAsyncWorkerThreadBlock(at: 0)
        expect(startedAssetWorkflowIDs.value) == ["wf_first", "wf_second"]

        await firstAssetDownloadGate.open()
        _ = await (firstPass.value, secondPass.value)
        expect(startedAssetWorkflowIDs.value) == ["wf_first", "wf_second"]
    }

    func testSchedulePrewarmingPublishesWebBundlesWithoutWaitingForTargetAssetDownloads() async throws {
        try requireWorkflowPrewarmingAvailability()
        let target = try Self.workflowDataResult(
            id: "wf_target",
            webViewURLs: ["https://example.com/target"]
        )
        let eventLog = OrderedEventLog()
        let assetDownloadGate = WorkflowDecodeGate()
        let paywallCache = MockPaywallCacheWarming(
            workflowAssetPrewarmingHandler: { workflowID in
                await assetDownloadGate.wait()
                eventLog.record("asset-complete:\(workflowID)")
            },
            onPrewarmWorkflowAssets: { workflowID in
                eventLog.record("asset-download:\(workflowID)")
            }
        )
        let webBundleURLBatcher = MockWebBundleURLBatcher {
            eventLog.record("publish")
        }
        let provider = PriorityWorkflowPrewarmingDecodeProvider(
            results: ["wf_target": target],
            workflowIdByOfferingId: ["default": "wf_target"],
            cachedWorkflowIDs: ["wf_target"],
            blockedWorkflowID: "unused",
            eventLog: eventLog
        )
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: provider,
            paywallCache: paywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: webBundleURLBatcher,
            decodeCoordinator: .init()
        )

        await coordinator.schedulePrewarming(offerings: Self.offerings())
        let prewarming = Task {
            await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        }

        await expect(webBundleURLBatcher.invokedPublishCount).toEventually(equal(1))
        expect(Array(eventLog.events.prefix(3))) == [
            "decode:wf_target",
            "asset-download:wf_target",
            "publish"
        ]
        expect(eventLog.events).toNot(contain("asset-complete:wf_target"))

        await assetDownloadGate.open()
        await prewarming.value

        expect(eventLog.events).to(contain("asset-complete:wf_target"))
    }

    func testSchedulePrewarmingForwardsCancellationToAssetPrewarmingTasks() async throws {
        try requireWorkflowPrewarmingAvailability()
        let assetPrewarmingStarted: Atomic<Bool> = false
        let assetPrewarmingCancelled: Atomic<Bool> = false
        let paywallCache = MockPaywallCacheWarming(workflowAssetPrewarmingHandler: { _ in
            assetPrewarmingStarted.value = true
            await withTaskCancellationHandler {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            } onCancel: {
                assetPrewarmingCancelled.value = true
            }
        })
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: self.mockProvider,
            paywallCache: paywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher,
            decodeCoordinator: .init()
        )
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1"]
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": try Self.workflowDataResult(id: "wf_1")]

        await coordinator.schedulePrewarming(offerings: Self.offerings())
        let prewarming = Task {
            await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        }
        await expect(assetPrewarmingStarted.value).toEventually(beTrue())

        prewarming.cancel()
        await expect(assetPrewarmingCancelled.value).toEventually(beTrue())
        await prewarming.value
    }

    func testScheduleAssetPrewarmingDoesNotDecodeWorkflowsWhoseAssetPrewarmingStarted() async throws {
        try requireWorkflowPrewarmingAvailability()
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": try Self.workflowDataResult(id: "wf_1")]

        await self.coordinator.schedulePrewarming(offerings: Self.offerings())
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        await self.coordinator.schedulePrewarming(offerings: Self.offerings())
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 1
    }

    func testScheduleAssetPrewarmingContinuesAfterADecodingFailure() async throws {
        try requireWorkflowPrewarmingAvailability()
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["broken", "working"]
        self.mockProvider.stubbedGetWorkflowError = ["broken": .notFound]
        self.mockProvider.stubbedGetWorkflowResult = ["working": try Self.workflowDataResult(id: "working")]

        await self.coordinator.schedulePrewarming(offerings: Self.offerings())
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
        try requireWorkflowPrewarmingAvailability()
        self.mockProvider.stubbedWorkflowIDsWithCachedBodyData = ["wf_1"]
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .uiConfigUnavailable]

        await self.coordinator.schedulePrewarming(offerings: Self.offerings())
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        self.mockProvider.stubbedGetWorkflowError = [:]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": try Self.workflowDataResult(id: "wf_1")]
        await self.coordinator.schedulePrewarming(offerings: Self.offerings())
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1", "wf_1"]
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 1
    }

    // MARK: - Web bundle publishing

    func testPublishWebBundleURLsPublishesResolvedTargetOfferingWorkflows() async throws {
        try requireWorkflowPrewarmingAvailability()
        let expected = try Self.workflowDataResult(
            id: "wf_1",
            webViewURLs: ["https://example.com/workflow"]
        )
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]
        let offerings = Self.offerings()

        await self.runScheduledPrewarming(offerings: offerings)

        expect(self.mockProvider.invokedWorkflowIdForOfferingIdParameters) == ["default"]
        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 1
        expect(Self.webBundleURLStrings(in: self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/workflow"]]
        ]
    }

    func testPublishWebBundleURLsDecodesSharedWorkflowOnlyOnce() async throws {
        try requireWorkflowPrewarmingAvailability()
        let expected = try Self.workflowDataResult(
            id: "wf_1",
            webViewURLs: ["https://example.com/shared"]
        )
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

        await self.runScheduledPrewarming(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(Self.webBundleURLStrings(in: self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/shared"]]
        ]
    }

    func testPublishWebBundleURLsPreservesTargetOfferingOrder() async throws {
        try requireWorkflowPrewarmingAvailability()
        self.mockProvider.stubbedWorkflowIdForOfferingId = [
            "default": "wf_current",
            "placement": "wf_placement"
        ]
        self.mockProvider.stubbedGetWorkflowResult = [
            "wf_current": try Self.workflowDataResult(
                id: "wf_current",
                webViewURLs: ["https://example.com/current"]
            ),
            "wf_placement": try Self.workflowDataResult(
                id: "wf_placement",
                webViewURLs: ["https://example.com/placement"]
            )
        ]
        let offerings = Self.offerings(
            placements: .init(
                fallbackOfferingId: nil,
                offeringIdsByPlacement: ["placement_id": "placement"]
            )
        )

        await self.runScheduledPrewarming(offerings: offerings)

        expect(Self.webBundleURLStrings(in: self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/current"]],
            [["https://example.com/placement"]]
        ]
    }

    func testPublishWebBundleURLsDoesNotDecodePublishedWorkflowAgainForSameConfigGeneration() async throws {
        try requireWorkflowPrewarmingAvailability()
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]
        let offerings = Self.offerings()

        await self.runScheduledPrewarming(offerings: offerings)
        await self.runScheduledPrewarming(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 1
    }

    func testPublishWebBundleURLsIgnoresInlineOfferingComponents() async throws {
        try requireWorkflowPrewarmingAvailability()
        let eventBus = WebBundleEventBus()
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: self.mockProvider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: WebBundleURLBatcher(eventBus: eventBus),
            decodeCoordinator: .init()
        )
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["workflow": "wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = [
            "wf_1": try Self.workflowDataResult(
                id: "wf_1",
                webViewURLs: ["https://example.com/workflow"]
            )
        ]
        let offerings = try Self.workflowAndInlineOfferings()
        var receivedEvents: [WebBundleEvent] = []
        var cancellables: Set<AnyCancellable> = []
        eventBus.publisher
            .dropFirst()
            .sink { receivedEvents.append($0) }
            .store(in: &cancellables)

        await self.runScheduledPrewarming(using: coordinator, offerings: offerings)
        expect(Self.webBundleURLStrings(in: receivedEvents)) == ["https://example.com/workflow"]
        receivedEvents.removeAll()
        await self.runScheduledPrewarming(using: coordinator, offerings: offerings)

        expect(receivedEvents).to(beEmpty())
    }

    func testPublishWebBundleURLsDoesNotPublishFallbackAssetsForClaimedWorkflowOffering() async throws {
        try requireWorkflowPrewarmingAvailability()
        let provider = BlockingWorkflowPrewarmingDecodeProvider(
            result: try Self.workflowDataResult(id: "wf_1"),
            workflowIdByOfferingId: ["workflow": "wf_1"]
        )
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: provider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher,
            decodeCoordinator: .init()
        )
        let offerings = try Self.workflowAndInlineOfferings()
        await coordinator.schedulePrewarming(offerings: offerings)
        let firstPublication = Task {
            await self.mockOperationDispatcher.invokeDispatchedAsyncWorkerThreadBlock(at: 0)
        }

        await expect(provider.decodeCount).toEventually(equal(1))
        await coordinator.schedulePrewarming(offerings: offerings)
        let secondPublication = Task {
            await self.mockOperationDispatcher.invokeDispatchedAsyncWorkerThreadBlock(at: 0)
        }
        await provider.releaseDecodes()
        _ = await (firstPublication.value, secondPublication.value)

        let urls = self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches
            .flatMap { $0 }
            .flatMap(\.urls)
            .map(\.url.absoluteString)
        expect(urls.filter { $0 == "https://example.com/workflow-fallback" }.count) == 0
    }

    func testConcurrentBackgroundPassesAreSerializedAndPublishWorkflowOncePerConfigGeneration() async throws {
        try requireWorkflowPrewarmingAvailability()
        let provider = BlockingWorkflowPrewarmingDecodeProvider(result: try Self.workflowDataResult(id: "wf_1"))
        let decodeCoordinator = WorkflowPrewarmingDecodeCoordinator()
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: provider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher,
            decodeCoordinator: decodeCoordinator
        )
        let offerings = Self.offerings()
        self.mockOperationDispatcher.forwardToOriginalDispatchOnWorkerThread = true
        let tasks = (0..<20).map { _ in
            Task { await coordinator.schedulePrewarming(offerings: offerings) }
        }

        await expect { await decodeCoordinator.activeRequestCount }.toEventually(equal(1))
        await expect(provider.decodeCount).toEventually(equal(1))
        await provider.releaseDecodes()
        for task in tasks {
            await task.value
        }

        await expect(self.mockWebBundleURLBatcher.invokedPublishCount).toEventually(equal(1))
    }

    func testPublishWebBundleURLsPublishesWorkflowAgainForNewConfigGeneration() async throws {
        try requireWorkflowPrewarmingAvailability()
        let expected = try Self.workflowDataResult(id: "wf_1")
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]
        let offerings = Self.offerings()

        await self.runScheduledPrewarming(offerings: offerings)
        self.mockProvider.configGeneration = 1
        await self.runScheduledPrewarming(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1", "wf_1"]
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 2
    }

    func testPublishWebBundleURLsRetriesWorkflowThatFailedToDecode() async throws {
        try requireWorkflowPrewarmingAvailability()
        let expected = try Self.workflowDataResult(
            id: "wf_1",
            webViewURLs: ["https://example.com/retried"]
        )
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .notFound]
        let offerings = Self.offerings()

        await self.runScheduledPrewarming(offerings: offerings)
        self.mockProvider.stubbedGetWorkflowError = [:]
        self.mockProvider.stubbedGetWorkflowResult = ["wf_1": expected]
        await self.runScheduledPrewarming(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1", "wf_1"]
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 1
        expect(Self.webBundleURLStrings(in: self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/retried"]]
        ]
    }

    func testPublishWebBundleURLsSkipsUncachedWorkflowsWithoutFetching() async throws {
        try requireWorkflowPrewarmingAvailability()
        self.mockProvider.stubbedWorkflowIdForOfferingId = ["default": "wf_1"]
        self.mockProvider.stubbedGetWorkflowError = ["wf_1": .notFound]
        let offerings = Self.offerings()

        await self.runScheduledPrewarming(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters) == ["wf_1"]
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 0
    }

    func testPublishWebBundleURLsSkipsOfferingsWithoutWorkflowMappingOrInlineURLs() async throws {
        try requireWorkflowPrewarmingAvailability()
        let offerings = Self.offerings()

        await self.runScheduledPrewarming(offerings: offerings)

        expect(self.mockProvider.invokedDecodeCachedWorkflowForAssetPrewarmingParameters).to(beEmpty())
        expect(self.mockProvider.invokedGetWorkflowParameters).to(beEmpty())
        expect(self.mockWebBundleURLBatcher.invokedPublishCount) == 0
    }

    // MARK: - WorkflowPrewarmingDecodeCoordinator

    func testPrewarmingAndWebBundlePublishingShareTransientDecode() async throws {
        try requireWorkflowPrewarmingAvailability()
        let provider = BlockingWorkflowPrewarmingDecodeProvider(result: try Self.workflowDataResult(
            id: "wf_1",
            webViewURLs: ["https://example.com/shared-decode"]
        ))
        let decodeCoordinator = WorkflowPrewarmingDecodeCoordinator()
        let coordinator = WorkflowPrewarmingCoordinator(
            workflowsConfigProvider: provider,
            paywallCache: self.mockPaywallCache,
            operationDispatcher: self.mockOperationDispatcher,
            webBundleURLBatcher: self.mockWebBundleURLBatcher,
            decodeCoordinator: decodeCoordinator
        )

        await coordinator.schedulePrewarming(offerings: Self.offerings())
        let prewarming = Task {
            await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
        }

        await expect { await decodeCoordinator.activeRequestCount }.toEventually(equal(1))
        await expect(provider.decodeCount).toEventually(equal(1))

        await provider.releaseDecodes()
        await prewarming.value

        expect(provider.decodeCount) == 1
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetsCount) == 1
        expect(self.mockPaywallCache.invokedPrewarmWorkflowAssetIDs) == ["wf_1"]
        expect(Self.webBundleURLStrings(in: self.mockWebBundleURLBatcher.invokedPublishScreenURLBatches)) == [
            [["https://example.com/shared-decode"]]
        ]
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
        await expect(provider.decodeCount).toEventually(equal(1))
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
        await expect(provider.decodeCount).toEventually(equal(4))

        await provider.releaseDecodes()
        for task in tasks {
            _ = await task.value
        }

        expect(provider.decodeCount) == 10
        expect(provider.maxConcurrentDecodeCount) == 4
    }

    // MARK: - Helpers

    private func runScheduledPrewarming(
        using coordinator: WorkflowPrewarmingCoordinator? = nil,
        offerings: Offerings
    ) async {
        await (coordinator ?? self.coordinator).schedulePrewarming(offerings: offerings)
        await self.mockOperationDispatcher.invokeAllDispatchedAsyncWorkerThreadBlocks()
    }

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

    private static func workflowAndInlineOfferings() throws -> Offerings {
        let workflowOffering = try self.offering(
            id: "workflow",
            webViewURL: "https://example.com/workflow-fallback"
        )
        let inlineOffering = try self.offering(
            id: "inline",
            webViewURL: "https://example.com/inline"
        )
        let response = OfferingsResponse(
            currentOfferingId: workflowOffering.identifier,
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        return Offerings(
            offerings: [
                workflowOffering.identifier: workflowOffering,
                inlineOffering.identifier: inlineOffering
            ],
            currentOfferingID: workflowOffering.identifier,
            placements: .init(
                fallbackOfferingId: nil,
                offeringIdsByPlacement: ["inline": inlineOffering.identifier]
            ),
            targeting: nil,
            contents: .init(response: response, httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

    private static func offering(id: String, webViewURL: String) throws -> Offering {
        let components: [PaywallComponent] = [
            .webView(.init(id: "web", protocolVersion: 1, url: webViewURL))
        ]
        let paywallComponents = Offering.PaywallComponents(
            uiConfig: .empty,
            data: .init(
                templateName: "test",
                assetBaseURL: try XCTUnwrap(URL(string: "https://assets.example.com")),
                componentsConfig: .init(base: .init(
                    stack: .init(components: components),
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#ffffff")))
                )),
                componentsLocalizations: [:],
                revision: 1,
                defaultLocaleIdentifier: "en_US"
            )
        )
        return Offering(
            identifier: id,
            serverDescription: id,
            paywallComponents: paywallComponents,
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

    private static func webBundleURLStrings(in events: [WebBundleEvent]) -> [String] {
        return events.flatMap { event -> [String] in
            guard case let .receivedAssetURLs(urls) = event else { return [] }
            return urls.map(\.url.absoluteString)
        }
    }

    private static func webBundleURLStrings(
        in invocations: [[WebBundleScreenURLBatch]]
    ) -> [[[String]]] {
        return invocations.map { batches in
            batches.map { batch in batch.urls.map(\.url.absoluteString) }
        }
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
        webViewURLs: [String] = []
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

private final class PriorityWorkflowPrewarmingDecodeProvider: WorkflowsConfigProviderType, @unchecked Sendable {

    private let results: [String: WorkflowDataResult]
    private let workflowIdByOfferingId: [String: String]
    private let cachedWorkflowIDs: [String]
    private let blockedWorkflowID: String
    private let eventLog: OrderedEventLog?
    private let gate = WorkflowDecodeGate()
    private let decodedIDs: Atomic<[String]> = .init([])

    let configGeneration = 0
    var decodedWorkflowIDs: [String] { self.decodedIDs.value }

    init(
        results: [String: WorkflowDataResult],
        workflowIdByOfferingId: [String: String],
        cachedWorkflowIDs: [String],
        blockedWorkflowID: String,
        eventLog: OrderedEventLog? = nil
    ) {
        self.results = results
        self.workflowIdByOfferingId = workflowIdByOfferingId
        self.cachedWorkflowIDs = cachedWorkflowIDs
        self.blockedWorkflowID = blockedWorkflowID
        self.eventLog = eventLog
    }

    func workflowId(forOfferingId offeringId: String) async -> String? {
        return self.workflowIdByOfferingId[offeringId]
    }

    func workflowIds() async -> [String] { return [] }

    func getWorkflow(workflowId: String) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        return .failure(.notFound)
    }

    func decodeCachedWorkflowForAssetPrewarming(
        workflowId: String
    ) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        self.eventLog?.record("decode:\(workflowId)")
        self.decodedIDs.modify { $0.append(workflowId) }
        if workflowId == self.blockedWorkflowID {
            await self.gate.wait()
        }
        guard let result = self.results[workflowId] else { return .failure(.notFound) }
        return .success(result)
    }

    func cachePrefetchedWorkflowBodyData(includingOfferingId: String?) async -> [String] {
        return self.cachedWorkflowIDs
    }

    func cachedWorkflow(forOfferingId offeringId: String) -> WorkflowDataResult? { return nil }

    func releaseBlockedDecode() async {
        await self.gate.open()
    }

}

private final class OrderedEventLog: @unchecked Sendable {

    private let recordedEvents: Atomic<[String]> = .init([])

    var events: [String] { self.recordedEvents.value }

    func record(_ event: String) {
        self.recordedEvents.modify { $0.append(event) }
    }

}

private final class BlockingWorkflowPrewarmingDecodeProvider: WorkflowsConfigProviderType, @unchecked Sendable {

    private let result: WorkflowDataResult
    private let gate = WorkflowDecodeGate()
    private let decodeCounter: Atomic<Int> = .init(0)
    private let activeDecodeCounter: Atomic<Int> = .init(0)
    private let maximumActiveDecodeCounter: Atomic<Int> = .init(0)
    private let generation: Atomic<Int> = .init(0)
    private let workflowIdByOfferingId: [String: String]?

    var decodeCount: Int { self.decodeCounter.value }
    var maxConcurrentDecodeCount: Int { self.maximumActiveDecodeCounter.value }
    var configGeneration: Int {
        get { self.generation.value }
        set { self.generation.value = newValue }
    }

    init(result: WorkflowDataResult, workflowIdByOfferingId: [String: String]? = nil) {
        self.result = result
        self.workflowIdByOfferingId = workflowIdByOfferingId
    }

    func workflowId(forOfferingId offeringId: String) async -> String? {
        if let workflowIdByOfferingId {
            return workflowIdByOfferingId[offeringId]
        }
        return self.result.workflow.id
    }
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
