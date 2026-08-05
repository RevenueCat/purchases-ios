//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointsManagerTests.swift
//
//  Created by Rick van der Linden.
//

import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@_spi(Internal) @testable import RevenueCat_CustomEntitlementComputation
#else
@_spi(Internal) @testable import RevenueCat
#endif

@MainActor
final class CheckpointsManagerTests: TestCase {

    private let presentableCheckpointIdentifier = "test_checkpoint"

    private var presenter: MockCheckpointPresenter!
    private var listener: MockCheckpointListener!
    private var resolver: MockCheckpointWorkflowResolver!
    private var manager: CheckpointsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.presenter = MockCheckpointPresenter()
        self.listener = MockCheckpointListener()
        self.resolver = MockCheckpointWorkflowResolver()
        self.resolver.presentableIdentifiers = [self.presentableCheckpointIdentifier]
        self.resolver.failedIdentifiers = ["error_checkpoint"]
        self.manager = CheckpointsManager(
            resolver: self.resolver,
            presenterProvider: { self.presenter }
        )
        self.manager.checkpointListener = self.listener
    }

    func testCheckpointParamsDropsInvalidCustomPropertiesWithWarning() {
        let params = CheckpointParams(customProperties: [
            "string": "value",
            "integer": 1,
            "double": 1.5,
            "boolean": true,
            "array": [1, 2, 3],
            "object": NSObject(),
            "null": NSNull()
        ])

        XCTAssertEqual(params.customProperties["string"] as? String, "value")
        XCTAssertEqual(params.customProperties["integer"] as? Int, 1)
        XCTAssertEqual(params.customProperties["double"] as? Double, 1.5)
        XCTAssertEqual(params.customProperties["boolean"] as? Bool, true)
        XCTAssertNil(params.customProperties["array"])
        XCTAssertNil(params.customProperties["object"])
        XCTAssertNil(params.customProperties["null"])

        for key in ["array", "object", "null"] {
            self.logger.verifyMessageWasLogged(
                "Dropping invalid checkpoint custom property '\(key)'",
                level: .warn,
                expectedCount: 1
            )
        }
    }

    func testCheckpointModelsExposeCheckpointAndDebugDescriptions() {
        let params = CheckpointParams()
        let checkpoint = CheckpointInfo(identifier: "test_checkpoint", params: params)
        let result = CheckpointNoActionResult(checkpoint: checkpoint, reason: .noMatch)

        XCTAssertEqual(result.checkpoint.identifier, "test_checkpoint")
        XCTAssertEqual(params.description, "CheckpointParams(customProperties=[:])")
        XCTAssertEqual(
            checkpoint.description,
            "CheckpointInfo(identifier='test_checkpoint', params=CheckpointParams(customProperties=[:]))"
        )
        XCTAssertEqual(
            result.description,
            "NoAction(checkpoint=\(checkpoint), reason=NO_MATCH)"
        )
        XCTAssertEqual(CheckpointPaywallDismissedOutcome().description, "Dismissed")
    }

    #if ENABLE_CHECKPOINTS_OBJC
    func testObjectiveCCheckpointResultWrappersPreserveAssociatedValues() throws {
        let checkpoint = CheckpointInfo(
            identifier: "test_checkpoint",
            params: CheckpointParams(customProperties: ["source": "objective-c"])
        )

        let presented = try XCTUnwrap(
            ObjCCheckpointResult.wrapping(
                CheckpointPaywallPresentedResult(
                    checkpoint: checkpoint,
                    paywallOutcome: CheckpointPaywallDismissedOutcome()
                )
            ) as? ObjCCheckpointPaywallPresentedResult
        )
        XCTAssertEqual(presented.checkpoint.identifier, "test_checkpoint")
        XCTAssertEqual(presented.checkpoint.params.customProperties["source"] as? String, "objective-c")
        XCTAssertTrue(presented.paywallOutcome is ObjCCheckpointPaywallDismissedOutcome)

        let noAction = try XCTUnwrap(
            ObjCCheckpointResult.wrapping(
                CheckpointNoActionResult(checkpoint: checkpoint, reason: .frequencyCapped)
            ) as? ObjCCheckpointNoActionResult
        )
        XCTAssertEqual(noAction.reason.value, "FREQUENCY_CAPPED")
    }
    #endif

    func testUnknownCheckpointResolvesNoActionWithNoMatch() {
        let completion = self.expectation(description: "Checkpoint completes")
        var completionResult: CheckpointResult?

        self.manager.checkpoint(identifier: "some_unknown_checkpoint", params: nil) { result in
            completionResult = try? result.get()
            self.listener.events.append(.completion)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)

        guard let noAction = completionResult as? CheckpointNoActionResult else {
            return XCTFail("Expected a no-action result")
        }
        XCTAssertEqual(noAction.reason, .noMatch)
        XCTAssertEqual(noAction.checkpoint.identifier, "some_unknown_checkpoint")
        XCTAssertEqual(
            self.listener.events,
            [
                .hit("some_unknown_checkpoint"),
                .completed("some_unknown_checkpoint"),
                .completion
            ]
        )
    }

    func testSimulatedErrorCheckpointCompletesWithConfigurationError() {
        let completion = self.expectation(description: "Checkpoint errors")

        self.manager.checkpoint(identifier: "error_checkpoint", params: nil) { result in
            guard case let .failure(error) = result else {
                return XCTFail("Expected checkpoint to fail")
            }
            XCTAssertEqual(error.code, ErrorCode.configurationError.rawValue)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testAwaitingSimulatedErrorCheckpointThrowsConfigurationError() async {
        do {
            _ = try await self.manager.checkpoint(identifier: "error_checkpoint", params: nil)
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual((error as NSError).code, ErrorCode.configurationError.rawValue)
        }
    }

    func testPresentableCheckpointErrorsWhenPresenterIsMissing() {
        self.manager = CheckpointsManager(resolver: self.resolver, presenterProvider: { nil })
        let completion = self.expectation(description: "Checkpoint errors")

        self.manager.checkpoint(identifier: self.presentableCheckpointIdentifier, params: nil) { result in
            guard case let .failure(error) = result else {
                return XCTFail("Expected checkpoint to fail")
            }
            XCTAssertEqual(error.code, ErrorCode.configurationError.rawValue)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testPresenterProviderCanPresentCheckpoint() async throws {
        self.manager = CheckpointsManager(
            resolver: self.resolver,
            presenterProvider: { self.presenter }
        )
        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome()
            )
        }

        let result = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        guard let presented = result as? CheckpointPaywallPresentedResult,
              presented.paywallOutcome is CheckpointPaywallDismissedOutcome else {
            return XCTFail("Expected a paywall-presented result")
        }
    }

    func testPresenterReceivesResolvedPresentationForCheckpointIdentifier() async throws {
        self.resolver.presentableIdentifiers.insert("soft_paywall")
        self.presenter.onPresent = { presentation in
            XCTAssertEqual(presentation.workflowPresentation.checkpoint.identifier, "soft_paywall")
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome()
            )
        }

        _ = try await self.manager.checkpoint(
            identifier: "soft_paywall",
            params: CheckpointParams(customProperties: ["name": "Rick"])
        )
    }

    func testCheckpointWithoutAvailableWorkflowDataResolvesConfigurationUnavailable() async throws {
        self.resolver.noMatchReason = .configurationUnavailable
        self.resolver.presentableIdentifiers = []

        let result = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        guard let noAction = result as? CheckpointNoActionResult else {
            return XCTFail("Expected a no-action result")
        }
        XCTAssertEqual(noAction.reason, .configurationUnavailable)
    }

    func testPresentableCheckpointResolvesPaywallPresentedWhenPaywallFinishes() async throws {
        let completion = self.expectation(description: "Checkpoint completes")
        let presentationStarted = self.expectation(description: "Checkpoint presentation starts")
        var completionResult: CheckpointResult?
        let params = CheckpointParams(customProperties: ["goal": "test"])
        self.presenter.onPresent = { _ in presentationStarted.fulfill() }

        self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: params
        ) { result in
            completionResult = try? result.get()
            self.listener.events.append(.completion)
            completion.fulfill()
        }

        XCTAssertNil(completionResult)
        await self.fulfillment(of: [presentationStarted], timeout: 1)
        let presentation = try XCTUnwrap(self.presenter.presentations.first)
        presentation.delegate.onCheckpointPaywallFinished(
            callID: presentation.callID,
            outcome: CheckpointPaywallDismissedOutcome()
        )
        await self.fulfillment(of: [completion], timeout: 1)

        guard let presented = completionResult as? CheckpointPaywallPresentedResult else {
            return XCTFail("Expected a paywall-presented result")
        }
        XCTAssertEqual(presented.checkpoint.identifier, self.presentableCheckpointIdentifier)
        XCTAssertEqual(presented.checkpoint.params.customProperties["goal"] as? String, "test")
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallDismissedOutcome)
        XCTAssertEqual(
            self.listener.events,
            [
                .hit("test_checkpoint"),
                .completed("test_checkpoint"),
                .completion
            ]
        )
    }

    func testAwaitingPresentableCheckpointResolvesPaywallPresentedWhenPaywallFinishes() async throws {
        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome()
            )
        }

        let result = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        guard let presented = result as? CheckpointPaywallPresentedResult else {
            return XCTFail("Expected a paywall-presented result")
        }
        XCTAssertEqual(presented.checkpoint.identifier, self.presentableCheckpointIdentifier)
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallDismissedOutcome)
    }

    func testConcurrentCheckpointErrorsWhilePresenting() async throws {
        let firstCheckpoint = Task {
            try await self.manager.checkpoint(
                identifier: self.presentableCheckpointIdentifier,
                params: nil
            )
        }
        await Task.yield()

        do {
            _ = try await self.manager.checkpoint(
                identifier: self.presentableCheckpointIdentifier,
                params: nil
            )
            XCTFail("Expected concurrent checkpoint to throw")
        } catch {
            XCTAssertEqual(
                (error as NSError).code,
                ErrorCode.operationAlreadyInProgressForProductError.rawValue
            )
            XCTAssertEqual(
                error.localizedDescription,
                "Another checkpoint experience is already being presented."
            )
        }

        let presentation = try XCTUnwrap(self.presenter.presentations.first)
        presentation.delegate.onCheckpointPaywallFinished(
            callID: presentation.callID,
            outcome: CheckpointPaywallDismissedOutcome()
        )
        _ = try await firstCheckpoint.value
    }

    func testCheckpointCanPresentAgainAfterPreviousUIFinishes() async throws {
        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome()
            )
        }

        _ = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )
        _ = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        XCTAssertEqual(self.presenter.presentations.count, 2)
    }

    func testCheckpointCanPresentAgainAfterPreviousCallIsCancelled() async throws {
        let firstPresentationStarted = self.expectation(description: "First presentation starts")
        self.presenter.onPresent = { _ in firstPresentationStarted.fulfill() }
        let firstCheckpoint = Task {
            try await self.manager.checkpoint(
                identifier: self.presentableCheckpointIdentifier,
                params: nil
            )
        }
        await self.fulfillment(of: [firstPresentationStarted], timeout: 1)

        firstCheckpoint.cancel()
        do {
            _ = try await firstCheckpoint.value
            XCTFail("Expected cancelled checkpoint to throw")
        } catch is CancellationError {
            // Expected.
        }

        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome()
            )
        }
        _ = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        XCTAssertEqual(self.presenter.presentations.count, 2)
    }

    func testUIFinishedReportForUnknownCallIDIsNoOp() {
        let executor = UICheckpointWorkflowExecutor(presenterProvider: { self.presenter })

        executor.onCheckpointPaywallFinished(
            callID: "unknown-call-id",
            outcome: CheckpointPaywallDismissedOutcome()
        )

        XCTAssertTrue(self.presenter.presentations.isEmpty)
        XCTAssertTrue(self.listener.events.isEmpty)
    }

}

