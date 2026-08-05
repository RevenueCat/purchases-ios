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

    func testRuntimePresenterProviderCanBeDiscovered() throws {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        let provider = try XCTUnwrap(
            NSClassFromString("RCCheckpointPresenterProvider") as? CheckpointPresenterProvider.Type
        )

        XCTAssertTrue(provider.makeCheckpointPresenter() is CheckpointWorkflowPresenter)
        #endif
    }

    func testPresenterRejectsAnUnresolvedPresentation() {
        let presenter = CheckpointWorkflowPresenter()
        let delegate = MockCheckpointPresenterDelegate()
        let checkpoint = CheckpointInfo(identifier: "test_checkpoint", params: CheckpointParams())

        presenter.present(
            callID: "call-id",
            presentation: CheckpointWorkflowPresentation(checkpoint: checkpoint),
            delegate: delegate
        )

        XCTAssertEqual(delegate.finishedCallID, "call-id")
        XCTAssertTrue(delegate.outcome is CheckpointPaywallErrorOutcome)
    }

    func testPresenterStagesOutcomeUntilPresentationFinishesDismissing() {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let error = NSError(domain: "test", code: 1)

        presenter.present(
            callID: "call-id",
            presentation: Self.presentation(),
            delegate: delegate
        )
        presenter.stage(outcome: CheckpointPaywallErrorOutcome(error: error), callID: "call-id")

        XCTAssertNil(delegate.finishedCallID)
        XCTAssertNotNil(store.call(for: "call-id"))

        presenter.presentationDidDismiss(callID: "call-id")
        presenter.presentationDidDismiss(callID: "call-id")

        XCTAssertEqual(delegate.finishedCallID, "call-id")
        XCTAssertEqual(delegate.finishCount, 1)
        XCTAssertEqual((delegate.outcome as? CheckpointPaywallErrorOutcome)?.error, error)
        XCTAssertNil(store.call(for: "call-id"))
    }

    func testCallStoreDefaultsToDismissedAndRemovesCallsIndependently() {
        let store = CheckpointCallStore()
        let firstDelegate = MockCheckpointPresenterDelegate()
        let secondDelegate = MockCheckpointPresenterDelegate()
        store.store(callID: "first", presentation: Self.presentation(), delegate: firstDelegate)
        store.store(callID: "second", presentation: Self.presentation(), delegate: secondDelegate)

        let first = store.remove(callID: "first")

        XCTAssertTrue(first?.stagedOutcome is CheckpointPaywallDismissedOutcome)
        XCTAssertTrue(first?.delegate === firstDelegate)
        XCTAssertNil(store.call(for: "first"))
        XCTAssertNotNil(store.call(for: "second"))
    }

    private static func presentation() -> ResolvedCheckpointWorkflowPresentation {
        let checkpoint = CheckpointInfo(identifier: "test_checkpoint", params: .init())
        let workflow = PublishedWorkflow(
            id: "workflow-id",
            displayName: "Test",
            initialStepId: "step-id",
            singleStepFallbackId: nil,
            steps: ["step-id": WorkflowStep(id: "step-id", type: "screen", screenId: nil)],
            screens: [:]
        )
        return ResolvedCheckpointWorkflowPresentation(
            checkpoint: checkpoint,
            workflow: workflow,
            uiConfig: .empty,
            offering: nil
        )
    }

}

private final class MockCheckpointPresenterDelegate: CheckpointPresenterDelegate {

    private(set) var finishedCallID: String?
    private(set) var outcome: CheckpointPaywallOutcome?
    private(set) var finishCount = 0

    func onCheckpointPaywallFinished(callID: String, outcome: CheckpointPaywallOutcome) {
        self.finishCount += 1
        self.finishedCallID = callID
        self.outcome = outcome
    }

}
