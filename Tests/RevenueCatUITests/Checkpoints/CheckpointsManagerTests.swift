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

@_spi(Internal) @testable import RevenueCat
@_spi(CheckpointsInternal) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointsManagerTests: TestCase {

    #if ENABLE_CHECKPOINTS_OBJC

    func testObjectiveCCustomVariablesConvertSupportedFoundationValues() throws {
        let params = CheckpointCallParams(objectiveCCustomVariables: [
            "string": "value",
            "integer": NSNumber(value: Int64(42)),
            "double": NSNumber(value: 4.5),
            "true": NSNumber(value: true),
            "false": NSNumber(value: false)
        ])

        XCTAssertEqual(params.customVariables, [
            "string": .string("value"),
            "integer": .number(42),
            "double": .number(4.5),
            "true": .bool(true),
            "false": .bool(false)
        ])

    }

    func testObjectiveCCustomVariablesDropUnsupportedValuesAndNonStringKeys() {
        let params = CheckpointCallParams(objectiveCCustomVariables: [
            "valid": "value",
            "invalid-key": "value",
            "null": NSNull(),
            "date": Date(),
            "array": ["nested"],
            NSNumber(value: 1): "invalid key"
        ])

        XCTAssertEqual(params.customVariables, ["valid": .string("value")])
    }

    func testObjectiveCResultWrapsInvalidIdentifierNoActionResult() throws {
        let identifier = "invalid checkpoint"
        let checkpoint = CheckpointInfo(identifier: identifier, params: .init())
        let result = CheckpointNoActionResult(
            checkpoint: checkpoint,
            reason: .invalidCheckpointIdentifier
        )

        let objcResult = try XCTUnwrap(
            ObjCCheckpointResult.wrapping(result) as? ObjCCheckpointNoActionResult
        )

        XCTAssertEqual(objcResult.checkpoint.identifier, identifier)
        XCTAssertEqual(objcResult.reason.value, "INVALID_CHECKPOINT_IDENTIFIER")
    }

    #endif

    func testCheckpointCallParamsConvertCustomVariableValuesForCoreResolution() {
        let params = CheckpointCallParams(customVariables: [
            "string": "value",
            "integer": 42,
            "double": 4.5,
            "boolean": true
        ])

        let expected: [String: RevenueCat.CheckpointValue] = [
            "string": .string("value"),
            "integer": .double(42),
            "double": .double(4.5),
            "boolean": .boolean(true)
        ]

        XCTAssertEqual(params.coreParams.customVariables, expected)
    }

    func testCheckpointCallParamsDropInvalidCustomVariableKeys() {
        let params = CheckpointCallParams(customVariables: [
            "valid_key": "value",
            "invalid-key": "value",
            "1valid": "value",
            "_valid": "value",
            "": "value"
        ])

        XCTAssertEqual(params.customVariables, [
            "valid_key": "value",
            "1valid": "value",
            "_valid": "value"
        ])
        XCTAssertEqual(params.coreParams.customVariables, [
            "valid_key": .string("value"),
            "1valid": .string("value"),
            "_valid": .string("value")
        ])
    }

    func testNoActionResultAndListenerEventsAreBuiltInRevenueCatUI() async throws {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        let listener = ListenerRecorder()
        manager.listener = listener

        let result = try await manager.checkpoint(
            identifier: "unknown_checkpoint",
            params: CheckpointCallParams(customVariables: ["name": "Rick"])
        )

        guard let noAction = result as? CheckpointNoActionResult else {
            return XCTFail("Expected a no-action result")
        }
        XCTAssertEqual(noAction.reason, .unknownCheckpoint)
        XCTAssertEqual(noAction.checkpoint.identifier, "unknown_checkpoint")
        XCTAssertEqual(noAction.checkpoint.customVariables["name"], "Rick")
        XCTAssertEqual(
            listener.events,
            [.hit("unknown_checkpoint"), .completed("unknown_checkpoint")]
        )
    }

    func testInvalidCustomVariableKeysDoNotReachResolution() async throws {
        var resolvedParams: CheckpointCallParams?
        let manager = CheckpointsManager { _, params in
            resolvedParams = params
            return .noAction(.noMatch)
        }

        _ = try await manager.checkpoint(
            identifier: "test",
            params: CheckpointCallParams(customVariables: [
                "valid_key": "value",
                "invalid-key": "value"
            ])
        )

        XCTAssertEqual(resolvedParams?.customVariables, ["valid_key": "value"])
    }

    func testResolvedWorkflowProducesPaywallResult() async throws {
        let executor = MockCheckpointWorkflowExecutor()
        executor.outcome = CheckpointPaywallDismissedOutcome.shared
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let customVariables: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true,
            "invalid-key": "not forwarded"
        ]
        let result = try await manager.checkpoint(
            identifier: "soft_paywall",
            params: .init(customVariables: customVariables)
        )

        guard let presented = result as? CheckpointPaywallPresentedResult else {
            return XCTFail("Expected a presented-paywall result")
        }
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallDismissedOutcome)
        XCTAssertEqual(executor.presentations.map(\.workflow.workflow.id), ["workflow-id"])
        XCTAssertEqual(executor.presentations.first?.customVariables, [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ])
    }

    func testResolvedOfferingProducesReceivedOfferingResultWithoutPresenting() async throws {
        let executor = MockCheckpointWorkflowExecutor()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: executor
        )
        let listener = ListenerRecorder()
        manager.listener = listener

        let result = try await manager.checkpoint(identifier: "onboarding", params: .init())

        guard let received = result as? CheckpointReceivedOfferingResult else {
            return XCTFail("Expected a received-offering result")
        }
        XCTAssertEqual(received.offering.identifier, "offering-id")
        XCTAssertEqual(received.checkpoint.identifier, "onboarding")
        // Data-only, so it never claims the executor's one-presentation-at-a-time slot.
        XCTAssertTrue(executor.presentations.isEmpty)
        XCTAssertEqual(listener.events, [.hit("onboarding"), .completed("onboarding")])
    }

    func testResolutionErrorIsForwardedWithoutCompletedListenerEvent() async {
        let expectedError = NSError(domain: "test", code: 42)
        let manager = CheckpointsManager { _, _ in throw expectedError }
        let listener = ListenerRecorder()
        manager.listener = listener

        do {
            _ = try await manager.checkpoint(identifier: "error_checkpoint", params: .init())
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

        XCTAssertEqual(listener.events, [.hit("error_checkpoint")])
    }

    func testPresentationErrorIsForwardedWithoutPresentedResultOrCompletedListenerEvent() async {
        let expectedError = NSError(domain: "test", code: 42)
        let executor = MockCheckpointWorkflowExecutor()
        executor.error = expectedError
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )
        let listener = ListenerRecorder()
        manager.listener = listener

        do {
            _ = try await manager.checkpoint(identifier: "soft_paywall", params: .init())
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

        XCTAssertEqual(listener.events, [.hit("soft_paywall")])
    }

    func testCompletionAPIForwardsResult() {
        let completion = self.expectation(description: "Checkpoint completes")
        let manager = CheckpointsManager { _, _ in .noAction(.disabled) }

        manager.checkpoint(identifier: "disabled", params: .init()) { result in
            guard case let .success(noAction as CheckpointNoActionResult) = result else {
                return XCTFail("Expected a no-action result")
            }
            XCTAssertEqual(noAction.reason, .configurationUnavailable)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testValidCheckpointIdentifierReachesListenerAndResolution() async throws {
        var resolvedIdentifiers: [String] = []
        let manager = CheckpointsManager { identifier, _ in
            resolvedIdentifiers.append(identifier)
            return .noAction(.noMatch)
        }
        let listener = ListenerRecorder()
        manager.listener = listener

        _ = try await manager.checkpoint(identifier: "A-1_b", params: .init())

        XCTAssertEqual(resolvedIdentifiers, ["A-1_b"])
        XCTAssertEqual(listener.events, [.hit("A-1_b"), .completed("A-1_b")])
    }

    func testInvalidCheckpointIdentifierIsLoggedAndReportedToListenerWithoutResolution() async throws {
        let invalidIdentifier = " checkout😀"
        var resolutionCount = 0
        let manager = CheckpointsManager { _, _ in
            resolutionCount += 1
            return .noAction(.noMatch)
        }
        let listener = ListenerRecorder()
        manager.listener = listener

        let result = try await manager.checkpoint(identifier: invalidIdentifier, params: .init())

        guard let noActionResult = result as? CheckpointNoActionResult else {
            return XCTFail("Expected a no-action result")
        }

        XCTAssertEqual(noActionResult.reason, .invalidCheckpointIdentifier)
        XCTAssertEqual(noActionResult.checkpoint.identifier, invalidIdentifier)
        XCTAssertEqual(resolutionCount, 0)
        XCTAssertEqual(listener.events, [.hit(invalidIdentifier), .completed(invalidIdentifier)])
        self.logger.verifyMessageWasLogged(
            CheckpointIdentifierValidator.invalidIdentifierLogMessage(invalidIdentifier),
            level: .error
        )
    }

    func testCompletionAPIReturnsInvalidIdentifierNoActionResult() {
        let completion = self.expectation(description: "Checkpoint completes")
        var resolutionCount = 0
        let manager = CheckpointsManager { _, _ in
            resolutionCount += 1
            return .noAction(.noMatch)
        }

        manager.checkpoint(identifier: "invalid checkpoint", params: .init()) { result in
            guard case let .success(noAction as CheckpointNoActionResult) = result else {
                return XCTFail("Expected an invalid-identifier no-action result")
            }

            XCTAssertEqual(noAction.reason, .invalidCheckpointIdentifier)
            XCTAssertEqual(resolutionCount, 0)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testUIOwnedReferenceModelsPreserveValueEqualityAndHashing() {
        let firstInfo = CheckpointInfo(
            identifier: "test",
            params: CheckpointCallParams(customVariables: ["name": "Rick"])
        )
        let secondInfo = CheckpointInfo(
            identifier: "test",
            params: CheckpointCallParams(customVariables: ["name": "Rick"])
        )
        let firstResult = CheckpointNoActionResult(checkpoint: firstInfo, reason: .noMatch)
        let secondResult = CheckpointNoActionResult(checkpoint: secondInfo, reason: .noMatch)

        XCTAssertEqual(firstInfo, secondInfo)
        XCTAssertEqual(firstResult, secondResult)
        XCTAssertEqual(Set([firstInfo, secondInfo]).count, 1)
        XCTAssertEqual(Set([firstResult, secondResult]).count, 1)
    }

    private static func offering() -> Offering {
        return Offering(
            identifier: "offering-id",
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

    private static func workflow() -> ResolvedCheckpointWorkflow {
        let offering = Self.offering()
        return ResolvedCheckpointWorkflow(
            workflow: PublishedWorkflow(
                id: "workflow-id",
                displayName: "Test",
                initialStepId: "step-id",
                singleStepFallbackId: nil,
                steps: ["step-id": WorkflowStep(id: "step-id", type: "screen", screenId: nil)],
                screens: [:]
            ),
            uiConfig: .empty,
            offering: offering,
            offerings: .preview(offerings: [offering])
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowExecutorTests: TestCase {

    func testCustomVariablesAreForwardedToThePresenter() async throws {
        let expected: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ]
        let presenter = MockCheckpointPresenter()
        presenter.onPresent = { presentation in
            presentation.delegate.checkpointPresentationFinished(
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }
        let executor = CheckpointWorkflowExecutor { presenter }

        _ = try await executor.execute(Self.presentation(customVariables: expected))

        XCTAssertEqual(
            presenter.presentations.first?.checkpointPresentation.customVariables,
            expected
        )
    }

    func testPresentationFailureResumesExecutionAndAllowsRetry() async throws {
        let presenter = MockCheckpointPresenter()
        let expectedError = NSError(domain: "test", code: 42)
        presenter.presentationError = expectedError
        let executor = CheckpointWorkflowExecutor { presenter }

        do {
            _ = try await executor.execute(Self.presentation())
            XCTFail("Expected presentation failure")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

        presenter.presentationError = nil
        presenter.onPresent = { presentation in
            presentation.delegate.checkpointPresentationFinished(
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }
        _ = try await executor.execute(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 1)
    }

    func testConcurrentExecutionFailsWhilePresentationIsActive() async throws {
        let presenter = MockCheckpointPresenter()
        let presentationStarted = self.expectation(description: "Presentation starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        let executor = CheckpointWorkflowExecutor { presenter }
        let firstExecution = Task { try await executor.execute(Self.presentation()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        do {
            _ = try await executor.execute(Self.presentation())
            XCTFail("Expected concurrent execution to throw")
        } catch {
            XCTAssertEqual(
                (error as NSError).code,
                ErrorCode.operationAlreadyInProgressForProductError.rawValue
            )
        }

        let presentation = try XCTUnwrap(presenter.presentations.first)
        presentation.delegate.checkpointPresentationFinished(
            outcome: CheckpointPaywallDismissedOutcome.shared
        )
        _ = try await firstExecution.value
    }

    func testExecutionCanRestartAfterPresentationFinishes() async throws {
        let presenter = MockCheckpointPresenter()
        presenter.onPresent = { presentation in
            presentation.delegate.checkpointPresentationFinished(
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }
        let executor = CheckpointWorkflowExecutor { presenter }

        _ = try await executor.execute(Self.presentation())
        _ = try await executor.execute(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 2)
    }

    func testExecutionCanRestartAfterCancellation() async throws {
        let presenter = MockCheckpointPresenter()
        let presentationStarted = self.expectation(description: "Presentation starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        let executor = CheckpointWorkflowExecutor { presenter }
        let firstExecution = Task { try await executor.execute(Self.presentation()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        firstExecution.cancel()
        do {
            _ = try await firstExecution.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        }

        presenter.onPresent = { presentation in
            presentation.delegate.checkpointPresentationFinished(
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }
        _ = try await executor.execute(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 2)
        XCTAssertEqual(presenter.dismissCallCount, 1)
    }

    func testCancellationKeepsExecutionActiveUntilPresentationFinishesDismissing() async throws {
        let presenter = MockCheckpointPresenter()
        presenter.automaticallyFinishesDismissing = false
        let presentationStarted = self.expectation(description: "Presentation starts")
        let dismissalStarted = self.expectation(description: "Dismissal starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        presenter.onDismiss = { dismissalStarted.fulfill() }
        let executor = CheckpointWorkflowExecutor { presenter }
        let firstExecution = Task { try await executor.execute(Self.presentation()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        firstExecution.cancel()
        await self.fulfillment(of: [dismissalStarted], timeout: 1)

        do {
            _ = try await executor.execute(Self.presentation())
            XCTFail("Expected execution to remain active while dismissing")
        } catch {
            XCTAssertEqual(
                (error as NSError).code,
                ErrorCode.operationAlreadyInProgressForProductError.rawValue
            )
        }

        presenter.finishDismissing()
        do {
            _ = try await firstExecution.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        }
    }

    func testCompletedOutcomeWinsBeforeScheduledCancellationRuns() async throws {
        let presenter = MockCheckpointPresenter()
        let expectedError = NSError(domain: "test", code: 42)
        let expectedOutcome = CheckpointPaywallErrorOutcome(error: expectedError)
        var execution: Task<CheckpointPaywallOutcome, Error>?
        presenter.onPresent = { presentation in
            execution?.cancel()
            presentation.delegate.checkpointPresentationFinished(
                outcome: expectedOutcome
            )
        }
        let executor = CheckpointWorkflowExecutor { presenter }

        execution = Task { try await executor.execute(Self.presentation()) }
        let outcome = try await XCTUnwrap(execution).value

        guard let errorOutcome = outcome as? CheckpointPaywallErrorOutcome else {
            return XCTFail("Expected the completed presentation outcome")
        }
        XCTAssertEqual(errorOutcome.error, expectedError)
        XCTAssertEqual(presenter.dismissCallCount, 0)
    }

    func testPresentationCompletionWithoutPendingExecutionIsIgnored() {
        let presenter = MockCheckpointPresenter()
        let executor = CheckpointWorkflowExecutor { presenter }

        executor.checkpointPresentationFinished(
            outcome: CheckpointPaywallDismissedOutcome.shared
        )

        XCTAssertTrue(presenter.presentations.isEmpty)
    }

    private static func presentation(
        customVariables: [String: CustomVariableValue] = [:]
    ) -> CheckpointPresentation {
        return CheckpointPresentation(
            workflow: self.workflow(),
            customVariables: customVariables
        )
    }

    private static func workflow() -> ResolvedCheckpointWorkflow {
        let offering = Offering(
            identifier: "offering-id",
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        return ResolvedCheckpointWorkflow(
            workflow: PublishedWorkflow(
                id: "workflow-id",
                displayName: "Test",
                initialStepId: "step-id",
                singleStepFallbackId: nil,
                steps: ["step-id": WorkflowStep(id: "step-id", type: "screen", screenId: nil)],
                screens: [:]
            ),
            uiConfig: .empty,
            offering: offering,
            offerings: .preview(offerings: [offering])
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockCheckpointWorkflowExecutor: CheckpointExecutor {

    var outcome: CheckpointPaywallOutcome = CheckpointPaywallDismissedOutcome.shared
    var error: Error?
    private(set) var presentations: [CheckpointPresentation] = []

    func execute(_ presentation: CheckpointPresentation) async throws -> CheckpointPaywallOutcome {
        self.presentations.append(presentation)
        if let error {
            throw error
        }
        return self.outcome
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockCheckpointPresenter: CheckpointPresenter {

    struct Presentation {
        let checkpointPresentation: CheckpointPresentation
        let delegate: CheckpointPresentationDelegate
    }

    var onPresent: ((Presentation) -> Void)?
    var onDismiss: (() -> Void)?
    var automaticallyFinishesDismissing = true
    var presentationError: Error?
    private(set) var presentations: [Presentation] = []
    private(set) var dismissCallCount = 0
    private var dismissalCompletions: [() -> Void] = []

    func present(
        presentation: CheckpointPresentation,
        delegate: CheckpointPresentationDelegate
    ) throws {
        if let presentationError {
            throw presentationError
        }
        let record = Presentation(checkpointPresentation: presentation, delegate: delegate)
        self.presentations.append(record)
        self.onPresent?(record)
    }

    func dismiss(completion: @escaping () -> Void) {
        self.dismissCallCount += 1
        self.onDismiss?()
        if self.automaticallyFinishesDismissing {
            completion()
        } else {
            self.dismissalCompletions.append(completion)
        }
    }

    func finishDismissing() {
        self.dismissalCompletions.removeFirst()()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class ListenerRecorder: CheckpointListener {

    enum Event: Equatable {
        case hit(String)
        case completed(String)
    }

    private(set) var events: [Event] = []

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        self.events.append(.hit(checkpoint.identifier))
    }

    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {
        self.events.append(.completed(checkpoint.identifier))
    }

}
