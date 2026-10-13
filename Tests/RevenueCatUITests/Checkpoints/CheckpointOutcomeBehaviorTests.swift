//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointOutcomeBehaviorTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointOutcomeBehaviorTests: TestCase {

    // Unknown checkpoint: invoke the callback with nil and do not invoke the error presenter.
    func testUnknownCheckpoint() async {
        await self.assertCompletedWithNil(.noAction(.unknownCheckpoint))
    }

    // No matching rule: invoke the callback with nil and do not invoke the error presenter.
    func testNoMatchingRule() async {
        await self.assertCompletedWithNil(.noAction(.noMatch))
    }

    // Invalid checkpoint identifier: invoke the error presenter and do not invoke the callback.
    func testInvalidCheckpointIdentifier() async {
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager { _, _ in
            XCTFail("Invalid identifiers must not reach resolution")
            return .noAction(.noMatch)
        }

        let result = await manager.checkpointForCallback(
            identifier: " checkout😀",
            params: self.params(errorPresenter: errorPresenter)
        )

        self.assertSuppressed(result)
        self.assertTerminalErrorWasPresented(by: errorPresenter, checkpointIdentifier: " checkout😀")
        XCTAssertEqual(
            (errorPresenter.presentations.first?.error as NSError?)?.code,
            ErrorCode.configurationError.rawValue
        )
        XCTAssertEqual(
            errorPresenter.presentations.first?.error.localizedDescription,
            CheckpointIdentifierValidator.invalidIdentifierLogMessage(" checkout😀")
        )
    }

    // Checkpoint resolution failure: invoke the error presenter and do not invoke the callback.
    func testResolutionFailure() async {
        let expectedError = NSError(domain: "CheckpointOutcomeBehaviorTests", code: 1)
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager { _, _ in
            throw expectedError
        }

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        self.assertSuppressed(result)
        self.assertTerminalErrorWasPresented(by: errorPresenter, checkpointIdentifier: "soft_paywall")
        XCTAssertEqual(errorPresenter.presentations.first?.error as NSError?, expectedError)
    }

    // Configuration unavailable: invoke the error presenter and do not invoke the callback.
    func testConfigurationUnavailable() async {
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager { _, _ in .noAction(.configurationUnavailable) }

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        self.assertSuppressed(result)
        self.assertTerminalErrorWasPresented(by: errorPresenter, checkpointIdentifier: "soft_paywall")
        XCTAssertEqual(
            (errorPresenter.presentations.first?.error as NSError?)?.code,
            ErrorCode.configurationError.rawValue
        )
    }

    // Presentation startup failure: invoke the error presenter and do not invoke the callback.
    func testPresentationStartupFailure() async {
        let expectedError = NSError(domain: "CheckpointOutcomeBehaviorTests", code: 2)
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            checkpointPresenter: FailingCheckpointPresenter(error: expectedError)
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        self.assertSuppressed(result)
        self.assertTerminalErrorWasPresented(by: errorPresenter, checkpointIdentifier: "soft_paywall")
        XCTAssertEqual(errorPresenter.presentations.first?.error as NSError?, expectedError)
    }

    // Terminal workflow error: do not invoke the callback again or the error presenter.
    func testTerminalWorkflowError() async {
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            checkpointPresenter: OutcomeCheckpointPresenter(outcome: .failed)
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        self.assertSuppressed(result)
        XCTAssertTrue(errorPresenter.presentations.isEmpty)
    }

    // Terminal default paywall error: do not invoke the callback again or the error presenter.
    func testTerminalDefaultPaywallError() async {
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager { _, _ in .matchedOffering(Self.offering()) }

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: .init(
                paywallPresenter: { _, completion in completion(.failed) },
                errorPresenter: { params, _ in errorPresenter.presentations.append(params) }
            )
        )

        self.assertSuppressed(result)
        XCTAssertTrue(errorPresenter.presentations.isEmpty)
    }

    // Completed Flow with a newly active entitlement: invoke the callback with that entitlement.
    func testFlowCompletesWithObtainedEntitlement() async throws {
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            checkpointPresenter: OutcomeCheckpointPresenter(
                outcome: .completed(
                    customerInfo: try Self.customerInfo(activeEntitlements: ["premium", "pro"])
                )
            ),
            cachedCustomerInfoProvider: {
                try? Self.customerInfo(activeEntitlements: ["pro"])
            }
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected the callback to be invoked")
        }
        XCTAssertEqual(flowResult?.obtainedEntitlements.map(\.entitlementInfo.identifier), ["premium"])
        XCTAssertTrue(errorPresenter.presentations.isEmpty)
    }

    // Completed Flow with only previously active entitlements: invoke the callback with an empty result.
    func testFlowCompletesWithoutObtainedEntitlement() async throws {
        let errorPresenter = ErrorPresentationRecorder()
        let customerInfo = try Self.customerInfo(activeEntitlements: ["premium"])
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            checkpointPresenter: OutcomeCheckpointPresenter(outcome: .completed(customerInfo: customerInfo)),
            cachedCustomerInfoProvider: { customerInfo }
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected the callback to be invoked")
        }
        XCTAssertTrue(flowResult?.obtainedEntitlements.isEmpty == true)
        XCTAssertTrue(errorPresenter.presentations.isEmpty)
    }

    // Post-Flow synchronization failure: invoke the callback with an empty result without presenting an error yet.
    func testPostFlowSynchronizationFailure() async {
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager(
            resolveCheckpoint: { _, _ in .matchedWorkflow(Self.workflow()) },
            checkpointPresenter: OutcomeCheckpointPresenter(
                outcome: .synchronizationFailed(NSError(domain: "test", code: 1))
            )
        )

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected the callback to be invoked")
        }
        XCTAssertTrue(flowResult?.obtainedEntitlements.isEmpty == true)
        XCTAssertTrue(errorPresenter.presentations.isEmpty)
    }

    private func assertCompletedWithNil(
        _ resolution: CheckpointResolution,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let errorPresenter = ErrorPresentationRecorder()
        let manager = CheckpointsManager { _, _ in resolution }

        let result = await manager.checkpointForCallback(
            identifier: "soft_paywall",
            params: self.params(errorPresenter: errorPresenter)
        )

        guard case let .completed(flowResult) = result else {
            return XCTFail("Expected the callback to be invoked", file: file, line: line)
        }
        XCTAssertNil(flowResult, file: file, line: line)
        XCTAssertTrue(errorPresenter.presentations.isEmpty, file: file, line: line)
    }

    private func assertSuppressed(
        _ result: CheckpointCallbackResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .suppressed = result else {
            return XCTFail("Expected the callback not to be invoked", file: file, line: line)
        }
    }

    private func assertTerminalErrorWasPresented(
        by errorPresenter: ErrorPresentationRecorder,
        checkpointIdentifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(errorPresenter.presentations.count, 1, file: file, line: line)
        XCTAssertEqual(
            errorPresenter.presentations.first?.checkpointIdentifier,
            checkpointIdentifier,
            file: file,
            line: line
        )
        XCTAssertEqual(errorPresenter.presentations.first?.stage, .beforeFlowPresentation, file: file, line: line)
        XCTAssertEqual(
            errorPresenter.presentations.first?.customVariables,
            ["source": "test"],
            file: file,
            line: line
        )
    }

    private func params(errorPresenter: ErrorPresentationRecorder) -> CheckpointCallParams {
        return .init(
            customVariables: ["source": "test"],
            errorPresenter: { params, completion in
                errorPresenter.presentations.append(params)
                completion.complete()
            }
        )
    }

    private static func workflow() -> ResolvedCheckpointWorkflow {
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
            offerings: .preview(offerings: [])
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

}

private final class ErrorPresentationRecorder: @unchecked Sendable {
    var presentations: [ErrorPresentationParams] = []
}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class FailingCheckpointPresenter: CheckpointPresenterType {

    private let error: any Error

    init(error: any Error) {
        self.error = error
    }

    func presentWorkflow(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome {
        throw self.error
    }

    func presentOffering(
        params: PaywallPresentationParams,
        globalPaywallPresenter: PaywallPresenter?,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointPresentationOutcome {
        throw self.error
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class OutcomeCheckpointPresenter: CheckpointPresenterType {

    private let outcome: CheckpointPresentationOutcome

    init(outcome: CheckpointPresentationOutcome) {
        self.outcome = outcome
    }

    func presentWorkflow(_ presentation: WorkflowPresentationRequest) async throws -> CheckpointPresentationOutcome {
        return self.outcome
    }

    func presentOffering(
        params: PaywallPresentationParams,
        globalPaywallPresenter: PaywallPresenter?,
        localPaywallPresentationHandler: PaywallPresentationHandler?
    ) async throws -> CheckpointPresentationOutcome {
        return self.outcome
    }

}
