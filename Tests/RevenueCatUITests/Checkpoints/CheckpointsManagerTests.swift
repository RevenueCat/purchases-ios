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

    func testObjectiveCParamsConvertAndRoundTripSupportedFoundationValues() throws {
        let params = ObjCCheckpointParams(customVariables: [
            "string": "value",
            "integer": NSNumber(value: Int64(42)),
            "double": NSNumber(value: 4.5),
            "true": NSNumber(value: true),
            "false": NSNumber(value: false)
        ])

        XCTAssertEqual(params.value.customVariables, [
            "string": .string("value"),
            "integer": .number(42),
            "double": .number(4.5),
            "true": .bool(true),
            "false": .bool(false)
        ])

        let roundTrip = ObjCCheckpointParams(customVariables: params.customVariables)
        XCTAssertEqual(roundTrip.value, params.value)
    }

    func testObjectiveCParamsDropUnsupportedValuesAndNonStringKeys() {
        let params = ObjCCheckpointParams(customVariables: [
            "valid": "value",
            "null": NSNull(),
            "date": Date(),
            "array": ["nested"],
            NSNumber(value: 1): "invalid key"
        ])

        XCTAssertEqual(params.value.customVariables, ["valid": .string("value")])
    }

    #endif

    func testCheckpointParamsConvertCustomVariableValuesForCoreResolution() {
        let params = RevenueCatUI.CheckpointParams(customVariables: [
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

    func testNoActionResultAndListenerEventsAreBuiltInRevenueCatUI() async throws {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        let listener = ListenerRecorder()
        manager.listener = listener

        let result = try await manager.checkpoint(
            identifier: "unknown_checkpoint",
            params: CheckpointParams(customVariables: ["name": "Rick"])
        )

        guard let noAction = result as? CheckpointNoActionResult else {
            return XCTFail("Expected a no-action result")
        }
        XCTAssertEqual(noAction.reason, .unknownCheckpoint)
        XCTAssertEqual(noAction.checkpoint.identifier, "unknown_checkpoint")
        XCTAssertEqual(noAction.checkpoint.params.customVariables["name"], "Rick")
        XCTAssertEqual(
            listener.events,
            [.hit("unknown_checkpoint"), .completed("unknown_checkpoint")]
        )
    }

    func testResolvedWorkflowProducesPaywallResult() async throws {
        let executor = MockCheckpointWorkflowExecutor()
        executor.outcome = CheckpointPaywallDismissedOutcome.shared
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let result = try await manager.checkpoint(identifier: "soft_paywall", params: .init())

        guard let presented = result as? CheckpointPaywallPresentedResult else {
            return XCTFail("Expected a presented-paywall result")
        }
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallDismissedOutcome)
        XCTAssertEqual(executor.executedWorkflows.map(\.workflow.id), ["workflow-id"])
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
        XCTAssertTrue(executor.executedWorkflows.isEmpty)
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
            XCTAssertEqual(noAction.reason, .disabled)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testUIOwnedReferenceModelsPreserveValueEqualityAndHashing() {
        let firstInfo = CheckpointInfo(
            identifier: "test",
            params: CheckpointParams(customVariables: ["name": "Rick"])
        )
        let secondInfo = CheckpointInfo(
            identifier: "test",
            params: CheckpointParams(customVariables: ["name": "Rick"])
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

    func testPresentationFailureResumesExecutionAndAllowsRetry() async throws {
        let presenter = MockCheckpointPresenter()
        let expectedError = NSError(domain: "test", code: 42)
        presenter.presentationError = expectedError
        let executor = CheckpointWorkflowExecutor { presenter }

        do {
            _ = try await executor.execute(Self.workflow())
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
        _ = try await executor.execute(Self.workflow())

        XCTAssertEqual(presenter.presentations.count, 1)
    }

    func testConcurrentExecutionFailsWhilePresentationIsActive() async throws {
        let presenter = MockCheckpointPresenter()
        let presentationStarted = self.expectation(description: "Presentation starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        let executor = CheckpointWorkflowExecutor { presenter }
        let firstExecution = Task { try await executor.execute(Self.workflow()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        do {
            _ = try await executor.execute(Self.workflow())
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

        _ = try await executor.execute(Self.workflow())
        _ = try await executor.execute(Self.workflow())

        XCTAssertEqual(presenter.presentations.count, 2)
    }

    func testExecutionCanRestartAfterCancellation() async throws {
        let presenter = MockCheckpointPresenter()
        let presentationStarted = self.expectation(description: "Presentation starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        let executor = CheckpointWorkflowExecutor { presenter }
        let firstExecution = Task { try await executor.execute(Self.workflow()) }
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
        _ = try await executor.execute(Self.workflow())

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
        let firstExecution = Task { try await executor.execute(Self.workflow()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        firstExecution.cancel()
        await self.fulfillment(of: [dismissalStarted], timeout: 1)

        do {
            _ = try await executor.execute(Self.workflow())
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

        execution = Task { try await executor.execute(Self.workflow()) }
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
    private(set) var executedWorkflows: [ResolvedCheckpointWorkflow] = []

    func execute(_ workflow: ResolvedCheckpointWorkflow) async throws -> CheckpointPaywallOutcome {
        self.executedWorkflows.append(workflow)
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
        let workflow: ResolvedCheckpointWorkflow
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
        workflow: ResolvedCheckpointWorkflow,
        delegate: CheckpointPresentationDelegate
    ) throws {
        if let presentationError {
            throw presentationError
        }
        let presentation = Presentation(workflow: workflow, delegate: delegate)
        self.presentations.append(presentation)
        self.onPresent?(presentation)
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
