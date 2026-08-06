//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowPresenterTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CheckpointWorkflowPresenterTests: TestCase {

    func testPresenterStagesOutcomeUntilPresentationFinishesDismissing() {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let error = NSError(domain: "test", code: 1)

        presenter.present(
            callID: "call-id",
            workflow: Self.workflow(),
            delegate: delegate
        )
        presenter.stage(outcome: CheckpointPaywallErrorOutcome(error: error), callID: "call-id")

        XCTAssertNil(delegate.finishedCallID)
        XCTAssertNotNil(store.call(for: "call-id"))

        presenter.presentationDidDismiss(callID: "call-id")
        presenter.presentationDidDismiss(callID: "call-id")

        XCTAssertEqual(delegate.finishedCallID, "call-id")
        XCTAssertEqual(delegate.finishCount, 1)
        guard let errorOutcome = delegate.outcome as? CheckpointPaywallErrorOutcome else {
            return XCTFail("Expected an error outcome")
        }
        XCTAssertEqual(errorOutcome.error, error)
        XCTAssertNil(store.call(for: "call-id"))
    }

    func testCallStoreDefaultsToDismissedAndRemovesCallsIndependently() {
        let store = CheckpointCallStore()
        let firstDelegate = MockCheckpointPresenterDelegate()
        let secondDelegate = MockCheckpointPresenterDelegate()
        store.store(callID: "first", workflow: Self.workflow(), delegate: firstDelegate)
        store.store(callID: "second", workflow: Self.workflow(), delegate: secondDelegate)

        let first = store.remove(callID: "first")

        guard first?.stagedOutcome is CheckpointPaywallDismissedOutcome else {
            return XCTFail("Expected a dismissed outcome")
        }
        XCTAssertTrue(first?.delegate === firstDelegate)
        XCTAssertNil(store.call(for: "first"))
        XCTAssertNotNil(store.call(for: "second"))
    }

    func testDismissRemovesCallWithoutReportingAnOutcome() {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        var didFinishDismissing = false
        presenter.present(
            callID: "call-id",
            workflow: Self.workflow(),
            delegate: delegate
        )

        presenter.dismiss(callID: "call-id") {
            didFinishDismissing = true
        }
        presenter.presentationDidDismiss(callID: "call-id")

        XCTAssertTrue(didFinishDismissing)
        XCTAssertNil(store.call(for: "call-id"))
        XCTAssertEqual(delegate.finishCount, 0)
    }

    private static func workflow() -> ResolvedCheckpointWorkflow {
        let workflow = PublishedWorkflow(
            id: "workflow-id",
            displayName: "Test",
            initialStepId: "step-id",
            singleStepFallbackId: nil,
            steps: ["step-id": WorkflowStep(id: "step-id", type: "screen", screenId: nil)],
            screens: [:]
        )
        return ResolvedCheckpointWorkflow(
            workflow: workflow,
            uiConfig: .empty,
            offering: Offering(
                identifier: "offering-id",
                serverDescription: "Test offering",
                availablePackages: [],
                webCheckoutUrl: nil
            )
        )
    }

}

private final class MockCheckpointPresenterDelegate: CheckpointPresentationDelegate {

    private(set) var finishedCallID: String?
    private(set) var outcome: CheckpointPaywallOutcome?
    private(set) var finishCount = 0

    func checkpointPresentationFinished(callID: String, outcome: CheckpointPaywallOutcome) {
        self.finishCount += 1
        self.finishedCallID = callID
        self.outcome = outcome
    }

}
