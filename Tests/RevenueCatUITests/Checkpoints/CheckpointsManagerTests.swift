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

    func testNoActionDoesNotPresentAnything() async throws {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }

        let execution = try await manager.executeCheckpoint(
            identifier: "unknown_checkpoint",
            params: CheckpointCallParams(customVariables: ["name": "Rick"])
        )

        guard case .nothingPresented = execution else {
            return XCTFail("Expected nothing to be presented")
        }
    }

    func testInvalidCustomVariableKeysDoNotReachResolution() async throws {
        var resolvedParams: CheckpointCallParams?
        let manager = CheckpointsManager { _, params in
            resolvedParams = params
            return .noAction(.noMatch)
        }

        _ = try await manager.executeCheckpoint(
            identifier: "test",
            params: CheckpointCallParams(customVariables: [
                "valid_key": "value",
                "invalid-key": "value"
            ])
        )

        XCTAssertEqual(resolvedParams?.customVariables, ["valid_key": "value"])
    }

    func testResolvedWorkflowProducesDismissedExecution() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        executor.execution = .completed(CheckpointFlowOutcome.dismissed)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let customVariables: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true,
            "invalid-key": "not forwarded"
        ]
        let execution = try await manager.executeCheckpoint(
            identifier: "soft_paywall",
            params: .init(customVariables: customVariables)
        )

        guard case .completed(.dismissed) = execution else {
            return XCTFail("Expected a dismissed presentation")
        }
        XCTAssertEqual(executor.presentations.map(\.workflow.workflow.id), ["workflow-id"])
        XCTAssertEqual(executor.presentations.first?.customVariables, [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ])
    }

    func testCallbackCheckpointReturnsCompletedResultAfterWorkflowDismissal() async {
        let executor = MockCheckpointWorkflowPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements, [])
    }

    func testCallbackCheckpointIsSuppressedWhenWorkflowBacksOut() async {
        let executor = MockCheckpointWorkflowPresenter()
        executor.execution = .backedOut(CheckpointFlowOutcome.dismissed)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
    }

    func testCallbackCheckpointIsSuppressedWhenAnotherFlowIsBeingPresented() async {
        let executor = MockCheckpointWorkflowPresenter()
        executor.error = CheckpointError.operationAlreadyInProgress
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
    }

    func testUnmatchedCallbackCheckpointStillCompletesWhileAnotherFlowIsBeingPresented() async {
        let executor = MockCheckpointWorkflowPresenter()
        executor.error = CheckpointError.operationAlreadyInProgress
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .noAction(.noMatch) },
            workflowPresenter: executor
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
        let executor = MockCheckpointWorkflowPresenter()
        executor.execution = .completed(
            CheckpointFlowOutcome.error(NSError(domain: "test", code: 1))
        )
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertNil(flowResult)
    }

    func testCallbackCheckpointOnlyReturnsEntitlementsAbsentFromCachedCustomerInfo() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        executor.execution = .completed(
            CheckpointFlowOutcome.purchased(
                transaction: nil,
                customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
            )
        )
        var resolutionStarted = false
        var cachedCustomerInfoCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in
                resolutionStarted = true
                return .matchedWorkflow(Self.workflow())
            },
            workflowPresenter: executor,
            cachedCustomerInfoProvider: {
                XCTAssertFalse(resolutionStarted)
                cachedCustomerInfoCallCount += 1
                return try? Self.customerInfo(activeEntitlements: ["pro"])
            }
        )

        let result = await manager.checkpointForCallback(identifier: "purchase", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
        XCTAssertEqual(cachedCustomerInfoCallCount, 1)
    }

    func testCallbackCheckpointReturnsNoEntitlementsWhenAllWereAlreadyCached() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        executor.execution = .completed(
            CheckpointFlowOutcome.purchased(
                transaction: nil,
                customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
            )
        )
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor,
            cachedCustomerInfoProvider: {
                try? Self.customerInfo(activeEntitlements: ["premium", "pro"])
            }
        )

        let result = await manager.checkpointForCallback(identifier: "purchase", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements, [])
    }

    func testCallbackCheckpointTreatsAllEntitlementsAsObtainedWithoutCachedCustomerInfo() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        executor.execution = .completed(
            CheckpointFlowOutcome.restored(
                customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
            )
        )
        var cachedCustomerInfoCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor,
            cachedCustomerInfoProvider: {
                cachedCustomerInfoCallCount += 1
                return nil
            }
        )

        let result = await manager.checkpointForCallback(identifier: "restore", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(
            flowResult?.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted(),
            ["premium", "pro"]
        )
        XCTAssertEqual(cachedCustomerInfoCallCount, 1)
    }

    func testRunCheckpointRecordsBackOutWithoutChangingDismissedOutcome() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        executor.execution = .backedOut(CheckpointFlowOutcome.dismissed)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case .backedOut(.dismissed) = execution else {
            return XCTFail("Expected a backed-out dismissed presentation")
        }
    }

    func testRunCheckpointKeepsErrorOutcomeWhenBackedOut() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        let error = NSError(domain: "test", code: 42)
        executor.execution = .backedOut(CheckpointFlowOutcome.error(error))
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case let .backedOut(.error(outcomeError)) = execution else {
            return XCTFail("Expected an error outcome")
        }
        XCTAssertEqual(outcomeError, error)
    }

    func testRunCheckpointDoesNotMarkNormalDismissalAsBackedOut() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case .completed = execution else {
            return XCTFail("Expected a completed checkpoint execution")
        }
    }

    func testResolvedOfferingUsesCallSitePaywallPresenter() async throws {
        let executor = MockCheckpointWorkflowPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: executor,
            customerInfoSynchronizer: { try Self.customerInfo(activeEntitlements: []) }
        )
        var receivedParams: PaywallPresentationParams?
        let execution = try await manager.executeCheckpoint(
            identifier: "onboarding",
            params: .init(customVariables: ["source": "test"], paywallPresenter: { params, completion in
                receivedParams = params
                completion(.continue)
            })
        )

        guard case .completed(.finished) = execution else {
            return XCTFail("Expected a completed custom presentation")
        }
        XCTAssertEqual(receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(receivedParams?.customVariables, ["source": "test"])
        XCTAssertEqual(receivedParams?.offering.identifier, "offering-id")
        XCTAssertTrue(executor.presentations.isEmpty)
    }

    func testCallSitePaywallPresenterOverridesGlobalPresenter() async throws {
        let global = MockPaywallPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter()
        )
        manager.paywallPresenter = global
        var localCallCount = 0

        _ = try await manager.executeCheckpoint(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in
                localCallCount += 1
                completion(.continue)
            })
        )

        XCTAssertEqual(localCallCount, 1)
        XCTAssertEqual(global.callCount, 0)
    }

    func testResolvedOfferingUsesGlobalPaywallPresenter() async throws {
        let global = MockPaywallPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter()
        )
        manager.paywallPresenter = global

        _ = try await manager.executeCheckpoint(identifier: "onboarding", params: .init())

        XCTAssertEqual(global.callCount, 1)
        XCTAssertEqual(global.receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(global.receivedParams?.offering.identifier, "offering-id")
    }

    func testResolvedOfferingUsesDefaultPaywallPresenterWithoutAnOverride() async throws {
        let defaultPresenter = MockDefaultPaywallPresenter(result: .closed)
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            defaultPaywallPresenter: defaultPresenter,
            customerInfoSynchronizer: {
                customerInfoSynchronizerCallCount += 1
                return try Self.customerInfo(activeEntitlements: [])
            }
        )

        let execution = try await manager.executeCheckpoint(identifier: "onboarding", params: .init())

        guard case .completed(.finished) = execution else {
            return XCTFail("Expected the default presenter to use the shared completion path")
        }
        XCTAssertEqual(defaultPresenter.receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(defaultPresenter.receivedParams?.offering.identifier, "offering-id")
        XCTAssertEqual(customerInfoSynchronizerCallCount, 1)
    }

    func testDefaultOfferingPurchaseOrRestoreUsesTheCachedEntitlementBaseline() async throws {
        let terminalCustomerInfo = try Self.customerInfo(activeEntitlements: ["premium", "pro"])
        let defaultPresenter = MockDefaultPaywallPresenter(result: .continue)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            defaultPaywallPresenter: defaultPresenter,
            cachedCustomerInfoProvider: { try? Self.customerInfo(activeEntitlements: ["pro"]) },
            customerInfoSynchronizer: { terminalCustomerInfo }
        )

        let result = await manager.checkpointForCallback(identifier: "restore", params: .init())

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
    }

    func testDefaultPaywallPresenterNavigatedBackSuppressesCheckpointCallback() async {
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            defaultPaywallPresenter: MockDefaultPaywallPresenter(result: .navigatedBack),
            customerInfoSynchronizer: {
                customerInfoSynchronizerCallCount += 1
                return try Self.customerInfo(activeEntitlements: [])
            }
        )

        let result = await manager.checkpointForCallback(identifier: "onboarding", params: .init())

        guard case .suppressed = result else {
            return XCTFail("Expected a backed-out default presentation to suppress the callback")
        }
        XCTAssertEqual(customerInfoSynchronizerCallCount, 0)
    }

    func testNavigatedBackSuppressesCheckpointCallback() async {
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            customerInfoSynchronizer: {
                customerInfoSynchronizerCallCount += 1
                return try Self.customerInfo(activeEntitlements: ["premium"])
            }
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.navigatedBack) })
        )

        guard case .suppressed = result else {
            return XCTFail("Expected a backed-out presentation to suppress the callback")
        }
        XCTAssertEqual(customerInfoSynchronizerCallCount, 0)
    }

    func testContinueSynchronizesCustomerInfoAndReturnsNewEntitlements() async throws {
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            cachedCustomerInfoProvider: {
                try? Self.customerInfo(activeEntitlements: ["pro"])
            },
            customerInfoSynchronizer: {
                customerInfoSynchronizerCallCount += 1
                return try Self.customerInfo(activeEntitlements: ["premium", "pro"])
            }
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.continue) })
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
        XCTAssertEqual(customerInfoSynchronizerCallCount, 1)
    }

    func testCustomerInfoSynchronizationFailureReturnsNil() async {
        let expectedError = NSError(domain: "test", code: 42)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            customerInfoSynchronizer: { throw expectedError }
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.continue) })
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertNil(flowResult)
    }

    func testOnlyFirstPresenterCompletionSynchronizesCustomerInfo() async throws {
        let presentationStarted = self.expectation(description: "Custom presentation starts")
        let synchronizationStarted = self.expectation(description: "Customer info synchronization starts")
        var presenterCompletion: PaywallPresentationCompletion?
        var synchronizationContinuation: CheckedContinuation<CustomerInfo, Error>?
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            customerInfoSynchronizer: {
                customerInfoSynchronizerCallCount += 1
                synchronizationStarted.fulfill()
                return try await withCheckedThrowingContinuation { continuation in
                    synchronizationContinuation = continuation
                }
            }
        )

        let checkpoint = Task {
            await manager.checkpointForCallback(
                identifier: "onboarding",
                params: .init(paywallPresenter: { _, completion in
                    presenterCompletion = completion
                    presentationStarted.fulfill()
                })
            )
        }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        presenterCompletion?(.continue)
        await self.fulfillment(of: [synchronizationStarted], timeout: 1)
        presenterCompletion?(.continue)
        presenterCompletion?(.navigatedBack)

        XCTAssertEqual(customerInfoSynchronizerCallCount, 1)
        synchronizationContinuation?.resume(
            returning: try Self.customerInfo(activeEntitlements: ["premium"])
        )

        guard case let .completed(flowResult) = await checkpoint.value else {
            return XCTFail("Expected the first completion to finish the checkpoint")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
    }

    func testPresenterCompletionReleasesPresentationSlotBeforeSynchronizationCompletes() async throws {
        let presentationStarted = self.expectation(description: "Custom presentation starts")
        let synchronizationStarted = self.expectation(description: "Customer info synchronization starts")
        var presenterCompletion: PaywallPresentationCompletion?
        var synchronizationContinuation: CheckedContinuation<CustomerInfo, Error>?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            customerInfoSynchronizer: {
                synchronizationStarted.fulfill()
                return try await withCheckedThrowingContinuation { continuation in
                    synchronizationContinuation = continuation
                }
            }
        )

        let firstCheckpoint = Task {
            try await manager.executeCheckpoint(
                identifier: "onboarding",
                params: .init(paywallPresenter: { _, completion in
                    presenterCompletion = completion
                    presentationStarted.fulfill()
                })
            )
        }
        await self.fulfillment(of: [presentationStarted], timeout: 1)
        presenterCompletion?(.continue)
        await self.fulfillment(of: [synchronizationStarted], timeout: 1)

        let secondResult: Result<CheckpointExecution, Error>
        do {
            secondResult = .success(try await manager.executeCheckpoint(
                identifier: "onboarding",
                params: .init(paywallPresenter: { _, completion in completion(.navigatedBack) })
            ))
        } catch {
            secondResult = .failure(error)
        }

        synchronizationContinuation?.resume(
            returning: try Self.customerInfo(activeEntitlements: ["premium"])
        )
        _ = try await firstCheckpoint.value

        guard case .success(.backedOut) = secondResult else {
            return XCTFail("Expected another checkpoint to present while customer information synchronizes")
        }
    }

    func testCancellationDuringSynchronizationIgnoresLateResultAndReleasesPresentationSlot() async throws {
        let presentationStarted = self.expectation(description: "Custom presentation starts")
        let synchronizationStarted = self.expectation(description: "Customer info synchronization starts")
        let lateSynchronizationFinished = self.expectation(description: "Late synchronization finishes")
        var presenterCompletion: PaywallPresentationCompletion?
        var synchronizationContinuation: CheckedContinuation<CustomerInfo, Error>?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockCheckpointWorkflowPresenter(),
            customerInfoSynchronizer: {
                let customerInfo = try await withCheckedThrowingContinuation { continuation in
                    synchronizationContinuation = continuation
                    synchronizationStarted.fulfill()
                }
                lateSynchronizationFinished.fulfill()
                return customerInfo
            }
        )

        let firstCheckpoint = Task {
            try await manager.executeCheckpoint(
                identifier: "onboarding",
                params: .init(paywallPresenter: { _, completion in
                    presenterCompletion = completion
                    presentationStarted.fulfill()
                })
            )
        }
        await self.fulfillment(of: [presentationStarted], timeout: 1)
        presenterCompletion?(.continue)
        await self.fulfillment(of: [synchronizationStarted], timeout: 1)

        firstCheckpoint.cancel()
        do {
            _ = try await firstCheckpoint.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        }

        let secondExecution = try await manager.executeCheckpoint(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.navigatedBack) })
        )
        guard case .backedOut = secondExecution else {
            return XCTFail("Expected a new presentation after cancellation")
        }

        synchronizationContinuation?.resume(
            returning: try Self.customerInfo(activeEntitlements: ["premium"])
        )
        await self.fulfillment(of: [lateSynchronizationFinished], timeout: 1)
    }

    func testResolutionErrorIsForwarded() async {
        let expectedError = NSError(domain: "test", code: 42)
        let manager = CheckpointsManager { _, _ in throw expectedError }

        do {
            _ = try await manager.executeCheckpoint(identifier: "error_checkpoint", params: .init())
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

    }

    func testPresentationErrorIsForwardedWithoutPresentedResult() async {
        let expectedError = NSError(domain: "test", code: 42)
        let executor = MockCheckpointWorkflowPresenter()
        executor.error = expectedError
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )
        do {
            _ = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

    }

    func testValidCheckpointIdentifierReachesResolution() async throws {
        var resolvedIdentifiers: [String] = []
        let manager = CheckpointsManager { identifier, _ in
            resolvedIdentifiers.append(identifier)
            return .noAction(.noMatch)
        }
        _ = try await manager.executeCheckpoint(identifier: "A-1_b", params: .init())

        XCTAssertEqual(resolvedIdentifiers, ["A-1_b"])
    }

    func testInvalidCheckpointIdentifierIsLoggedWithoutResolution() async throws {
        let invalidIdentifier = " checkout😀"
        var resolutionCount = 0
        let manager = CheckpointsManager { _, _ in
            resolutionCount += 1
            return .noAction(.noMatch)
        }
        let execution = try await manager.executeCheckpoint(identifier: invalidIdentifier, params: .init())

        guard case .nothingPresented = execution else {
            return XCTFail("Expected nothing to be presented")
        }

        XCTAssertEqual(resolutionCount, 0)
        self.logger.verifyMessageWasLogged(
            CheckpointIdentifierValidator.invalidIdentifierLogMessage(invalidIdentifier),
            level: .error
        )
    }

    private static func offering() -> Offering {
        return Offering(
            identifier: "offering-id",
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

    private static func customerInfo(activeEntitlements: [String]) throws -> CustomerInfo {
        let infos = Dictionary(uniqueKeysWithValues: activeEntitlements.map { identifier in
            (
                identifier,
                EntitlementInfo(
                    identifier: identifier,
                    isActive: true,
                    willRenew: true,
                    periodType: .normal,
                    latestPurchaseDate: Date(timeIntervalSince1970: 0),
                    expirationDate: Date(timeIntervalSince1970: 4_102_444_800),
                    store: .appStore,
                    productIdentifier: "\(identifier)-product",
                    isSandbox: true,
                    ownershipType: .purchased
                )
            )
        })

        return CustomerInfo(
            entitlements: EntitlementInfos(entitlements: infos),
            requestDate: Date(timeIntervalSince1970: 0),
            firstSeen: Date(timeIntervalSince1970: 0),
            originalAppUserId: "test-user"
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
final class CheckpointWorkflowExecutionTests: TestCase {

    func testCustomVariablesAreForwardedToThePresenter() async throws {
        let expected: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ]
        let presenter = CheckpointWorkflowPresenterHarness()
        presenter.onPresent = { presentation in
            presentation.finish(.completed(CheckpointFlowOutcome.dismissed))
        }
        let workflowPresenter = presenter.workflowPresenter

        _ = try await workflowPresenter.present(Self.presentation(customVariables: expected))

        XCTAssertEqual(
            presenter.presentations.first?.checkpointPresentation.customVariables,
            expected
        )
    }

    func testExecutionForwardsBackOutFromThePresenter() async throws {
        let presenter = CheckpointWorkflowPresenterHarness()
        presenter.onPresent = { presentation in
            presentation.finish(.backedOut(CheckpointFlowOutcome.dismissed))
        }
        let workflowPresenter = presenter.workflowPresenter

        let execution = try await workflowPresenter.present(Self.presentation())

        guard case .backedOut(.dismissed) = execution else {
            return XCTFail("Expected a backed-out workflow execution")
        }
    }

    func testPresentationFailureResumesExecutionAndAllowsRetry() async throws {
        let presenter = CheckpointWorkflowPresenterHarness()
        let expectedError = NSError(domain: "test", code: 42)
        presenter.presentationError = expectedError
        let workflowPresenter = presenter.workflowPresenter

        do {
            _ = try await workflowPresenter.present(Self.presentation())
            XCTFail("Expected presentation failure")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

        presenter.presentationError = nil
        presenter.onPresent = { presentation in
            presentation.finish(.completed(CheckpointFlowOutcome.dismissed))
        }
        _ = try await workflowPresenter.present(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 1)
    }

    func testConcurrentExecutionFailsWhilePresentationIsActive() async throws {
        let presenter = CheckpointWorkflowPresenterHarness()
        let presentationStarted = self.expectation(description: "Presentation starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        let workflowPresenter = presenter.workflowPresenter
        let firstExecution = Task { try await workflowPresenter.present(Self.presentation()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        do {
            _ = try await workflowPresenter.present(Self.presentation())
            XCTFail("Expected concurrent execution to throw")
        } catch {
            XCTAssertEqual(
                (error as NSError).code,
                ErrorCode.operationAlreadyInProgressForProductError.rawValue
            )
        }

        let presentation = try XCTUnwrap(presenter.presentations.first)
        presentation.finish(.completed(CheckpointFlowOutcome.dismissed))
        _ = try await firstExecution.value
    }

    func testExecutionCanRestartAfterPresentationFinishes() async throws {
        let presenter = CheckpointWorkflowPresenterHarness()
        presenter.onPresent = { presentation in
            presentation.finish(.completed(CheckpointFlowOutcome.dismissed))
        }
        let workflowPresenter = presenter.workflowPresenter

        _ = try await workflowPresenter.present(Self.presentation())
        _ = try await workflowPresenter.present(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 2)
    }

    func testExecutionCanRestartAfterCancellation() async throws {
        let presenter = CheckpointWorkflowPresenterHarness()
        let presentationStarted = self.expectation(description: "Presentation starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        let workflowPresenter = presenter.workflowPresenter
        let firstExecution = Task { try await workflowPresenter.present(Self.presentation()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        firstExecution.cancel()
        do {
            _ = try await firstExecution.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        }

        presenter.onPresent = { presentation in
            presentation.finish(.completed(CheckpointFlowOutcome.dismissed))
        }
        _ = try await workflowPresenter.present(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 2)
        XCTAssertEqual(presenter.dismissCallCount, 1)
    }

    func testCancellationKeepsExecutionActiveUntilPresentationFinishesDismissing() async throws {
        let presenter = CheckpointWorkflowPresenterHarness()
        presenter.automaticallyFinishesDismissing = false
        let presentationStarted = self.expectation(description: "Presentation starts")
        let dismissalStarted = self.expectation(description: "Dismissal starts")
        presenter.onPresent = { _ in presentationStarted.fulfill() }
        presenter.onDismiss = { dismissalStarted.fulfill() }
        let workflowPresenter = presenter.workflowPresenter
        let firstExecution = Task { try await workflowPresenter.present(Self.presentation()) }
        await self.fulfillment(of: [presentationStarted], timeout: 1)

        firstExecution.cancel()
        await self.fulfillment(of: [dismissalStarted], timeout: 1)

        do {
            _ = try await workflowPresenter.present(Self.presentation())
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
        let presenter = CheckpointWorkflowPresenterHarness()
        let expectedError = NSError(domain: "test", code: 42)
        let expectedOutcome = CheckpointFlowOutcome.error(expectedError)
        var execution: Task<CheckpointExecution, Error>?
        presenter.onPresent = { presentation in
            execution?.cancel()
            presentation.finish(.completed(expectedOutcome))
        }
        let workflowPresenter = presenter.workflowPresenter

        execution = Task { try await workflowPresenter.present(Self.presentation()) }
        let result = try await XCTUnwrap(execution).value

        guard case let .completed(.error(errorOutcome)) = result else {
            return XCTFail("Expected the completed presentation outcome")
        }
        XCTAssertEqual(errorOutcome, expectedError)
        XCTAssertEqual(presenter.dismissCallCount, 0)
    }

    func testPresentationCompletionWithoutPendingExecutionIsIgnored() {
        let presenter = CheckpointWorkflowPresenterHarness()
        let workflowPresenter = presenter.workflowPresenter

        XCTAssertNil(workflowPresenter.presentationDidDismiss())

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
private final class MockCheckpointWorkflowPresenter: CheckpointWorkflowPresenterProtocol {

    var execution: CheckpointExecution = .completed(
        CheckpointFlowOutcome.dismissed
    )
    var error: Error?
    private(set) var presentations: [CheckpointPresentation] = []

    func present(
        _ presentation: CheckpointPresentation
    ) async throws -> CheckpointExecution {
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
        completion(.continue)
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockDefaultPaywallPresenter: DefaultPaywallPresenterProtocol {

    let result: PaywallPresentationResult
    private(set) var receivedParams: PaywallPresentationParams?
    private(set) var cancelCallCount = 0

    init(result: PaywallPresentationResult) {
        self.result = result
    }

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        self.receivedParams = params
        completion(self.result)
    }

    func cancel() {
        self.cancelCallCount += 1
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class CheckpointWorkflowPresenterHarness {

    struct Presentation {
        let checkpointPresentation: CheckpointPresentation
        let finish: (CheckpointExecution) -> Void
    }

    var onPresent: ((Presentation) -> Void)?
    var onDismiss: (() -> Void)?
    var automaticallyFinishesDismissing = true
    var presentationError: Error?
    private(set) var presentations: [Presentation] = []
    private(set) var dismissCallCount = 0
    private var dismissalCompletions: [() -> Void] = []

    lazy var workflowPresenter = CheckpointWorkflowPresenter(
        dismissalHandler: { [weak self] completion in
            self?.handleDismissal(completion: completion)
        },
        presentationHandler: { [weak self] presentation in
            return try self?.handlePresentation(presentation) ?? false
        }
    )

    private func handlePresentation(_ presentation: CheckpointPresentation) throws -> Bool {
        if let presentationError {
            throw presentationError
        }
        let record = Presentation(
            checkpointPresentation: presentation,
            finish: { [weak self] execution in
                self?.finish(execution)
            }
        )
        self.presentations.append(record)
        self.onPresent?(record)
        return true
    }

    private func handleDismissal(completion: @escaping () -> Void) {
        self.dismissCallCount += 1
        self.onDismiss?()
        if self.automaticallyFinishesDismissing {
            completion()
        } else {
            self.dismissalCompletions.append(completion)
        }
    }

    private func finish(_ execution: CheckpointExecution) {
        switch execution {
        case .nothingPresented:
            self.workflowPresenter.presentationDidDismiss()
        case let .completed(outcome):
            self.workflowPresenter.stage(.outcome(outcome))
            self.workflowPresenter.presentationDidDismiss(reason: .close)
        case let .backedOut(outcome):
            self.workflowPresenter.stage(.outcome(outcome))
            self.workflowPresenter.presentationDidDismiss(reason: .navigatedBack)
        }
    }

    func finishDismissing() {
        self.dismissalCompletions.removeFirst()()
    }

}
