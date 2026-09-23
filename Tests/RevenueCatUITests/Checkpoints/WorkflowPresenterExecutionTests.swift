//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPresenterExecutionTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(CheckpointsInternal) @_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowPresenterExecutionTests: TestCase {

    func testCustomVariablesAreForwardedToThePresenter() async throws {
        let expected: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ]
        let presenter = WorkflowPresenterHarness()
        presenter.onPresent = { presentation in
            presentation.finish(.completed(customerInfo: nil))
        }
        let workflowPresenter = presenter.workflowPresenter

        _ = try await workflowPresenter.present(Self.presentation(customVariables: expected))

        XCTAssertEqual(
            presenter.presentations.first?.checkpointPresentation.customVariables,
            expected
        )
    }

    func testExecutionForwardsBackOutFromThePresenter() async throws {
        let presenter = WorkflowPresenterHarness()
        presenter.onPresent = { presentation in
            presentation.finish(.backedOut)
        }
        let workflowPresenter = presenter.workflowPresenter

        let execution = try await workflowPresenter.present(Self.presentation())

        guard case .backedOut = execution else {
            return XCTFail("Expected a backed-out workflow execution")
        }
    }

    func testPresentationFailureResumesExecutionAndAllowsRetry() async throws {
        let presenter = WorkflowPresenterHarness()
        let expectedError = NSError(domain: "test", code: 42)
        presenter.presentationError = expectedError
        let workflowPresenter = presenter.workflowPresenter

        let failure = try await workflowPresenter.present(Self.presentation())
        guard case .failed = failure else {
            return XCTFail("Expected presentation failure")
        }

        presenter.presentationError = nil
        presenter.onPresent = { presentation in
            presentation.finish(.completed(customerInfo: nil))
        }
        _ = try await workflowPresenter.present(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 1)
    }

    func testConcurrentExecutionFailsWhilePresentationIsActive() async throws {
        let presenter = WorkflowPresenterHarness()
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
        presentation.finish(.completed(customerInfo: nil))
        _ = try await firstExecution.value
    }

    func testExecutionCanRestartAfterPresentationFinishes() async throws {
        let presenter = WorkflowPresenterHarness()
        presenter.onPresent = { presentation in
            presentation.finish(.completed(customerInfo: nil))
        }
        let workflowPresenter = presenter.workflowPresenter

        _ = try await workflowPresenter.present(Self.presentation())
        _ = try await workflowPresenter.present(Self.presentation())

        XCTAssertEqual(presenter.presentations.count, 2)
    }

    func testPresentationCompletionWithoutPendingExecutionIsIgnored() {
        let presenter = WorkflowPresenterHarness()
        let workflowPresenter = presenter.workflowPresenter

        XCTAssertNil(workflowPresenter.presentationDidDismiss())

        XCTAssertTrue(presenter.presentations.isEmpty)
    }

    private static func presentation(
        customVariables: [String: CustomVariableValue] = [:]
    ) -> WorkflowPresentationRequest {
        return WorkflowPresentationRequest(
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
private final class WorkflowPresenterHarness {

    struct Presentation {
        let checkpointPresentation: WorkflowPresentationRequest
        let finish: (CheckpointPresentationOutcome) -> Void
    }

    var onPresent: ((Presentation) -> Void)?
    var presentationError: Error?
    private(set) var presentations: [Presentation] = []

    lazy var workflowPresenter = WorkflowPresenter(
        presentationStarter: { [weak self] presentation in
            return try self?.handlePresentation(presentation) ?? false
        }
    )

    private func handlePresentation(_ presentation: WorkflowPresentationRequest) throws -> Bool {
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

    private func finish(_ execution: CheckpointPresentationOutcome) {
        switch execution {
        case .nothingPresented:
            self.workflowPresenter.presentationDidDismiss()
        case .completed, .failed:
            self.workflowPresenter.stage(.outcome(execution))
            self.workflowPresenter.presentationDidDismiss(reason: .close)
        case .backedOut:
            self.workflowPresenter.presentationDidDismiss(reason: .navigatedBack)
        }
    }
}

#endif
