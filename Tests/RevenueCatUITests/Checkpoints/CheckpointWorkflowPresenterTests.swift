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

        try presenter.present(presentation: Self.presentation(), delegate: delegate)
        presenter.stage(.outcome(CheckpointPaywallOutcome.Error(error: error)))

        XCTAssertEqual(delegate.finishCount, 0)
        XCTAssertNotNil(store.call)

        presenter.presentationDidDismiss()
        presenter.presentationDidDismiss()

        XCTAssertEqual(delegate.finishCount, 1)
        guard let errorOutcome = delegate.outcome as? CheckpointPaywallOutcome.Error else {
            return XCTFail("Expected an error outcome")
        }
        XCTAssertEqual(errorOutcome.error, error)
        XCTAssertNil(store.call)
    }

    func testWorkflowPresentationErrorProducesErrorOutcomeAfterDismissal() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.present(presentation: presentation, delegate: delegate)
        let viewController = try presenter.makePaywallViewController(for: presentation)
        viewController.simulateWorkflowPresentationError(error)
        presenter.presentationDidDismiss()

        guard let outcome = delegate.outcome as? CheckpointPaywallOutcome.Error else {
            return XCTFail("Expected a configuration error outcome")
        }
        XCTAssertEqual(outcome.error, error)
    }

    func testWorkflowPresentationErrorDoesNotReplaceEarlierPurchaseOutcome() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let controller = try presenter.makePaywallViewController(for: presentation)
        let transaction = StoreTransaction(MockStoreTransaction())
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.present(presentation: presentation, delegate: delegate)
        presenter.paywallViewController(
            controller,
            didFinishPurchasingWith: TestData.customerInfo,
            transaction: transaction
        )
        controller.simulateWorkflowPresentationError(error)
        presenter.presentationDidDismiss()

        guard let outcome = delegate.outcome as? CheckpointPaywallOutcome.Purchased else {
            return XCTFail("Expected the purchase outcome to win")
        }
        XCTAssertEqual(outcome.transaction, transaction)
        XCTAssertEqual(outcome.customerInfo, TestData.customerInfo)
    }

    func testWorkflowPresentationErrorDoesNotReplaceEarlierRestoreOutcome() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let controller = try presenter.makePaywallViewController(for: presentation)
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.present(presentation: presentation, delegate: delegate)
        presenter.paywallViewController(controller, didFinishRestoringWith: TestData.customerInfo)
        controller.simulateWorkflowPresentationError(error)
        presenter.presentationDidDismiss()

        guard let outcome = delegate.outcome as? CheckpointPaywallOutcome.Restored else {
            return XCTFail("Expected the restore outcome to win")
        }
        XCTAssertEqual(outcome.customerInfo, TestData.customerInfo)
    }

    func testWorkflowPresentationErrorDoesNotReplaceEarlierWebCheckoutOutcome() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let controller = try presenter.makePaywallViewController(for: presentation)
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.present(presentation: presentation, delegate: delegate)
        presenter.paywallViewControllerDidOpenWebCheckout(controller)
        controller.simulateWorkflowPresentationError(error)
        presenter.presentationDidDismiss()

        XCTAssertTrue(delegate.outcome is CheckpointPaywallOutcome.WebCheckoutOpened)
    }

    func testBackingOutReportsDismissedOutcomeAndBackedOut() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }

        try presenter.present(presentation: Self.presentation(), delegate: delegate)
        presenter.presentationDidDismiss(reason: .navigatedBack)

        XCTAssertTrue(delegate.outcome is CheckpointPaywallOutcome.Dismissed)
        XCTAssertTrue(delegate.didBackOut)
    }

    func testBackingOutKeepsAStagedErrorOutcome() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let error = NSError(domain: "test", code: 1)

        try presenter.present(presentation: Self.presentation(), delegate: delegate)
        presenter.stage(.outcome(CheckpointPaywallOutcome.Error(error: error)))
        presenter.presentationDidDismiss(reason: .navigatedBack)

        guard let outcome = delegate.outcome as? CheckpointPaywallOutcome.Error else {
            return XCTFail("Expected an error outcome")
        }
        XCTAssertEqual(outcome.error, error)
        XCTAssertTrue(delegate.didBackOut)
    }

    func testInteractiveDismissalIsNotReportedAsBackingOut() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = Self.presentation()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let controller = PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"])
        let presentationController = UIPresentationController(
            presentedViewController: controller,
            presenting: UIViewController()
        )

        try presenter.present(presentation: presentation, delegate: delegate)
        controller.presentationControllerWillDismiss(presentationController)
        presenter.paywallViewControllerWasDismissed(controller)

        XCTAssertTrue(delegate.outcome is CheckpointPaywallOutcome.Dismissed)
        XCTAssertFalse(delegate.didBackOut)
    }

    func testPurchaseCallbackPreservesTransaction() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = Self.presentation()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let transaction = StoreTransaction(MockStoreTransaction())

        try presenter.present(presentation: presentation, delegate: delegate)
        presenter.paywallViewController(
            PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"]),
            didFinishPurchasingWith: TestData.customerInfo,
            transaction: transaction
        )

        guard let stagedOutcome = store.call?.stagedOutcome as? CheckpointPaywallOutcome.Purchased else {
            return XCTFail("Expected a purchased outcome")
        }
        XCTAssertEqual(stagedOutcome.transaction, transaction)
        XCTAssertEqual(stagedOutcome.customerInfo, TestData.customerInfo)

        presenter.presentationDidDismiss()

        guard let reportedOutcome = delegate.outcome as? CheckpointPaywallOutcome.Purchased else {
            return XCTFail("Expected a purchased outcome")
        }
        XCTAssertEqual(reportedOutcome.transaction, transaction)
        XCTAssertEqual(reportedOutcome.customerInfo, TestData.customerInfo)
    }

    func testWebCheckoutCallbackStagesOutcomeUntilPresentationFinishesDismissing() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = Self.presentation()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }

        try presenter.present(presentation: presentation, delegate: delegate)
        presenter.paywallViewControllerDidOpenWebCheckout(
            PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"])
        )

        XCTAssertTrue(store.call?.stagedOutcome is CheckpointPaywallOutcome.WebCheckoutOpened)
        XCTAssertNil(delegate.outcome)

        presenter.presentationDidDismiss()

        XCTAssertTrue(delegate.outcome is CheckpointPaywallOutcome.WebCheckoutOpened)
        XCTAssertNil(store.call)
    }

    func testPurchaseOutcomeReplacesEarlierWebCheckoutOutcome() throws {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        let presentation = Self.presentation()
        let presenter = CheckpointWorkflowPresenter(callStore: store) { _ in true }
        let controller = PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"])
        let transaction = StoreTransaction(MockStoreTransaction())

        try presenter.present(presentation: presentation, delegate: delegate)
        presenter.paywallViewControllerDidOpenWebCheckout(controller)
        presenter.paywallViewController(
            controller,
            didFinishPurchasingWith: TestData.customerInfo,
            transaction: transaction
        )
        presenter.presentationDidDismiss()

        guard let outcome = delegate.outcome as? CheckpointPaywallOutcome.Purchased else {
            return XCTFail("Expected the later purchase outcome")
        }
        XCTAssertEqual(outcome.transaction, transaction)
        XCTAssertEqual(outcome.customerInfo, TestData.customerInfo)
    }

    func testCallStoreDefaultsToDismissedAndRemovesCall() {
        let store = CheckpointCallStore()
        let delegate = MockCheckpointPresenterDelegate()
        store.store(presentation: Self.presentation(), delegate: delegate)

        let call = store.remove()

        guard call?.stagedOutcome is CheckpointPaywallOutcome.Dismissed else {
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
        try presenter.present(presentation: Self.presentation(), delegate: delegate)

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
        let presentation = Self.presentation()
        let presenter = CheckpointWorkflowPresenter { _ in true }
        try presenter.present(presentation: presentation, delegate: MockCheckpointPresenterDelegate())
        let originalController = PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"])
        let exitOfferController = DismissRecordingPaywallController(
            offering: try XCTUnwrap(presentation.workflow.offerings.all["offering-id"])
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
            try presenter.present(presentation: Self.presentation(), delegate: delegate)
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
            try presenter.present(presentation: Self.presentation(), delegate: delegate)
        ) { error in
            XCTAssertEqual(error as NSError, expectedError)
        }
        XCTAssertNil(store.call)
        XCTAssertEqual(delegate.finishCount, 0)
    }

    #endif

    func testCustomVariablesAreKeptWithThePresentedWorkflow() throws {
        let store = CheckpointCallStore()
        let expected: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ]
        var receivedPresentation: CheckpointPresentation?
        let presenter = CheckpointWorkflowPresenter(callStore: store) { presentation in
            receivedPresentation = presentation
            return true
        }

        try presenter.present(
            presentation: Self.presentation(customVariables: expected),
            delegate: MockCheckpointPresenterDelegate()
        )

        XCTAssertEqual(receivedPresentation?.customVariables, expected)
        XCTAssertEqual(store.call?.presentation.customVariables, expected)
    }

    func testCustomVariablesAreAppliedToThePaywallViewController() throws {
        let expected: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ]
        let presenter = CheckpointWorkflowPresenter { _ in true }

        let viewController = try presenter.makePaywallViewController(
            for: Self.renderablePresentation(customVariables: expected)
        )

        XCTAssertEqual(viewController.customVariables, expected)
    }

    private static func presentation(
        customVariables: [String: CustomVariableValue] = [:]
    ) -> CheckpointPresentation {
        return CheckpointPresentation(
            workflow: self.workflow(),
            customVariables: customVariables
        )
    }

    private static func renderablePresentation(
        customVariables: [String: CustomVariableValue]
    ) throws -> CheckpointPresentation {
        let resolvedWorkflow = self.workflow()
        let screen = WorkflowScreen(
            name: nil,
            templateName: "test",
            assetBaseURL: try XCTUnwrap(URL(string: "https://assets.revenuecat.com")),
            componentsConfig: try self.componentsConfig(),
            componentsLocalizations: [:],
            defaultLocale: "en_US",
            offeringIdentifier: "offering-id"
        )
        let workflow = PublishedWorkflow(
            id: "workflow-id",
            displayName: "Test",
            initialStepId: "step-id",
            singleStepFallbackId: nil,
            steps: ["step-id": WorkflowStep(id: "step-id", type: "screen", screenId: "screen-id")],
            screens: ["screen-id": screen]
        )
        return CheckpointPresentation(
            workflow: ResolvedCheckpointWorkflow(
                workflow: workflow,
                uiConfig: resolvedWorkflow.uiConfig,
                offerings: resolvedWorkflow.offerings
            ),
            customVariables: customVariables
        )
    }

    private static func componentsConfig() throws -> PaywallComponentsData.ComponentsConfig {
        let json = """
        {
          "base": {
            "stack": {
              "type": "stack",
              "components": [],
              "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
              "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
              "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
              "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
            },
            "background": {
              "type": "color",
              "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
            }
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PaywallComponentsData.ComponentsConfig.self, from: data)
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
        let offering = Offering(
            identifier: "offering-id",
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        return ResolvedCheckpointWorkflow(
            workflow: workflow,
            uiConfig: .empty,
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

    private(set) var execution: CheckpointExecution<CheckpointPaywallOutcome>?
    var outcome: CheckpointPaywallOutcome? { self.execution?.value }
    var didBackOut: Bool {
        guard let execution else { return false }
        if case .backedOut = execution {
            return true
        }
        return false
    }
    private(set) var finishCount = 0

    func checkpointPresentationFinished(_ execution: CheckpointExecution<CheckpointPaywallOutcome>) {
        self.finishCount += 1
        self.execution = execution
    }

}

#endif
