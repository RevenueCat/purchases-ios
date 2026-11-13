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
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

// swiftlint:disable file_length type_body_length

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

    func testCheckpointCallParamsResolveDefaultPresentationModeToSheet() {
        XCTAssertEqual(CheckpointCallParams().presentationMode, .modalSheet)
        XCTAssertEqual(CheckpointCallParams(presentationMode: .default).presentationMode, .modalSheet)
        XCTAssertEqual(CheckpointCallParams(presentationMode: .modalFullScreen).presentationMode, .modalFullScreen)
    }

    func testErrorPresentationHandlerPrefersLocalPresenter() {
        let globalPresenter = MockErrorPresenter()
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        manager.errorPresenter = globalPresenter
        var localCallCount = 0
        var defaultCallCount = 0

        let handler = manager.errorPresentationHandler(
            for: .init(errorPresenter: { _, _ in localCallCount += 1 }),
            defaultHandler: {
                defaultCallCount += 1
                return { _, _ in }
            }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(localCallCount, 1)
        XCTAssertEqual(globalPresenter.callCount, 0)
        XCTAssertEqual(defaultCallCount, 0)
    }

    func testErrorPresentationHandlerUsesGlobalPresenterWithoutLocalPresenter() {
        let globalPresenter = MockErrorPresenter()
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        manager.errorPresenter = globalPresenter
        var defaultCallCount = 0

        let handler = manager.errorPresentationHandler(
            for: .init(),
            defaultHandler: {
                defaultCallCount += 1
                return { _, _ in }
            }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(globalPresenter.callCount, 1)
        XCTAssertEqual(defaultCallCount, 0)
    }

    func testErrorPresentationHandlerUsesDefaultWithoutCustomPresenter() {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        var defaultCallCount = 0

        let handler = manager.errorPresentationHandler(
            for: .init(),
            defaultHandler: {
                return { _, _ in defaultCallCount += 1 }
            }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(defaultCallCount, 1)
    }

    // Replacing the global presenter while a Flow is active affects its later errors.
    func testErrorPresentationHandlerUsesReplacementGlobalPresenterDuringActiveFlow() {
        let initialPresenter = MockErrorPresenter()
        let replacementPresenter = MockErrorPresenter()
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        manager.errorPresenter = initialPresenter
        var defaultCallCount = 0
        let handler = manager.errorPresentationHandler(
            for: .init(),
            defaultHandler: { return { _, _ in defaultCallCount += 1 } }
        )

        manager.errorPresenter = replacementPresenter
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(initialPresenter.callCount, 0)
        XCTAssertEqual(replacementPresenter.callCount, 1)
        XCTAssertEqual(defaultCallCount, 0)
    }

    // Removing the global presenter while a Flow is active falls back to the SDK presenter.
    func testErrorPresentationHandlerUsesDefaultAfterRemovingGlobalPresenterDuringActiveFlow() {
        let initialPresenter = MockErrorPresenter()
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        manager.errorPresenter = initialPresenter
        var defaultCallCount = 0
        let handler = manager.errorPresentationHandler(
            for: .init(),
            defaultHandler: { return { _, _ in defaultCallCount += 1 } }
        )

        manager.errorPresenter = nil
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(initialPresenter.callCount, 0)
        XCTAssertEqual(defaultCallCount, 1)
    }

    // A per-call presenter remains fixed when the global presenter changes.
    func testErrorPresentationHandlerKeepsLocalPresenterDuringActiveFlow() {
        let initialPresenter = MockErrorPresenter()
        let replacementPresenter = MockErrorPresenter()
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        manager.errorPresenter = initialPresenter
        var localCallCount = 0
        var defaultCallCount = 0
        let handler = manager.errorPresentationHandler(
            for: .init(errorPresenter: { _, _ in localCallCount += 1 }),
            defaultHandler: { return { _, _ in defaultCallCount += 1 } }
        )

        manager.errorPresenter = replacementPresenter
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(localCallCount, 1)
        XCTAssertEqual(initialPresenter.callCount, 0)
        XCTAssertEqual(replacementPresenter.callCount, 0)
        XCTAssertEqual(defaultCallCount, 0)
    }

    // Completing one error presentation must not re-enter the next presenter inline.
    func testErrorPresentationHandlersShareFIFOQueueAcrossCustomAndDefaultPresenters() async {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        var presentationOrder: [String] = []
        var customCompletion: ErrorPresentationCompletion?
        let defaultPresented = self.expectation(description: "Default error presented")

        let customHandler = manager.errorPresentationHandler(
            for: .init(errorPresenter: { _, completion in
                presentationOrder.append("custom")
                customCompletion = completion
            }),
            defaultHandler: { XCTFail("Expected custom presenter"); return { _, _ in } }
        )
        let defaultHandler = manager.errorPresentationHandler(
            for: .init(),
            defaultHandler: {
                return { _, _ in
                    presentationOrder.append("default")
                    defaultPresented.fulfill()
                }
            }
        )

        customHandler(Self.errorPresentationParams, Self.errorPresentationCompletion)
        defaultHandler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(presentationOrder, ["custom"])

        customCompletion?.complete()

        XCTAssertEqual(presentationOrder, ["custom"])
        await self.fulfillment(of: [defaultPresented], timeout: 1)
        XCTAssertEqual(presentationOrder, ["custom", "default"])
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
        XCTAssertEqual(executor.presentations.first?.presentationMode, .modalSheet)
    }

    func testResolvedWorkflowReceivesRequestedPresentationMode() async throws {
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(customerInfo: nil)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        _ = try await manager.executeCheckpoint(
            identifier: "soft_paywall",
            params: .init(presentationMode: .modalFullScreen)
        )

        XCTAssertEqual(executor.presentations.first?.presentationMode, .modalFullScreen)
    }

    func testResolvedWorkflowReceivesInitialActiveEntitlements() async throws {
        let executor = MockWorkflowPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor,
            customerInfoProvider: {
                try Self.customerInfo(activeEntitlements: ["premium", "pro"])
            }
        )

        _ = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())

        XCTAssertEqual(
            executor.presentations.first?.initialActiveEntitlementIdentifiers,
            ["premium", "pro"]
        )
    }

    func testCustomerInfoIsReadOnceAfterResolutionAndIsTheBaselineForPresentationAndResult() async throws {
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(
            customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
        )
        var resolutionCompleted = false
        var customerInfoReadCount = 0
        var cachedCustomerInfoReadCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in
                resolutionCompleted = true
                return .matchedWorkflow(Self.workflow())
            },
            workflowPresenter: executor,
            customerInfoProvider: {
                XCTAssertTrue(resolutionCompleted)
                XCTAssertTrue(executor.presentations.isEmpty)
                customerInfoReadCount += 1
                return try Self.customerInfo(activeEntitlements: ["pro"])
            },
            cachedCustomerInfoProvider: {
                cachedCustomerInfoReadCount += 1
                return nil
            }
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        XCTAssertEqual(customerInfoReadCount, 1)
        XCTAssertEqual(cachedCustomerInfoReadCount, 0)
        XCTAssertEqual(executor.presentations.first?.initialActiveEntitlementIdentifiers, ["pro"])
        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
    }

    func testCallbackCheckpointReturnsCompletedResultAfterWorkflowDismissal() async {
        let executor = MockWorkflowPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements, [])
    }

    func testDismissedWorkflowDeliversTheCachedCustomerInfoAndWhatItShowsAsObtained() async throws {
        let product = Self.storeProduct(identifier: "premium-product")
        let customerInfoBefore = try Self.customerInfo(activeEntitlements: ["pro"])
        let cachedCustomerInfo = try Self.customerInfo(
            activeEntitlements: ["premium", "pro"],
            purchaseDatesByProductId: ["premium-product": Date(timeIntervalSince1970: 10)]
        )
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow(products: [product])) },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { customerInfoBefore },
            cachedCustomerInfoProvider: { cachedCustomerInfo }
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.customer, cachedCustomerInfo)
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
        XCTAssertEqual(checkpointResult.flow?.obtainedProducts.map(\.product.productIdentifier), ["premium-product"])
        XCTAssertTrue(checkpointResult.hasEntitlement("premium"))
        XCTAssertTrue(checkpointResult.hasEntitlement("pro"))
    }

    func testDismissedWorkflowDeliversTheCustomerInfoReadBeforeWhenTheCacheIsEmpty() async throws {
        let customerInfoBefore = try Self.customerInfo(activeEntitlements: ["pro"])
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { customerInfoBefore },
            cachedCustomerInfoProvider: { nil }
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.customer, customerInfoBefore)
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements, [])
        XCTAssertEqual(checkpointResult.flow?.obtainedProducts, [])
        XCTAssertTrue(checkpointResult.hasEntitlement("pro"))
        XCTAssertFalse(checkpointResult.didObtainEntitlement("pro"))
    }

    func testPurchaseOutcomeCustomerInfoWinsOverTheCache() async throws {
        let purchasedCustomerInfo = try Self.customerInfo(activeEntitlements: ["premium"])
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(customerInfo: purchasedCustomerInfo)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor,
            cachedCustomerInfoProvider: { try? Self.customerInfo(activeEntitlements: ["plus"]) }
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.customer, purchasedCustomerInfo)
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
    }

    func testNoMatchDeliversTheCustomerInfoReadAfterResolution() async throws {
        let customerInfoBefore = try Self.customerInfo(activeEntitlements: ["pro"])
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .noAction(.noMatch) },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { customerInfoBefore }
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertNil(checkpointResult.flow)
        XCTAssertEqual(checkpointResult.customer, customerInfoBefore)
        XCTAssertTrue(checkpointResult.hasEntitlement("pro"))
        XCTAssertFalse(checkpointResult.didObtainEntitlement("pro"))
        XCTAssertFalse(checkpointResult.hasEntitlement("plus"))
    }

    func testHasEntitlementReadsTheDeliveredCustomerNotTheFlow() throws {
        let pro = try XCTUnwrap(Self.customerInfo(activeEntitlements: ["pro"]).entitlements.active["pro"])
        let result = CheckpointResult(
            flow: FlowResult(obtainedEntitlements: [ObtainedEntitlement(entitlementInfo: pro)], obtainedProducts: []),
            customer: try Self.customerInfo(activeEntitlements: [])
        )

        XCTAssertTrue(result.didObtainEntitlement("pro"))
        XCTAssertFalse(result.hasEntitlement("pro"))
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

    func testCallbackCheckpointIsSuppressedWithoutPresentingErrorWhenPresentationContextIsUnavailable() async {
        let workflowPresenter = MockWorkflowPresenter()
        workflowPresenter.error = CheckpointError.presentationContextUnavailable
        var errorPresentationCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: workflowPresenter
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: .init(errorPresenter: { _, completion in
                errorPresentationCount += 1
                completion.complete()
            })
        )

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
        XCTAssertEqual(errorPresentationCount, 0)
    }

    func testUnmatchedCallbackCheckpointStillCompletesWhileAnotherFlowIsBeingPresented() async {
        let executor = MockWorkflowPresenter()
        executor.error = CheckpointError.operationAlreadyInProgress
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .noAction(.noMatch) },
            workflowPresenter: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertNil(checkpointResult.flow)
        XCTAssertEqual(checkpointResult.customer, try Self.customerInfo(activeEntitlements: []))
        XCTAssertNil(checkpointResult.obtainedEntitlement("pro"))
        XCTAssertFalse(checkpointResult.didObtainEntitlement("pro"))
        XCTAssertNil(checkpointResult.obtainedProduct("pro-product"))
        XCTAssertFalse(checkpointResult.didObtainProduct("pro-product"))
        XCTAssertTrue(executor.presentations.isEmpty)
    }

    func testCallbackCheckpointIsSuppressedWhenWorkflowErrors() async {
        let executor = MockWorkflowPresenter()
        executor.execution = .failed
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case .suppressed = result else {
            return XCTFail("Expected the callback not to be invoked")
        }
    }

    func testCallbackCheckpointOnlyReturnsEntitlementsAbsentBeforeTheFlow() async throws {
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(
            customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
        )
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor,
            customerInfoProvider: { try Self.customerInfo(activeEntitlements: ["pro"]) }
        )

        let result = await manager.checkpointForCallback(identifier: "purchase", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
    }

    func testCallbackCheckpointReturnsNoEntitlementsWhenAllWereAlreadyHeld() async throws {
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(
            customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
        )
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor,
            customerInfoProvider: {
                try Self.customerInfo(activeEntitlements: ["premium", "pro"])
            }
        )

        let result = await manager.checkpointForCallback(identifier: "purchase", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements, [])
    }

    func testCallbackCheckpointIsSuppressedWhenCustomerInfoCannotBeRead() async {
        let expectedError = NSError(domain: "test", code: 7)
        let executor = MockWorkflowPresenter()
        var resolutionCount = 0
        var presentedParams: ErrorPresentationParams?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in
                resolutionCount += 1
                return .matchedWorkflow(Self.workflow())
            },
            workflowPresenter: executor,
            customerInfoProvider: { throw expectedError }
        )

        let result = await manager.checkpointForCallback(
            identifier: "restore",
            params: .init(errorPresenter: { params, completion in
                presentedParams = params
                completion.complete()
            })
        )

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
        XCTAssertEqual(resolutionCount, 1)
        XCTAssertTrue(executor.presentations.isEmpty)
        XCTAssertEqual(presentedParams?.error as NSError?, expectedError)
        XCTAssertEqual(presentedParams?.kind, .flowCouldNotBeShown)
        self.logger.verifyMessageWasLogged(
            "Checkpoint 'restore': the customer's information could not be read: " + expectedError.localizedDescription,
            level: .error
        )
    }

    func testNoMatchIsSuppressedWhenCustomerInfoCannotBeRead() async {
        let expectedError = NSError(domain: "test", code: 7)
        var presentedParams: ErrorPresentationParams?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .noAction(.noMatch) },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { throw expectedError }
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: .init(errorPresenter: { params, completion in
                presentedParams = params
                completion.complete()
            })
        )

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
        XCTAssertEqual(presentedParams?.error as NSError?, expectedError)
        XCTAssertEqual(presentedParams?.kind, .flowCouldNotBeShown)
    }

    func testUnknownCheckpointIsSuppressedWhenCustomerInfoCannotBeRead() async {
        let expectedError = NSError(domain: "test", code: 7)
        var presentedParams: ErrorPresentationParams?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .noAction(.unknownCheckpoint) },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { throw expectedError }
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: .init(errorPresenter: { params, completion in
                presentedParams = params
                completion.complete()
            })
        )

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
        XCTAssertEqual(presentedParams?.error as NSError?, expectedError)
        XCTAssertEqual(presentedParams?.kind, .flowCouldNotBeShown)
    }

    func testResolvedOfferingDoesNotReachThePaywallPresenterWhenCustomerInfoCannotBeRead() async {
        let expectedError = NSError(domain: "test", code: 7)
        var presentedParams: ErrorPresentationParams?
        var paywallPresentationCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { throw expectedError }
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(
                paywallPresenter: { _, _ in paywallPresentationCount += 1 },
                errorPresenter: { params, completion in
                    presentedParams = params
                    completion.complete()
                }
            )
        )

        guard case .suppressed = result else {
            return XCTFail("Expected the callback to be suppressed")
        }
        XCTAssertEqual(paywallPresentationCount, 0)
        XCTAssertEqual(presentedParams?.error as NSError?, expectedError)
        XCTAssertEqual(presentedParams?.kind, .flowCouldNotBeShown)
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
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
            workflowPresenter: executor,
            customerInfoSynchronizer: { try Self.customerInfo(activeEntitlements: []) }
        )
        var receivedParams: PaywallPresentationParams?
        let execution = try await manager.executeCheckpoint(
            identifier: "onboarding",
            params: .init(
                customVariables: ["source": "test"],
                presentationMode: .modalFullScreen,
                paywallPresenter: { params, completion in
                    receivedParams = params
                    completion(.continued)
                }
            )
        )

        guard case .completed = execution else {
            return XCTFail("Expected a completed custom presentation")
        }
        XCTAssertEqual(receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(receivedParams?.customVariables, ["source": "test"])
        XCTAssertEqual(receivedParams?.presentationMode, .modalFullScreen)
        XCTAssertEqual(receivedParams?.offering.identifier, "offering-id")
        XCTAssertTrue(executor.presentations.isEmpty)
    }

    func testCallSitePaywallPresenterOverridesGlobalPresenter() async throws {
        let global = MockPaywallPresenter()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
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
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
            workflowPresenter: MockWorkflowPresenter()
        )
        manager.paywallPresenter = global

        _ = try await manager.executeCheckpoint(identifier: "onboarding", params: .init())

        XCTAssertEqual(global.callCount, 1)
        XCTAssertEqual(global.receivedParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(global.receivedParams?.offering.identifier, "offering-id")
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
        resolutionContinuation?.resume(returning: .matchedOffering(Self.offering(), traceID: "trace_id"))
        _ = try await checkpoint.value

        XCTAssertEqual(initialPresenter.callCount, 1)
        XCTAssertEqual(replacementPresenter.callCount, 0)
    }

    func testResolvedOfferingUsesDefaultPaywallPresenterWithoutAnOverride() async throws {
        let defaultPresenter = MockDefaultPaywallPresenter(result: .closed)
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
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

    func testDefaultOfferingPurchaseOrRestoreUsesTheEntitlementBaselineReadBeforeTheFlow() async throws {
        let terminalCustomerInfo = try Self.customerInfo(activeEntitlements: ["premium", "pro"])
        let defaultPresenter = MockDefaultPaywallPresenter(result: .continued)
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
            workflowPresenter: MockWorkflowPresenter(),
            defaultPaywallPresenter: defaultPresenter,
            customerInfoProvider: { try Self.customerInfo(activeEntitlements: ["pro"]) },
            customerInfoSynchronizer: { terminalCustomerInfo }
        )

        let result = await manager.checkpointForCallback(identifier: "restore", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
    }

    func testDefaultPaywallPresenterNavigatedBackSuppressesCheckpointCallback() async {
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
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
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
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

    func testContinueReturnsCustomerStateAndEverythingObtainedDuringTheFlow() async throws {
        let product = Self.storeProduct(identifier: "premium-product")
        let terminalCustomerInfo = try Self.customerInfo(
            activeEntitlements: ["premium", "pro"],
            purchaseDatesByProductId: ["premium-product": Date(timeIntervalSince1970: 10)]
        )
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(products: [product]), traceID: "trace_id") },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { try Self.customerInfo(activeEntitlements: ["pro"]) },
            customerInfoSynchronizer: {
                customerInfoSynchronizerCallCount += 1
                return terminalCustomerInfo
            }
        )

        let result = await manager.checkpointForCallback(
            identifier: "onboarding",
            params: .init(paywallPresenter: { _, completion in completion(.continued) })
        )

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        let flowResult = try XCTUnwrap(checkpointResult.flow)
        let obtainedEntitlement = try XCTUnwrap(flowResult.obtainedEntitlement("premium"))
        let obtainedProduct = try XCTUnwrap(flowResult.obtainedProduct("premium-product"))

        XCTAssertEqual(checkpointResult.customer, terminalCustomerInfo)
        XCTAssertEqual(flowResult.obtainedEntitlements, [obtainedEntitlement])
        XCTAssertEqual(obtainedEntitlement.entitlementInfo.identifier, "premium")
        XCTAssertEqual(flowResult.obtainedProducts, [obtainedProduct])
        XCTAssertEqual(obtainedProduct.product.productIdentifier, "premium-product")

        XCTAssertTrue(flowResult.didObtainEntitlement("premium"))
        XCTAssertFalse(flowResult.didObtainEntitlement("unknown"))
        XCTAssertTrue(flowResult.didObtainProduct("premium-product"))
        XCTAssertFalse(flowResult.didObtainProduct("unknown"))

        XCTAssertNil(flowResult.obtainedEntitlement("unknown"))
        XCTAssertNil(flowResult.obtainedProduct("unknown"))

        XCTAssertEqual(checkpointResult.obtainedEntitlement("premium"), obtainedEntitlement)
        XCTAssertNil(checkpointResult.obtainedEntitlement("unknown"))
        XCTAssertTrue(checkpointResult.didObtainEntitlement("premium"))
        XCTAssertFalse(checkpointResult.didObtainEntitlement("unknown"))
        XCTAssertEqual(checkpointResult.obtainedProduct("premium-product"), obtainedProduct)
        XCTAssertNil(checkpointResult.obtainedProduct("unknown"))
        XCTAssertTrue(checkpointResult.didObtainProduct("premium-product"))
        XCTAssertFalse(checkpointResult.didObtainProduct("unknown"))
        XCTAssertEqual(customerInfoSynchronizerCallCount, 1)
    }

    func testWorkflowCompletionReportsTheProductsItsOfferingsSold() async throws {
        let monthly = Self.storeProduct(identifier: "monthly")
        let executor = MockWorkflowPresenter()
        executor.execution = .completed(
            customerInfo: try Self.customerInfo(
                activeEntitlements: ["pro"],
                purchaseDatesByProductId: [
                    "monthly": Date(timeIntervalSince1970: 10),
                    "lifetime": Date(timeIntervalSince1970: 10)
                ]
            )
        )
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow(products: [monthly])) },
            workflowPresenter: executor,
            cachedCustomerInfoProvider: { try? Self.customerInfo(activeEntitlements: []) }
        )

        let result = await manager.checkpointForCallback(identifier: "soft_paywall", params: .init())

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.flow?.obtainedProducts.map(\.product.productIdentifier), ["monthly"])
        XCTAssertTrue(checkpointResult.didObtainProduct("monthly"))
        XCTAssertFalse(checkpointResult.didObtainProduct("lifetime"))
    }

    func testCustomerInfoSynchronizationFailurePresentsErrorThenReturnsTheLatestKnownCustomer() async throws {
        let expectedError = NSError(domain: "test", code: 42)
        let product = Self.storeProduct(identifier: "premium-product")
        let customerInfoBefore = try Self.customerInfo(activeEntitlements: ["pro"])
        let cachedCustomerInfo = try Self.customerInfo(
            activeEntitlements: ["premium", "pro"],
            purchaseDatesByProductId: ["premium-product": Date(timeIntervalSince1970: 10)]
        )
        let errorPresented = self.expectation(description: "Error is presented")
        var errorPresentationParams: ErrorPresentationParams?
        var errorPresentationCompletion: ErrorPresentationCompletion?
        var checkpointCompleted = false
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(products: [product]), traceID: "trace_id") },
            workflowPresenter: MockWorkflowPresenter(),
            customerInfoProvider: { customerInfoBefore },
            cachedCustomerInfoProvider: { cachedCustomerInfo },
            customerInfoSynchronizer: { throw expectedError }
        )

        let checkpoint = Task { @MainActor in
            let result = await manager.checkpointForCallback(
                identifier: "onboarding",
                params: .init(
                    paywallPresenter: { _, completion in completion(.continued) },
                    errorPresenter: { params, completion in
                        errorPresentationParams = params
                        errorPresentationCompletion = completion
                        errorPresented.fulfill()
                    }
                )
            )
            checkpointCompleted = true
            return result
        }

        await self.fulfillment(of: [errorPresented], timeout: 1)
        XCTAssertFalse(checkpointCompleted)
        XCTAssertEqual(errorPresentationParams?.checkpointIdentifier, "onboarding")
        XCTAssertEqual(errorPresentationParams?.error as NSError?, expectedError)
        XCTAssertEqual(errorPresentationParams?.kind, .flowResultSyncFailed)

        errorPresentationCompletion?.complete()
        errorPresentationCompletion?.complete()
        let result = await checkpoint.value

        guard case let .completed(checkpointResult) = result else {
            return XCTFail("Expected a completed callback")
        }
        XCTAssertEqual(checkpointResult.customer, cachedCustomerInfo)
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
        XCTAssertEqual(checkpointResult.flow?.obtainedProducts.map(\.product.productIdentifier), ["premium-product"])
        XCTAssertTrue(checkpointCompleted)
    }

    func testOnlyFirstPresenterCompletionSynchronizesCustomerInfo() async throws {
        let presentationStarted = self.expectation(description: "Custom presentation starts")
        let synchronizationStarted = self.expectation(description: "Customer info synchronization starts")
        var presenterCompletion: PaywallPresentationCompletion?
        var synchronizationContinuation: CheckedContinuation<CustomerInfo, Error>?
        var customerInfoSynchronizerCallCount = 0
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
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

        guard case let .completed(checkpointResult) = await checkpoint.value else {
            return XCTFail("Expected the first completion to finish the checkpoint")
        }
        XCTAssertEqual(checkpointResult.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
    }

    func testStalePresenterCompletionCannotReleaseReplacementPresentation() async throws {
        let firstStarted = self.expectation(description: "First custom presentation starts")
        let replacementStarted = self.expectation(description: "Replacement custom presentation starts")
        var firstCompletion: PaywallPresentationCompletion?
        var replacementCompletion: PaywallPresentationCompletion?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
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
            resolveCheckpoint: { _, _ in .matchedOffering(Self.offering(), traceID: "trace_id") },
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
            _ = try await manager.executeCheckpoint(identifier: "f0rc3_3rr0r", params: .init())
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

    }

    func testPresentationErrorIsPresentedAndReturnsFailed() async throws {
        let expectedError = NSError(domain: "test", code: 42)
        let executor = MockWorkflowPresenter()
        executor.error = expectedError
        var presentedError: (any Error)?
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let outcome = try await manager.executeCheckpoint(
            identifier: "soft_paywall",
            params: .init(errorPresenter: { params, completion in
                presentedError = params.error
                completion.complete()
            })
        )

        guard case .failed = outcome else {
            return XCTFail("Expected a failed presentation outcome")
        }
        XCTAssertEqual(presentedError as NSError?, expectedError)
    }

    func testWorkflowStartupErrorKeepsPresentationSlotUntilErrorPresentationCompletes() async throws {
        let expectedError = NSError(domain: "test", code: 42)
        let errorPresented = self.expectation(description: "Error is presented")
        var errorPresentationCompletion: ErrorPresentationCompletion?
        let executor = MockWorkflowPresenter()
        executor.error = expectedError
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            workflowPresenter: executor
        )

        let firstCheckpoint = Task {
            await manager.checkpointForCallback(
                identifier: "soft_paywall",
                params: .init(errorPresenter: { _, completion in
                    errorPresentationCompletion = completion
                    errorPresented.fulfill()
                })
            )
        }
        await self.fulfillment(of: [errorPresented], timeout: 1)

        do {
            _ = try await manager.executeCheckpoint(identifier: "soft_paywall", params: .init())
            XCTFail("Expected the error presentation to keep owning the presentation slot")
        } catch {
            XCTAssertEqual(
                (error as NSError).code,
                ErrorCode.operationAlreadyInProgressForProductError.rawValue
            )
        }

        errorPresentationCompletion?.complete()
        guard case .suppressed = await firstCheckpoint.value else {
            return XCTFail("Expected the failed presentation to suppress the callback")
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

    private static func offering(products: [StoreProduct] = []) -> Offering {
        return Offering(
            identifier: "offering-id",
            serverDescription: "Test offering",
            availablePackages: products.map { product in
                Package(
                    identifier: product.productIdentifier,
                    packageType: .custom,
                    storeProduct: product,
                    offeringIdentifier: "offering-id",
                    webCheckoutUrl: nil
                )
            },
            webCheckoutUrl: nil
        )
    }

    fileprivate static func customerInfo(
        activeEntitlements: [String],
        purchaseDatesByProductId: [String: Date] = [:]
    ) throws -> CustomerInfo {
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
            purchaseDatesByProductId: purchaseDatesByProductId,
            allPurchasedProductIds: Set(purchaseDatesByProductId.keys),
            requestDate: Date(timeIntervalSince1970: 0),
            firstSeen: Date(timeIntervalSince1970: 0),
            originalAppUserId: "test-user"
        )
    }

    private static func storeProduct(identifier: String) -> StoreProduct {
        return TestStoreProduct(
            localizedTitle: identifier,
            price: 1.99,
            currencyCode: "USD",
            localizedPriceString: "$1.99",
            productIdentifier: identifier,
            productType: .nonConsumable,
            localizedDescription: identifier,
            locale: Locale(identifier: "en_US")
        ).toStoreProduct()
    }

    private static func workflow(products: [StoreProduct] = []) -> ResolvedCheckpointWorkflow {
        let offering = Self.offering(products: products)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CheckpointsManagerTests {

    static var errorPresentationParams: ErrorPresentationParams {
        return .init(
            checkpointIdentifier: "test_checkpoint",
            error: NSError(domain: "test", code: 1),
            customVariables: [:],
            kind: .flowActionFailed
        )
    }

    static var errorPresentationCompletion: ErrorPresentationCompletion {
        return .init {}
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CheckpointsManager {

    convenience init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution
    ) {
        self.init(
            resolveCheckpoint: resolveCheckpoint,
            customerInfoProvider: { try CheckpointsManagerTests.customerInfo(activeEntitlements: []) }
        )
    }

    convenience init(
        resolveCheckpoint: @escaping (String, CheckpointCallParams) async throws -> CheckpointResolution,
        workflowPresenter: WorkflowPresenterType,
        defaultPaywallPresenter: PaywallPresenter? = nil,
        customerInfoProvider: @escaping CustomerInfoProvider = {
            try CheckpointsManagerTests.customerInfo(activeEntitlements: [])
        },
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
                cachedCustomerInfoProvider: cachedCustomerInfoProvider,
                customerInfoSynchronizer: customerInfoSynchronizer
            )
        }
        self.init(
            resolveCheckpoint: resolveCheckpoint,
            customerInfoProvider: customerInfoProvider,
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
private final class MockErrorPresenter: ErrorPresenter {

    private(set) var callCount = 0

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        self.callCount += 1
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