private final class MockCheckpointPresenter: CheckpointPresenter {

    struct Presentation {
        let callID: String
        let workflowPresentation: CheckpointWorkflowPresentation
        let delegate: CheckpointPresenterDelegate
    }

    private(set) var presentations: [Presentation] = []
    var onPresent: ((Presentation) -> Void)?

    func present(
        callID: String,
        presentation: CheckpointWorkflowPresentation,
        delegate: CheckpointPresenterDelegate
    ) {
        let presentation = Presentation(
            callID: callID,
            workflowPresentation: presentation,
            delegate: delegate
        )
        self.presentations.append(presentation)
        self.onPresent?(presentation)
    }

}

private final class MockCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    var presentableIdentifiers: Set<String> = []
    var failedIdentifiers: Set<String> = []
    var noMatchReason: CheckpointNoActionReason = .noMatch

    func resolve(checkpoint: CheckpointInfo) async -> CheckpointWorkflowResolution {
        if self.failedIdentifiers.contains(checkpoint.identifier) {
            return .failed(
                ErrorUtils.configurationError(
                    message: "Unable to resolve checkpoint workflow."
                )
            )
        }

        if self.presentableIdentifiers.contains(checkpoint.identifier) {
            return .matched(CheckpointWorkflowPresentation(checkpoint: checkpoint))
        }

        return .noMatch(self.noMatchReason)
    }

}

private final class MockCheckpointListener: CheckpointListener {

    enum Event: Equatable {
        case hit(String)
        case completed(String)
        case completion
    }

    var events: [Event] = []

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        self.events.append(.hit(checkpoint.identifier))
    }

    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {
        self.events.append(.completed(checkpoint.identifier))
    }

}
