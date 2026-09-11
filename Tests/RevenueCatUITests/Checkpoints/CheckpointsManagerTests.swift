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

    func testNoActionResultIsBuiltInRevenueCatUI() async throws {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }

        let result = try await manager.checkpoint(
            identifier: "unknown_checkpoint",
            params: CheckpointCallParams(customVariables: ["name": "Rick"])
        )

        guard let noAction = result as? CheckpointResult.NoAction else {
            return XCTFail("Expected a no-action result")
        }
        XCTAssertEqual(noAction.reason, .unknownCheckpoint)
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
        executor.execution = .completed(CheckpointPaywallOutcome.Dismissed.shared)
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

        guard let presented = result as? CheckpointResult.PaywallPresented else {
            return XCTFail("Expected a presented-paywall result")
        }
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallOutcome.Dismissed)
        XCTAssertEqual(executor.presentations.map(\.workflow.workflow.id), ["workflow-id"])
        XCTAssertEqual(executor.presentations.first?.customVariables, [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ])
    }

    func testCallbackCheckpointReturnsCompletedResultAfterWorkflowDismissal() async {
        let executor = MockCheckpointWorkflowExecutor()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements, [])
    }

    func testCallbackCheckpointIsSuppressedWhenWorkflowBacksOut() async {
        let executor = MockCheckpointWorkflowExecutor()
        executor.execution = .backedOut(CheckpointPaywallOutcome.Dismissed.shared)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
    }

    func testCallbackCheckpointIsSuppressedWhenAnotherFlowIsBeingPresented() async {
        let executor = MockCheckpointWorkflowExecutor()
        executor.error = CheckpointError.operationAlreadyInProgress
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
    }

    func testUnmatchedCallbackCheckpointStillCompletesWhileAnotherFlowIsBeingPresented() async {
        let executor = MockCheckpointWorkflowExecutor()
        executor.error = CheckpointError.operationAlreadyInProgress
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .noAction(.noMatch) },
            executor: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertNil(flowResult)
        XCTAssertTrue(executor.presentations.isEmpty)
    }

    func testCallbackCheckpointReturnsNilWhenResolutionFails() async {
        let manager = CheckpointsManager { _, _ in throw NSError(domain: "test", code: 1) }

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertNil(flowResult)
    }

    func testCallbackCheckpointReturnsNilWhenWorkflowErrors() async {
        let executor = MockCheckpointWorkflowExecutor()
        executor.execution = .completed(
            CheckpointPaywallOutcome.Error(error: NSError(domain: "test", code: 1))
        )
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertNil(flowResult)
    }

    func testRunCheckpointRecordsBackOutWithoutChangingDismissedOutcome() async throws {
        let executor = MockCheckpointWorkflowExecutor()
        executor.execution = .backedOut(CheckpointPaywallOutcome.Dismissed.shared)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case let .backedOut(result) = execution,
              let presented = result as? CheckpointResult.PaywallPresented else {
            return XCTFail("Expected a presented-paywall result")
        }
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallOutcome.Dismissed)
    }

    func testRunCheckpointKeepsErrorOutcomeWhenBackedOut() async throws {
        let executor = MockCheckpointWorkflowExecutor()
        let error = NSError(domain: "test", code: 42)
        executor.execution = .backedOut(CheckpointPaywallOutcome.Error(error: error))
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case let .backedOut(result) = execution,
              let outcome = (result as? CheckpointResult.PaywallPresented)?.paywallOutcome
            as? CheckpointPaywallOutcome.Error else {
            return XCTFail("Expected an error outcome")
        }
        XCTAssertEqual(outcome.error, error)
    }

    func testRunCheckpointDoesNotMarkNormalDismissalAsBackedOut() async throws {
        let executor = MockCheckpointWorkflowExecutor()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case .completed = execution else {
            return XCTFail("Expected a completed checkpoint execution")
        }
    }

    func testResolvedOfferingUsesCallSitePaywallPresenter() async throws {
        let executor = MockCheckpointWorkflowExecutor()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: executor
        )
        var receivedParams: PaywallPresentationParams?
        let result = try await manager.checkpoint(
            identifier: "onboarding",
            params: .init(customVariables: ["source": "test"], paywallPresenter: { params, completion in
                receivedParams = params
                completion(.closed)
            })
        )

        guard let presented = result as? CheckpointResult.PaywallPresented else {
            return XCTFail("Expected a presented-paywall result")
        }
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallOutcome.Dismissed)
        XCTAssertEqual(receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(receivedParams?.customVariables, ["source": "test"])
        XCTAssertEqual(receivedParams?.offering.identifier, "offering-id")
        XCTAssertTrue(executor.presentations.isEmpty)
    }

    func testCallSitePaywallPresenterOverridesGlobalPresenter() async throws {
        let global = MockPaywallPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: MockCheckpointWorkflowExecutor()
        )
        manager.paywallPresenter = global
        var localCallCount = 0

        _ = try await manager.checkpoint(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in
                localCallCount += 1
                completion(.closed)
            })
        )

        XCTAssertEqual(localCallCount, 1)
        XCTAssertEqual(global.callCount, 0)
    }

    func testResolvedOfferingUsesGlobalPaywallPresenter() async throws {
        let global = MockPaywallPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: MockCheckpointWorkflowExecutor()
        )
        manager.paywallPresenter = global

        _ = try await manager.checkpoint(identifier: "onboarding", params: .init())

        XCTAssertEqual(global.callCount, 1)
        XCTAssertEqual(global.receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(global.receivedParams?.offering.identifier, "offering-id")
    }

    func testNavigatedBackSuppressesCheckpointCallback() async {
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: MockCheckpointWorkflowExecutor()
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.navigatedBack) })
        )

        guard case .suppressed = result else {
            return XCTFail("Expected a backed-out presentation to suppress the callback")
        }
    }

    func testClosedCompletesCheckpointCallbackWithoutEntitlements() async {
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: MockCheckpointWorkflowExecutor()
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.closed) })
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements, [])
    }

    func testContinuedWithoutPurchasingCompletesCheckpointCallbackWithoutEntitlements() async {
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: MockCheckpointWorkflowExecutor()
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.continuedWithoutPurchasing) })
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements, [])
    }

    func testPurchasedFetchesCurrentCustomerInfo() async throws {
        let customerInfo = CustomerInfoFixtures.customerInfoWithAppleSubscriptions
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            executor: MockCheckpointWorkflowExecutor(),
            fetchCustomerInfo: { customerInfo }
        )

        let result = try await manager.checkpoint(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in
                completion(.purchased)
            })
        )

        guard let purchase = (result as? CheckpointResult.PaywallPresented)?.paywallOutcome
            as? CheckpointPaywallOutcome.Purchased else {
            return XCTFail("Expected a purchased paywall outcome")
        }
        XCTAssertEqual(purchase.customerInfo, customerInfo)
        XCTAssertNil(purchase.transaction)
    }

    func testResolutionErrorIsForwarded() async {
        let expectedError = NSError(domain: "test", code: 42)
        let manager = CheckpointsManager { _, _ in throw expectedError }

        do {
            _ = try await manager.checkpoint(identifier: "error_checkpoint", params: .init())
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

    }

    func testPresentationErrorIsForwardedWithoutPresentedResult() async {
        let expectedError = NSError(domain: "test", code: 42)
        let executor = MockCheckpointWorkflowExecutor()
        executor.error = expectedError
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            executor: executor
        )
        do {
            _ = try await manager.checkpoint(identifier: "soft_paywall", params: .init())
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

    }

    func testCompletionAPIForwardsResult() {
        let completion = self.expectation(description: "Checkpoint completes")
        let manager = CheckpointsManager { _, _ in .noAction(.configurationUnavailable) }

        manager.checkpoint(identifier: "disabled", params: .init()) { result in
            guard case let .success(noAction as CheckpointResult.NoAction) = result else {
                return XCTFail("Expected a no-action result")
            }
            XCTAssertEqual(noAction.reason, .configurationUnavailable)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testValidCheckpointIdentifierReachesResolution() async throws {
        var resolvedIdentifiers: [String] = []
        let manager = CheckpointsManager { identifier, _ in
            resolvedIdentifiers.append(identifier)
            return .noAction(.noMatch)
        }
        _ = try await manager.checkpoint(identifier: "A-1_b", params: .init())

        XCTAssertEqual(resolvedIdentifiers, ["A-1_b"])
    }

    func testInvalidCheckpointIdentifierIsLoggedWithoutResolution() async throws {
        let invalidIdentifier = " checkout😀"
        var resolutionCount = 0
        let manager = CheckpointsManager { _, _ in
            resolutionCount += 1
            return .noAction(.noMatch)
        }
        let result = try await manager.checkpoint(identifier: invalidIdentifier, params: .init())

        guard let noActionResult = result as? CheckpointResult.NoAction else {
            return XCTFail("Expected a no-action result")
        }

        XCTAssertEqual(noActionResult.reason, .invalidCheckpointIdentifier)
        XCTAssertEqual(resolutionCount, 0)
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
            guard case let .success(noAction as CheckpointResult.NoAction) = result else {
                return XCTFail("Expected an invalid-identifier no-action result")
            }

            XCTAssertEqual(noAction.reason, .invalidCheckpointIdentifier)
            XCTAssertEqual(resolutionCount, 0)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
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
            presentation.delegate.checkpointPresentationFinished(.completed(CheckpointPaywallOutcome.Dismissed.shared))
        }
        let executor = CheckpointWorkflowExecutor { presenter }

        _ = try await executor.execute(Self.presentation(customVariables: expected))

        XCTAssertEqual(
            presenter.presentations.first?.checkpointPresentation.customVariables,
            expected
        )
    }

    func testExecutionForwardsBackOutFromThePresenter() async throws {
        let presenter = MockCheckpointPresenter()
        presenter.onPresent = { presentation in
            presentation.delegate.checkpointPresentationFinished(.backedOut(CheckpointPaywallOutcome.Dismissed.shared))
        }
        let executor = CheckpointWorkflowExecutor { presenter }

        let execution = try await executor.execute(Self.presentation())

        guard case let .backedOut(outcome) = execution else {
            return XCTFail("Expected a backed-out workflow execution")
        }
        XCTAssertTrue(outcome is CheckpointPaywallOutcome.Dismissed)
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
            presentation.delegate.checkpointPresentationFinished(.completed(CheckpointPaywallOutcome.Dismissed.shared))
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
        presentation.delegate.checkpointPresentationFinished(.completed(CheckpointPaywallOutcome.Dismissed.shared))
        _ = try await firstExecution.value
    }

    func testExecutionCanRestartAfterPresentationFinishes() async throws {
        let presenter = MockCheckpointPresenter()
        presenter.onPresent = { presentation in
            presentation.delegate.checkpointPresentationFinished(.completed(CheckpointPaywallOutcome.Dismissed.shared))
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
            presentation.delegate.checkpointPresentationFinished(.completed(CheckpointPaywallOutcome.Dismissed.shared))
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
        let expectedOutcome = CheckpointPaywallOutcome.Error(error: expectedError)
        var execution: Task<CheckpointExecutionResult<CheckpointPaywallOutcome>, Error>?
        presenter.onPresent = { presentation in
            execution?.cancel()
            presentation.delegate.checkpointPresentationFinished(.completed(expectedOutcome))
        }
        let executor = CheckpointWorkflowExecutor { presenter }

        execution = Task { try await executor.execute(Self.presentation()) }
        let outcome = try await XCTUnwrap(execution).value.value

        guard let errorOutcome = outcome as? CheckpointPaywallOutcome.Error else {
            return XCTFail("Expected the completed presentation outcome")
        }
        XCTAssertEqual(errorOutcome.error, expectedError)
        XCTAssertEqual(presenter.dismissCallCount, 0)
    }

    func testPresentationCompletionWithoutPendingExecutionIsIgnored() {
        let presenter = MockCheckpointPresenter()
        let executor = CheckpointWorkflowExecutor { presenter }

        executor.checkpointPresentationFinished(.completed(CheckpointPaywallOutcome.Dismissed.shared))

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
            offerings: .preview(offerings: [offering])
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockCheckpointWorkflowExecutor: CheckpointExecutor {

    var execution: CheckpointExecutionResult<CheckpointPaywallOutcome> = .completed(
        CheckpointPaywallOutcome.Dismissed.shared
    )
    var error: Error?
    private(set) var presentations: [CheckpointPresentation] = []

    func execute(
        _ presentation: CheckpointPresentation
    ) async throws -> CheckpointExecutionResult<CheckpointPaywallOutcome> {
        self.presentations.append(presentation)
        if let error {
            throw error
        }
        return self.execution
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockPaywallPresenter: PaywallPresenter {

    private(set) var callCount = 0
    private(set) var receivedParams: PaywallPresentationParams?

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        self.callCount += 1
        self.receivedParams = params
        completion(.closed)
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
