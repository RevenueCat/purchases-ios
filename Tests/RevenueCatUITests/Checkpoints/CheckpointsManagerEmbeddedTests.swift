//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointsManagerEmbeddedTests.swift
//
//  Created by Cesar de la Vega.
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

// swiftlint:disable file_length

@MainActor
@available(iOS 15.0, macOS 12.0, *)
final class CheckpointsManagerEmbeddedTests: TestCase {

    private var fixture: EmbeddedParentFixture!

    override func setUp() {
        super.setUp()
        self.fixture = EmbeddedParentFixture()
    }

    override func tearDown() {
        self.fixture = nil
        super.tearDown()
    }

    func testNoMatchPassesAndFinishesOnce() async {
        let manager = Self.manager { _, _ in .noAction(.noMatch) }
        let finished = expectation(description: "finished")
        var passes = 0
        var finishes = 0

        let execution = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { _, _ in XCTFail("Unexpected error") },
            onPassed: { result in
                passes += 1
                XCTAssertNil(result.flow)
            },
            onFinished: { finishes += 1; finished.fulfill() }
        )
        await fulfillment(of: [finished], timeout: 2)
        execution.cancel()

        XCTAssertEqual(passes, 1)
        XCTAssertEqual(finishes, 1)
        XCTAssertTrue(self.fixture.parent.children.isEmpty)
    }

    func testMatchedWorkflowEmbedsInParentAndPassesOnClose() async throws {
        let workflow = try EmbeddedCheckpointPresentationTests.workflow()
        let manager = Self.manager { _, _ in .matchedWorkflow(workflow) }
        let finished = expectation(description: "finished")
        var passes = 0
        var finishes = 0

        _ = manager.checkpointEmbedded(
            "test", customVariables: ["name": "Ada"], parentViewController: self.fixture.parent,
            errorPresenter: { _, _ in XCTFail("Unexpected error") },
            onPassed: { _ in
                passes += 1
                XCTAssertEqual(finishes, 0, "onPassed precedes onFinished")
            },
            onFinished: { finishes += 1; finished.fulfill() }
        )
        await self.waitForEmbeddedController()
        let controller = try XCTUnwrap(self.fixture.embeddedController)
        XCTAssertEqual(controller.customVariables, ["name": "Ada"])
        XCTAssertTrue(controller.delegate is WorkflowPresenter)
        XCTAssertNil(self.fixture.parent.presentedViewController)

        controller.continueAfterCheckpointError()
        await fulfillment(of: [finished], timeout: 2)

        XCTAssertEqual(passes, 1)
        XCTAssertEqual(finishes, 1)
        XCTAssertTrue(self.fixture.parent.children.isEmpty)
    }

    func testMatchedOfferingEmbedsSDKPaywallAndIgnoresCustomPresenter() async throws {
        var synchronizations = 0
        let manager = Self.manager(
            resolveCheckpoint: { _, _ in
                .matchedOffering(EmbeddedCheckpointPresentationTests.offering(), traceID: "trace")
            },
            customerInfoSynchronizer: {
                synchronizations += 1
                return TestData.customerInfo
            }
        )
        let globalPresenter = CountingPaywallPresenter()
        manager.paywallPresenter = globalPresenter
        let finished = expectation(description: "finished")
        var passes = 0

        _ = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { _, _ in XCTFail("Unexpected error") },
            onPassed: { _ in passes += 1 },
            onFinished: { finished.fulfill() }
        )
        await self.waitForEmbeddedController()
        let controller = try XCTUnwrap(self.fixture.embeddedController)
        XCTAssertTrue(controller.delegate is DefaultPaywallPresenter)
        XCTAssertEqual(globalPresenter.callCount, 0)

        controller.continueAfterCheckpointError()
        await fulfillment(of: [finished], timeout: 2)
        XCTAssertTrue(self.fixture.parent.children.isEmpty)
        // Closing the SDK paywall continues the checkpoint: purchases are synced and the result is delivered.
        XCTAssertEqual(synchronizations, 1)
        XCTAssertEqual(passes, 1)
    }

    func testUnusableParentAtStartFailsThroughErrorPresenterWithoutResolving() async {
        let offscreen = EmbeddedParentFixture(inWindow: false)
        var resolutions = 0
        let manager = Self.manager { _, _ in
            resolutions += 1
            return .noAction(.noMatch)
        }
        let finished = expectation(description: "finished")
        var kinds: [CheckpointFailureKind] = []
        var finishes = 0

        _ = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: offscreen.parent,
            errorPresenter: { params, completion in
                kinds.append(params.kind)
                completion.complete()
            },
            onPassed: { _ in XCTFail("Must not pass") },
            onFinished: { finishes += 1; finished.fulfill() }
        )
        await fulfillment(of: [finished], timeout: 2)

        XCTAssertEqual(kinds, [.flowCouldNotBeShown])
        XCTAssertEqual(resolutions, 0)
        XCTAssertEqual(finishes, 1)
        XCTAssertNil(self.fixture.parent.presentedViewController)
    }

    func testParentLeavingScreenDuringResolutionFailsWithoutModalFallback() async {
        var resolution: CheckedContinuation<CheckpointResolution, Error>?
        let resolving = expectation(description: "resolving")
        let manager = Self.manager { _, _ in
            try await withCheckedThrowingContinuation { continuation in
                resolution = continuation
                resolving.fulfill()
            }
        }
        let finished = expectation(description: "finished")
        var kinds: [CheckpointFailureKind] = []

        _ = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { params, completion in
                kinds.append(params.kind)
                completion.complete()
            },
            onPassed: { _ in XCTFail("Must not pass") },
            onFinished: { finished.fulfill() }
        )
        await fulfillment(of: [resolving], timeout: 2)
        self.fixture.window.rootViewController = nil
        self.fixture.window.isHidden = true
        resolution?.resume(returning: .matchedOffering(EmbeddedCheckpointPresentationTests.offering(),
                                                       traceID: "trace"))
        await fulfillment(of: [finished], timeout: 2)

        XCTAssertEqual(kinds, [.flowCouldNotBeShown])
        XCTAssertTrue(self.fixture.parent.children.isEmpty)
        XCTAssertNil(self.fixture.parent.presentedViewController)
    }

    func testCancellationRemovesChildAndConcurrentCallRetiresIndependently() async throws {
        var synchronizations = 0
        let manager = Self.manager(
            resolveCheckpoint: { _, _ in
                .matchedOffering(EmbeddedCheckpointPresentationTests.offering(), traceID: "trace")
            },
            customerInfoSynchronizer: {
                synchronizations += 1
                throw CancellationError()
            }
        )
        let secondParent = EmbeddedParentFixture()
        var firstFinishes = 0
        let firstFinished = expectation(description: "first finished")
        let first = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { _, _ in XCTFail("Unexpected error") },
            onPassed: { _ in XCTFail("Cancelled execution passed") },
            onFinished: { firstFinishes += 1; firstFinished.fulfill() }
        )
        await self.waitForEmbeddedController()
        XCTAssertNotNil(self.fixture.embeddedController)

        let secondFinished = expectation(description: "second finished")
        _ = manager.checkpointEmbedded(
            "second", customVariables: [:], parentViewController: secondParent.parent,
            errorPresenter: { _, _ in XCTFail("Concurrent call showed error") },
            onPassed: { _ in XCTFail("Concurrent execution passed") },
            onFinished: { secondFinished.fulfill() }
        )
        await fulfillment(of: [secondFinished], timeout: 2)
        XCTAssertTrue(secondParent.parent.children.isEmpty)
        XCTAssertNotNil(self.fixture.embeddedController)
        XCTAssertEqual(firstFinishes, 0)

        first.cancel()
        first.cancel()
        await fulfillment(of: [firstFinished], timeout: 2)

        XCTAssertTrue(self.fixture.parent.children.isEmpty)
        XCTAssertEqual(firstFinishes, 1)
        XCTAssertEqual(synchronizations, 0)
    }

    func testCancelAfterRemovalDoesNotWaitForSynchronization() async throws {
        let syncing = expectation(description: "syncing")
        var sync: CheckedContinuation<CustomerInfo, Error>?
        let manager = Self.manager(
            resolveCheckpoint: { _, _ in
                .matchedOffering(EmbeddedCheckpointPresentationTests.offering(), traceID: "trace")
            },
            customerInfoSynchronizer: {
                try await withCheckedThrowingContinuation { continuation in
                    sync = continuation
                    syncing.fulfill()
                }
            }
        )
        var finishes = 0
        let execution = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { _, _ in XCTFail("Unexpected error") },
            onPassed: { _ in XCTFail("Cancelled execution passed") },
            onFinished: { finishes += 1 }
        )
        await self.waitForEmbeddedController()
        try XCTUnwrap(self.fixture.embeddedController).continueAfterCheckpointError()
        await fulfillment(of: [syncing], timeout: 2)

        execution.cancel()

        XCTAssertEqual(finishes, 1)
        sync?.resume(throwing: CancellationError())
    }

    func testCancelDuringResolutionSuppressesLatePresentation() async {
        var resolution: CheckedContinuation<CheckpointResolution, Error>?
        let resolving = expectation(description: "resolving")
        let manager = Self.manager { _, _ in
            try await withCheckedThrowingContinuation { continuation in
                resolution = continuation
                resolving.fulfill()
            }
        }
        var finishes = 0
        let execution = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { _, _ in XCTFail("Unexpected error") },
            onPassed: { _ in XCTFail("Cancelled execution passed") },
            onFinished: { finishes += 1 }
        )
        await fulfillment(of: [resolving], timeout: 2)

        execution.cancel()
        execution.cancel()
        XCTAssertEqual(finishes, 1)

        resolution?.resume(returning: .matchedOffering(EmbeddedCheckpointPresentationTests.offering(),
                                                       traceID: "trace"))
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(self.fixture.parent.children.isEmpty)
        XCTAssertEqual(finishes, 1)
    }

    func testCancelRetiresPendingErrorAndIgnoresStaleReply() async {
        let manager = Self.manager { _, _ in throw CheckpointError.configurationUnavailable }
        let errorShown = expectation(description: "error shown")
        var reply: ErrorPresentationCompletion?
        var finishes = 0
        let execution = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { _, completion in
                reply = completion
                errorShown.fulfill()
            },
            onPassed: { _ in XCTFail("Cancelled execution passed") },
            onFinished: { finishes += 1 }
        )
        await fulfillment(of: [errorShown], timeout: 2)

        execution.cancel()
        reply?.complete()
        reply?.complete()
        await Task.yield()

        XCTAssertEqual(finishes, 1)
    }

    func testCoveringErrorKeepsChildAttachedUntilAcknowledged() async throws {
        let workflow = try EmbeddedCheckpointPresentationTests.workflow()
        let manager = Self.manager { _, _ in .matchedWorkflow(workflow) }
        var reply: ErrorPresentationCompletion?
        let errorShown = expectation(description: "error shown")
        let finished = expectation(description: "finished")
        var finishes = 0
        var passes = 0
        _ = manager.checkpointEmbedded(
            "test", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { params, completion in
                XCTAssertEqual(params.kind, .flowActionFailed)
                reply = completion
                errorShown.fulfill()
            },
            onPassed: { _ in passes += 1 },
            onFinished: { finishes += 1; finished.fulfill() }
        )
        await self.waitForEmbeddedController()
        let controller = try XCTUnwrap(self.fixture.embeddedController)

        controller.delegate?.paywallViewController?(
            controller, didFailPurchasingWith: NSError(domain: "test", code: 7)
        )
        await fulfillment(of: [errorShown], timeout: 2)
        // The error UI covers the paywall; the child stays attached and execution stays active.
        controller.viewDidDisappear(false)
        XCTAssertTrue(controller.parent === self.fixture.parent)
        XCTAssertEqual(finishes, 0)

        reply?.complete()
        XCTAssertTrue(controller.parent === self.fixture.parent)
        controller.continueAfterCheckpointError()
        await fulfillment(of: [finished], timeout: 2)
        XCTAssertEqual(finishes, 1)
        XCTAssertEqual(passes, 1, "Closing after a recovered error still passes")
    }

    func testCancelQueuedStartupErrorReleasesOnlyItsExecution() async throws {
        let manager = Self.manager { identifier, _ in
            if identifier == "A" { throw CheckpointError.configurationUnavailable }
            return .matchedOffering(EmbeddedCheckpointPresentationTests.offering(), traceID: "trace")
        }
        let aShown = expectation(description: "A error shown")
        var aCompletion: ErrorPresentationCompletion?
        var aFinishes = 0
        _ = manager.checkpointEmbedded(
            "A", customVariables: [:], parentViewController: self.fixture.parent,
            errorPresenter: { _, completion in aCompletion = completion; aShown.fulfill() },
            onPassed: { _ in XCTFail("A must not pass") }, onFinished: { aFinishes += 1 }
        )
        await fulfillment(of: [aShown], timeout: 2)
        defer { aCompletion?.complete() }

        // B's parent is off screen, so B queues a startup error behind A's open error UI.
        let offscreen = EmbeddedParentFixture(inWindow: false)
        let bFinished = expectation(description: "B finished independently")
        var bFinishes = 0
        let second = manager.checkpointEmbedded(
            "B", customVariables: [:], parentViewController: offscreen.parent,
            errorPresenter: { _, _ in XCTFail("B queued error must never be shown") },
            onPassed: { _ in XCTFail("B must not pass") },
            onFinished: { bFinishes += 1; bFinished.fulfill() }
        )
        let queue = try XCTUnwrap(
            Mirror(reflecting: manager).descendant("errorPresentationQueue") as? ErrorPresentationQueue
        )
        let pendingCount = {
            Mirror(reflecting: queue).descendant("pendingPresentations").map {
                Mirror(reflecting: $0).children.count
            } ?? -1
        }
        await expect { pendingCount() }.toEventually(equal(1), timeout: .seconds(2))

        second.cancel()
        second.cancel()
        await fulfillment(of: [bFinished], timeout: 2)
        XCTAssertEqual(bFinishes, 1)
        XCTAssertEqual(pendingCount(), 0)
        XCTAssertEqual(aFinishes, 0)
    }

    private static func manager(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        customerInfoSynchronizer: @escaping CheckpointsManager.CustomerInfoSynchronizer = { throw CancellationError() }
    ) -> CheckpointsManager {
        return CheckpointsManager(
            resolveCheckpoint: resolveCheckpoint,
            customerInfoProvider: { TestData.customerInfo },
            customerInfoSynchronizer: customerInfoSynchronizer
        )
    }

    private func waitForEmbeddedController() async {
        let deadline = Date().addingTimeInterval(2)
        while self.fixture.embeddedController == nil, Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, *)
private final class CountingPaywallPresenter: PaywallPresenter {

    private(set) var callCount = 0

    func present(params: PaywallPresentationParams, completion: @escaping PaywallPresentationCompletion) {
        self.callCount += 1
        completion(.continued)
    }

}

#endif
