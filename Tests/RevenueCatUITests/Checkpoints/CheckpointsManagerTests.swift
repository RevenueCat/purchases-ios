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
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(customerInfo: nil)
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

        guard case .completed(nil) = execution else {
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
        let executor = MockWorkflowPresenter()
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
        let executor = MockWorkflowPresenter()
        executor.execution = .backedOut
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
        let executor = MockWorkflowPresenter()
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
        let executor = MockWorkflowPresenter()
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
        let executor = MockWorkflowPresenter()
        executor.execution = .failed
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
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(
            customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
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
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(
            customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
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
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(
            customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
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
        let executor = MockWorkflowPresenter()
        executor.execution = .backedOut
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case .backedOut = execution else {
            return XCTFail("Expected a backed-out dismissed presentation")
        }
    }

    func testRunCheckpointReportsBackOutWithoutAnErrorPayload() async throws {
        let executor = MockWorkflowPresenter()
        executor.execution = .backedOut
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let execution = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        guard case .backedOut = execution else {
            return XCTFail("Expected a backed-out outcome")
        }
    }

    func testRunCheckpointDoesNotMarkNormalDismissalAsBackedOut() async throws {
        let executor = MockWorkflowPresenter()
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
        let executor = MockWorkflowPresenter()
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
                completion(.continued)
            })
        )

        guard case .completed = execution else {
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
            workflowPresenter: MockWorkflowPresenter()
        )
        manager.paywallPresenter = global
        var localCallCount = 0

        _ = try await manager.executeCheckpoint(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in
                localCallCount += 1
                completion(.continued)
            })
        )

        XCTAssertEqual(localCallCount, 1)
        XCTAssertEqual(global.callCount, 0)
    }

    func testResolvedOfferingUsesGlobalPaywallPresenter() async throws {
        let global = MockPaywallPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockWorkflowPresenter()
        )
        manager.paywallPresenter = global

        _ = try await manager.executeCheckpoint(identifier: "onboarding", params: .init())

        XCTAssertEqual(global.callCount, 1)
        XCTAssertEqual(global.receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(global.receivedParams?.offering.identifier, "offering-id")
    }

    func testResolvedAdWithoutARegisteredPresenterPresentsNothing() async throws {
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedAd(Self.adStep()) },
            workflowPresenter: MockWorkflowPresenter()
        )

        let execution = try await manager.executeCheckpoint(identifier: "onboarding", params: .init())

        guard case .nothingPresented = execution else {
            return XCTFail("Expected nothing to be presented")
        }
        self.logger.verifyMessageWasLogged(
            Strings.checkpoint_ad_step_without_ad_presenter(checkpointIdentifier: "onboarding"),
            level: .warn
        )
    }

    func testResolvedAdUsesRegisteredAdPresenter() async throws {
        let presenter = MockAdPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedAd(Self.adStep()) },
            workflowPresenter: MockWorkflowPresenter()
        )
        manager.adPresenter = presenter

        let execution = try await manager.executeCheckpoint(
            identifier: "onboarding",
            params: .init(customVariables: ["source": "test"])
        )

        guard case let .adPresented(outcome) = execution else {
            return XCTFail("Expected a presented-ad execution")
        }
        XCTAssertTrue(outcome is CheckpointAdOutcome.Shown)
        XCTAssertEqual(presenter.callCount, 1)
        XCTAssertEqual(presenter.receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(presenter.receivedParams?.customVariables, ["source": "test"])
        XCTAssertEqual(presenter.receivedParams?.adUnitId, "ad-unit-id")
        XCTAssertEqual(presenter.receivedParams?.mediator, MediatorName(rawValue: "admob"))
        XCTAssertEqual(presenter.receivedParams?.adFormat, .interstitial)
    }

    func testSequentialAdCheckpointsOfDifferentFormatsEachPresentAfterThePreviousCompletes() async throws {
        // Each checkpoint resolves to a different ad step; the presenter reports a format-appropriate outcome
        // only after an async hop, so a stale presentation slot would surface as operationAlreadyInProgress.
        let steps: [String: ResolvedAdStep] = [
            "level_complete": Self.adStep(adUnitId: "interstitial-unit", adFormat: .interstitial),
            "extra_life": Self.adStep(adUnitId: "rewarded-unit", adFormat: .rewarded),
            "next_level": Self.adStep(adUnitId: "interstitial-unit-2", adFormat: .interstitial)
        ]
        let presenter = FormatAwareAdPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { identifier, _ in .matchedAd(try XCTUnwrap(steps[identifier])) },
            workflowPresenter: MockWorkflowPresenter()
        )
        manager.adPresenter = presenter

        let first = try await manager.executeCheckpoint(identifier: "level_complete", params: .init())
        let second = try await manager.executeCheckpoint(identifier: "extra_life", params: .init())
        let third = try await manager.executeCheckpoint(identifier: "next_level", params: .init())

        XCTAssertTrue(Self.adOutcome(first) is CheckpointAdOutcome.Shown)
        XCTAssertTrue(Self.adOutcome(second) is CheckpointAdOutcome.Rewarded)
        XCTAssertTrue(Self.adOutcome(third) is CheckpointAdOutcome.Shown)
        XCTAssertEqual(
            presenter.receivedParams.map(\.checkpointIdentifier),
            ["level_complete", "extra_life", "next_level"]
        )
        XCTAssertEqual(
            presenter.receivedParams.map(\.adFormat),
            [.interstitial, .rewarded, .interstitial]
        )
        XCTAssertEqual(
            presenter.receivedParams.map(\.adUnitId),
            ["interstitial-unit", "rewarded-unit", "interstitial-unit-2"]
        )
    }

    func testAdCheckpointCanFollowOneWhosePresenterFailed() async throws {
        let presenter = FormatAwareAdPresenter()
        presenter.failNextPresentation = NSError(domain: "gma", code: 3)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedAd(Self.adStep()) },
            workflowPresenter: MockWorkflowPresenter()
        )
        manager.adPresenter = presenter

        let failed = try await manager.executeCheckpoint(identifier: "level_complete", params: .init())
        let shown = try await manager.executeCheckpoint(identifier: "next_level", params: .init())

        XCTAssertTrue(Self.adOutcome(failed) is CheckpointAdOutcome.Failed)
        XCTAssertTrue(Self.adOutcome(shown) is CheckpointAdOutcome.Shown)
        XCTAssertEqual(presenter.receivedParams.count, 2)
    }

    func testAdPresenterIsCapturedBeforeCheckpointResolution() async throws {
        let resolutionStarted = self.expectation(description: "Checkpoint resolution starts")
        var resolutionContinuation: CheckedContinuation<CheckpointResolution, Never>?
        let initialPresenter = MockAdPresenter()
        let replacementPresenter = MockAdPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in
                await withCheckedContinuation { continuation in
                    resolutionContinuation = continuation
                    resolutionStarted.fulfill()
                }
            }
        )
        manager.adPresenter = initialPresenter

        let checkpoint = Task {
            try await manager.executeCheckpoint(identifier: "onboarding", params: .init())
        }
        await self.fulfillment(of: [resolutionStarted], timeout: 1)
        manager.adPresenter = replacementPresenter
        resolutionContinuation?.resume(returning: .matchedAd(Self.adStep()))
        _ = try await checkpoint.value

        XCTAssertEqual(initialPresenter.callCount, 1)
        XCTAssertEqual(replacementPresenter.callCount, 0)
    }

    func testGlobalPaywallPresenterIsCapturedBeforeCheckpointResolution() async throws {
        let resolutionStarted = self.expectation(description: "Checkpoint resolution starts")
        var resolutionContinuation: CheckedContinuation<CheckpointResolution, Never>?
        let initialPresenter = MockPaywallPresenter()
        let replacementPresenter = MockPaywallPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in
                await withCheckedContinuation { continuation in
                    resolutionContinuation = continuation
                    resolutionStarted.fulfill()
                }
            }
        )
        manager.paywallPresenter = initialPresenter

        let checkpoint = Task {
            try await manager.executeCheckpoint(identifier: "onboarding", params: .init())
        }
        await self.fulfillment(of: [resolutionStarted], timeout: 1)
        manager.paywallPresenter = replacementPresenter
        resolutionContinuation?.resume(returning: .matchedOffering(Self.offering()))
        _ = try await checkpoint.value

        XCTAssertEqual(initialPresenter.callCount, 1)
        XCTAssertEqual(replacementPresenter.callCount, 0)
    }

    func testResolvedOfferingUsesDefaultPaywallPresenterWithoutAnOverride() async throws {
        let defaultPresenter = MockDefaultPaywallPresenter(result: .closed)
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockWorkflowPresenter(),
            defaultPaywallPresenter: defaultPresenter,
            customerInfoSynchronizer: {
                customerInfoSynchronizerCallCount += 1
                return try Self.customerInfo(activeEntitlements: [])
            }
        )

        let execution = try await manager.executeCheckpoint(identifier: "onboarding", params: .init())

        guard case .completed = execution else {
            return XCTFail("Expected the default presenter to use the shared completion path")
        }
        XCTAssertEqual(defaultPresenter.receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(defaultPresenter.receivedParams?.offering.identifier, "offering-id")
        XCTAssertEqual(customerInfoSynchronizerCallCount, 1)
    }

    func testDefaultOfferingPurchaseOrRestoreUsesTheCachedEntitlementBaseline() async throws {
        let terminalCustomerInfo = try Self.customerInfo(activeEntitlements: ["premium", "pro"])
        let defaultPresenter = MockDefaultPaywallPresenter(result: .continued)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockWorkflowPresenter(),
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
            workflowPresenter: MockWorkflowPresenter(),
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
            workflowPresenter: MockWorkflowPresenter(),
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
            workflowPresenter: MockWorkflowPresenter(),
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
            params: .init(paywallPresenter: { _, completion in completion(.continued) })
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
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoSynchronizer: { throw expectedError }
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.continued) })
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
            workflowPresenter: MockWorkflowPresenter(),
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

        presenterCompletion?(.continued)
        await self.fulfillment(of: [synchronizationStarted], timeout: 1)
        presenterCompletion?(.continued)
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

    func testStalePresenterCompletionCannotReleaseReplacementPresentation() async throws {
        let firstStarted = self.expectation(description: "First custom presentation starts")
        let replacementStarted = self.expectation(description: "Replacement custom presentation starts")
        var firstCompletion: PaywallPresentationCompletion?
        var replacementCompletion: PaywallPresentationCompletion?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoSynchronizer: { try Self.customerInfo(activeEntitlements: []) }
        )

        let first = Task {
            try await manager.executeCheckpoint(
                identifier: "onboarding",
                params: .init(paywallPresenter: { _, completion in
                    firstCompletion = completion
                    firstStarted.fulfill()
                })
            )
        }
        await self.fulfillment(of: [firstStarted], timeout: 1)
        firstCompletion?(.continued)
        _ = try await first.value

        let replacement = Task {
            try await manager.executeCheckpoint(
                identifier: "onboarding",
                params: .init(paywallPresenter: { _, completion in
                    replacementCompletion = completion
                    replacementStarted.fulfill()
                })
            )
        }
        await self.fulfillment(of: [replacementStarted], timeout: 1)

        firstCompletion?(.navigatedBack)

        do {
            _ = try await manager.executeCheckpoint(
                identifier: "onboarding",
                params: .init(paywallPresenter: { _, completion in completion(.navigatedBack) })
            )
            XCTFail("Expected the replacement presentation to keep owning the slot")
        } catch {
            XCTAssertEqual((error as NSError).code, ErrorCode.operationAlreadyInProgressForProductError.rawValue)
        }

        replacementCompletion?(.navigatedBack)
        guard case .backedOut = try await replacement.value else {
            return XCTFail("Expected the replacement presentation to back out")
        }
    }

    func testPresenterCompletionReleasesPresentationSlotBeforeSynchronizationCompletes() async throws {
        let presentationStarted = self.expectation(description: "Custom presentation starts")
        let synchronizationStarted = self.expectation(description: "Customer info synchronization starts")
        var presenterCompletion: PaywallPresentationCompletion?
        var synchronizationContinuation: CheckedContinuation<CustomerInfo, Error>?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering()) },
            workflowPresenter: MockWorkflowPresenter(),
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
        presenterCompletion?(.continued)
        await self.fulfillment(of: [synchronizationStarted], timeout: 1)

        let secondResult: Result<CheckpointPresentationOutcome, Error>
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
        let executor = MockWorkflowPresenter()
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

    private static func adStep(
        adUnitId: String = "ad-unit-id",
        adFormat: AdFormat = .interstitial
    ) -> ResolvedAdStep {
        return ResolvedAdStep(adUnitId: adUnitId, mediator: MediatorName(rawValue: "admob"), adFormat: adFormat)
    }

    private static func adOutcome(_ execution: CheckpointPresentationOutcome) -> CheckpointAdOutcome? {
        guard case let .adPresented(outcome) = execution else { return nil }
        return outcome
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
private extension CheckpointsManager {

    convenience init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        workflowPresenter: WorkflowPresenterType,
        defaultPaywallPresenter: PaywallPresenter? = nil,
        cachedCustomerInfoProvider: @escaping @MainActor () -> CustomerInfo? = { nil },
        customerInfoSynchronizer: @escaping CustomerInfoSynchronizer = { throw CancellationError() }
    ) {
        let checkpointPresenter: CheckpointPresenter
        if let defaultPaywallPresenter {
            checkpointPresenter = CheckpointPresenter(
                workflowPresenter: workflowPresenter,
                defaultPaywallPresenter: defaultPaywallPresenter,
                customerInfoSynchronizer: customerInfoSynchronizer
            )
        } else {
            checkpointPresenter = CheckpointPresenter(
                workflowPresenter: workflowPresenter,
                customerInfoSynchronizer: customerInfoSynchronizer
            )
        }
        self.init(
            resolveCheckpoint: resolveCheckpoint,
            checkpointPresenter: checkpointPresenter,
            cachedCustomerInfoProvider: cachedCustomerInfoProvider
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockWorkflowPresenter: WorkflowPresenterType {

    var execution: CheckpointPresentationOutcome = .completed(customerInfo: nil)
    var error: Error?
    private(set) var presentations: [WorkflowPresentationRequest] = []

    func present(
        _ presentation: WorkflowPresentationRequest
    ) async throws -> CheckpointPresentationOutcome {
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
        completion(.continued)
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockAdPresenter: AdPresenter {

    private(set) var callCount = 0
    private(set) var receivedParams: AdPresentationParams?

    func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    ) {
        self.callCount += 1
        self.receivedParams = params
        completion(.shown)
    }

}

/// Completes asynchronously with an outcome that matches the requested ad format, like a real presenter would.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class FormatAwareAdPresenter: AdPresenter {

    private(set) var receivedParams: [AdPresentationParams] = []
    var failNextPresentation: NSError?

    func present(
        params: AdPresentationParams,
        completion: @escaping AdPresentationCompletion
    ) {
        self.receivedParams.append(params)
        let error = self.failNextPresentation
        self.failNextPresentation = nil

        Task { @MainActor in
            await Task.yield()
            if let error {
                completion(.failed(error: error))
            } else if params.adFormat == .rewarded || params.adFormat == .rewardedInterstitial {
                completion(.rewarded(reward: .noReward))
            } else {
                completion(.shown)
            }
        }
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockDefaultPaywallPresenter: PaywallPresenter {

    let result: PaywallPresentationResult?
    var onPresent: (() -> Void)?
    private(set) var receivedParams: PaywallPresentationParams?

    init(result: PaywallPresentationResult?) {
        self.result = result
    }

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        self.receivedParams = params
        self.onPresent?()
        if let result {
            completion(result)
        }
    }
}
