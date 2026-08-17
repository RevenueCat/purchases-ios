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
@_spi(CheckpointsInternal) @_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CheckpointWorkflowPresenterTests: TestCase {

    func testPresenterStagesOutcomeUntilPresentationFinishesDismissing() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let error = NSError(domain: "test", code: 1)

        try presenter.present(workflow: Self.workflow(), delegate: delegate)
        presenter.stage(outcome: CheckpointPaywallErrorOutcome(error: error))

        XCTAssertEqual(delegate.finishCount, 0)
        XCTAssertNotNil(store.call)

        presenter.presentationDidDismiss()
        presenter.presentationDidDismiss()

        XCTAssertEqual(delegate.finishCount, 1)
        guard let errorOutcome = delegate.outcome as? CheckpointPaywallErrorOutcome else {
            return XCTFail("Expected an error outcome")
        }
        XCTAssertEqual(errorOutcome.error, error)
        XCTAssertNil(store.call)
    }

    func testCallStoreDefaultsToDismissedAndRemovesCall() {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        store.store(workflow: Self.workflow(), delegate: delegate)

        let call = store.remove()

        guard call?.stagedOutcome is CheckpointPaywallDismissedOutcome else {
            return XCTFail("Expected a dismissed outcome")
        }
        XCTAssertTrue(call?.delegate === delegate)
        XCTAssertNil(store.call)
    }

    func testDismissRemovesCallWithoutReportingAnOutcome() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        var didFinishDismissing = false
        try presenter.present(workflow: Self.workflow(), delegate: delegate)

        presenter.dismiss {
            didFinishDismissing = true
        }
        presenter.presentationDidDismiss()

        XCTAssertTrue(didFinishDismissing)
        XCTAssertNil(store.call)
        XCTAssertEqual(delegate.finishCount, 0)
    }

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)

    func testDismissTargetsPresentedExitOfferController() throws {
        let workflow = Self.workflow()
        let presenter = CheckpointWorkflowPresenter { _ in true }
        try presenter.present(workflow: workflow, delegate: MockCheckpointPresenterDelegate())
        let originalController = PaywallViewController(offering: workflow.offering)
        let exitOfferController = DismissRecordingPaywallController(
            offering: workflow.offering
        )

        presenter.paywallViewController(
            originalController,
            willPresentExitOfferController: exitOfferController
        )
        presenter.dismiss {}

        XCTAssertEqual(exitOfferController.dismissCallCount, 1)
    }

    func testRejectedPresentationThrowsAndCleansStoredCall() {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in false }

        XCTAssertThrowsError(
            try presenter.present(workflow: Self.workflow(), delegate: delegate)
        ) { error in
            guard case CheckpointError.presentationFailed = error else {
                return XCTFail("Expected presentationFailed, got \(error)")
            }
        }
        XCTAssertNil(store.call)
        XCTAssertEqual(delegate.finishCount, 0)
    }

    func testPresentationSetupErrorIsPropagatedAndCleansStoredCall() {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let expectedError = NSError(domain: "test", code: 42)
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in
            throw expectedError
        }

        XCTAssertThrowsError(
            try presenter.present(workflow: Self.workflow(), delegate: delegate)
        ) { error in
            XCTAssertEqual(error as NSError, expectedError)
        }
        XCTAssertNil(store.call)
        XCTAssertEqual(delegate.finishCount, 0)
    }

    #endif

    private static func workflow() -> ResolvedCheckpointWorkflow {
        let workflow = PublishedWorkflow(
            id: "workflow-id",
            displayName: "Test",
            initialStepId: "step-id",
            singleStepFallbackId: nil,
            steps: ["step-id": WorkflowStep(id: "step-id", type: "screen", screenId: nil)],
            screens: [:]
        )
        let offering = Offering(
            identifier: "offering-id",
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        return ResolvedCheckpointWorkflow(
            workflow: workflow,
            uiConfig: .empty,
            offering: offering,
            offerings: .preview(offerings: [offering])
        )
    }

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, *)
private final class DismissRecordingPaywallController: PaywallViewController {

    private(set) var dismissCallCount = 0
    private let stubbedPresentingViewController = UIViewController()

    override var presentingViewController: UIViewController? {
        return self.stubbedPresentingViewController
    }

    init(offering: Offering) {
        super.init(
            content: .offering(offering),
            fonts: DefaultPaywallFontProvider(),
            displayCloseButton: false,
            shouldBlockTouchEvents: false,
            performPurchase: nil,
            performRestore: nil,
            dismissRequestedHandler: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        self.dismissCallCount += 1
        completion?()
    }

}

#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class MockCheckpointPresenterDelegate: CheckpointPresentationDelegate {

    private(set) var outcome: CheckpointPaywallOutcome?
    private(set) var finishCount = 0

    func checkpointPresentationFinished(outcome: CheckpointPaywallOutcome) {
        self.finishCount += 1
        self.outcome = outcome
    }

}

#endif
