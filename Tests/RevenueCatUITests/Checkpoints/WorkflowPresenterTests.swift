//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPresenterTests.swift
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
final class WorkflowPresenterTests: TestCase {

    func testPresenterStagesOutcomeUntilPresentationFinishesDismissing() throws {
        let presenter = WorkflowPresenter { _ in true }
        try presenter.startPresentation(Self.presentation())
        presenter.stage(.outcome(.failed))

        let execution = presenter.presentationDidDismiss()
        XCTAssertNil(presenter.presentationDidDismiss())

        guard case .failed? = execution else {
            return XCTFail("Expected an error outcome")
        }
    }

    func testWorkflowPresentationErrorProducesErrorOutcomeAfterDismissal() throws {
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = WorkflowPresenter { _ in true }
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.startPresentation(presentation)
        let viewController = try presenter.makePaywallViewController(for: presentation)
        viewController.simulateWorkflowPresentationError(error)
        let execution = presenter.presentationDidDismiss()

        guard case .failed? = execution else {
            return XCTFail("Expected a configuration error outcome")
        }
    }

    func testWorkflowPresentationErrorDoesNotReplaceEarlierPurchaseOutcome() throws {
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = WorkflowPresenter { _ in true }
        let controller = try presenter.makePaywallViewController(for: presentation)
        let transaction = StoreTransaction(MockStoreTransaction())
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.startPresentation(presentation)
        presenter.paywallViewController(
            controller,
            didFinishPurchasingWith: TestData.customerInfo,
            transaction: transaction
        )
        controller.simulateWorkflowPresentationError(error)
        let execution = presenter.presentationDidDismiss()

        guard case let .completed(customerInfo)? = execution else {
            return XCTFail("Expected the purchase outcome to win")
        }
        XCTAssertEqual(customerInfo, TestData.customerInfo)
    }

    func testWorkflowPresentationErrorDoesNotReplaceEarlierRestoreOutcome() throws {
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = WorkflowPresenter { _ in true }
        let controller = try presenter.makePaywallViewController(for: presentation)
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.startPresentation(presentation)
        presenter.paywallViewController(controller, didFinishRestoringWith: TestData.customerInfo)
        controller.simulateWorkflowPresentationError(error)
        let execution = presenter.presentationDidDismiss()

        guard case let .completed(customerInfo)? = execution else {
            return XCTFail("Expected the restore outcome to win")
        }
        XCTAssertEqual(customerInfo, TestData.customerInfo)
    }

    func testWorkflowPresentationErrorDoesNotReplaceEarlierWebCheckoutOutcome() throws {
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = WorkflowPresenter { _ in true }
        let controller = try presenter.makePaywallViewController(for: presentation)
        let error = NSError(domain: ErrorCode.errorDomain, code: ErrorCode.configurationError.rawValue)

        try presenter.startPresentation(presentation)
        presenter.paywallViewControllerDidOpenWebCheckout(controller)
        controller.simulateWorkflowPresentationError(error)
        let execution = presenter.presentationDidDismiss()

        guard case .completed(nil)? = execution else {
            return XCTFail("Expected the web-checkout outcome to win")
        }
    }

    func testBackingOutReportsDismissedOutcomeAndBackedOut() throws {
        let presenter = WorkflowPresenter { _ in true }

        try presenter.startPresentation(Self.presentation())
        let execution = presenter.presentationDidDismiss(reason: .navigatedBack)

        guard case .backedOut? = execution else {
            return XCTFail("Expected a dismissed outcome")
        }
    }

    func testBackingOutKeepsAStagedErrorOutcome() throws {
        let presenter = WorkflowPresenter { _ in true }
        try presenter.startPresentation(Self.presentation())
        presenter.stage(.outcome(.failed))
        let execution = presenter.presentationDidDismiss(reason: .navigatedBack)

        guard case .backedOut? = execution else {
            return XCTFail("Expected a backed-out outcome")
        }
    }

    func testNavigatingBackAfterRestoreCompletesWithRestoredOutcome() throws {
        let presenter = WorkflowPresenter { _ in true }

        try presenter.startPresentation(Self.presentation())
        presenter.stage(.outcome(.completed(customerInfo: TestData.customerInfo)))
        let execution = presenter.presentationDidDismiss(reason: .navigatedBack)

        guard case let .completed(customerInfo)? = execution else {
            return XCTFail("Expected the restore outcome")
        }
        XCTAssertEqual(customerInfo, TestData.customerInfo)
    }

    func testInteractiveDismissalIsNotReportedAsBackingOut() throws {
        let presentation = Self.presentation()
        let presenter = WorkflowPresenter { _ in true }
        let controller = PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"])
        let presentationController = UIPresentationController(
            presentedViewController: controller,
            presenting: UIViewController()
        )

        try presenter.startPresentation(presentation)
        controller.presentationControllerWillDismiss(presentationController)
        let execution = presenter.presentationDidDismiss()

        guard case .completed(nil)? = execution else {
            return XCTFail("Expected a dismissed outcome")
        }
    }

    func testPurchaseCallbackPreservesCustomerInfo() throws {
        let presentation = Self.presentation()
        let presenter = WorkflowPresenter { _ in true }
        let transaction = StoreTransaction(MockStoreTransaction())

        try presenter.startPresentation(presentation)
        presenter.paywallViewController(
            PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"]),
            didFinishPurchasingWith: TestData.customerInfo,
            transaction: transaction
        )

        let execution = presenter.presentationDidDismiss()

        guard case let .completed(reportedCustomerInfo)? = execution else {
            return XCTFail("Expected a purchased outcome")
        }
        XCTAssertEqual(reportedCustomerInfo, TestData.customerInfo)
    }

    func testWebCheckoutCallbackStagesOutcomeUntilPresentationFinishesDismissing() throws {
        let presentation = Self.presentation()
        let presenter = WorkflowPresenter { _ in true }

        try presenter.startPresentation(presentation)
        presenter.paywallViewControllerDidOpenWebCheckout(
            PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"])
        )

        let execution = presenter.presentationDidDismiss()

        guard case .completed(nil)? = execution else {
            return XCTFail("Expected a reported web-checkout outcome")
        }
        XCTAssertNil(presenter.presentationDidDismiss())
    }

    func testPurchaseOutcomeReplacesEarlierWebCheckoutOutcome() throws {
        let presentation = Self.presentation()
        let presenter = WorkflowPresenter { _ in true }
        let controller = PaywallViewController(offering: presentation.workflow.offerings.all["offering-id"])
        let transaction = StoreTransaction(MockStoreTransaction())

        try presenter.startPresentation(presentation)
        presenter.paywallViewControllerDidOpenWebCheckout(controller)
        presenter.paywallViewController(
            controller,
            didFinishPurchasingWith: TestData.customerInfo,
            transaction: transaction
        )
        let execution = presenter.presentationDidDismiss()

        guard case let .completed(customerInfo)? = execution else {
            return XCTFail("Expected the later purchase outcome")
        }
        XCTAssertEqual(customerInfo, TestData.customerInfo)
    }

    #if canImport(UIKit) && !os(tvOS) && !os(watchOS)

    func testRejectedPresentationThrowsAndCleansStoredCall() {
        var shouldAcceptPresentation = false
        let presenter = WorkflowPresenter { _ in shouldAcceptPresentation }

        XCTAssertThrowsError(
            try presenter.startPresentation(Self.presentation())
        ) { error in
            guard case CheckpointError.presentationFailed = error else {
                return XCTFail("Expected presentationFailed, got \(error)")
            }
        }

        shouldAcceptPresentation = true
        XCTAssertNoThrow(try presenter.startPresentation(Self.presentation()))
    }

    func testPresentationSetupErrorIsPropagatedAndCleansStoredCall() {
        let expectedError = NSError(domain: "test", code: 42)
        var presentationError: Error? = expectedError
        let presenter = WorkflowPresenter { _ in
            if let presentationError {
                throw presentationError
            }
            return true
        }

        XCTAssertThrowsError(
            try presenter.startPresentation(Self.presentation())
        ) { error in
            XCTAssertEqual(error as NSError, expectedError)
        }

        presentationError = nil
        XCTAssertNoThrow(try presenter.startPresentation(Self.presentation()))
    }

    #endif

    func testCustomVariablesAreKeptWithThePresentedWorkflow() throws {
        let expected: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ]
        var receivedPresentation: WorkflowPresentationRequest?
        let presenter = WorkflowPresenter { presentation in
            receivedPresentation = presentation
            return true
        }

        try presenter.startPresentation(Self.presentation(customVariables: expected))

        XCTAssertEqual(receivedPresentation?.customVariables, expected)
    }

    func testCustomVariablesAreAppliedToThePaywallViewController() throws {
        let expected: [String: CustomVariableValue] = [
            "name": "Rick",
            "attempt": 2,
            "enabled": true
        ]
        let presenter = WorkflowPresenter { _ in true }

        let viewController = try presenter.makePaywallViewController(
            for: Self.renderablePresentation(customVariables: expected)
        )

        XCTAssertEqual(viewController.customVariables, expected)
    }

    func testCheckpointWorkflowPaywallDoesNotAcceptExitOffers() throws {
        let presentation = try Self.renderablePresentation(customVariables: [:])
        let presenter = WorkflowPresenter { _ in true }
        let viewController = try presenter.makePaywallViewController(for: presentation)
        let exitOffering = try XCTUnwrap(presentation.workflow.offerings.all["offering-id"])
        viewController.remoteConfigEnabledForTesting = true

        viewController.simulateWorkflowExitOfferUpdate(exitOffering)
        XCTAssertNil(viewController.exitOfferOfferingForTesting)

        viewController.simulateOfferingBasedExitOfferPrefetchResult(exitOffering)
        XCTAssertNil(viewController.exitOfferOfferingForTesting)
    }

    private static func presentation(
        customVariables: [String: CustomVariableValue] = [:]
    ) -> WorkflowPresentationRequest {
        return WorkflowPresentationRequest(
            workflow: self.workflow(),
            customVariables: customVariables
        )
    }

    private static func renderablePresentation(
        customVariables: [String: CustomVariableValue]
    ) throws -> WorkflowPresentationRequest {
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
        return WorkflowPresentationRequest(
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

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class DefaultPaywallPresenterTests: TestCase {

    func testNavigatingBackWithoutPurchaseOrRestoreReportsNavigatedBack() {
        let presenter = DefaultPaywallPresenter()

        XCTAssertEqual(presenter.presentationResult(dismissalReason: .navigatedBack), .navigatedBack)
    }

    func testPurchaseTakesPrecedenceOverNavigatingBack() {
        let presenter = DefaultPaywallPresenter()
        let controller = self.makePaywallViewController()
        let delegate: PaywallViewControllerDelegate = presenter

        delegate.paywallViewController?(
            controller,
            didFinishPurchasingWith: TestData.customerInfo,
            transaction: nil
        )

        XCTAssertEqual(presenter.presentationResult(dismissalReason: .navigatedBack), .continued)
    }

    func testRestoreTakesPrecedenceOverNavigatingBack() {
        let presenter = DefaultPaywallPresenter()
        let controller = self.makePaywallViewController()
        let delegate: PaywallViewControllerDelegate = presenter

        delegate.paywallViewController?(controller, didFinishRestoringWith: TestData.customerInfo)

        XCTAssertEqual(presenter.presentationResult(dismissalReason: .navigatedBack), .continued)
    }

    func testDefaultCheckpointPaywallDoesNotAcceptExitOffers() throws {
        let offering = Offering(
            identifier: "offering-id",
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let controller = makeDefaultCheckpointPaywallViewController(
            params: .init(checkpointIdentifier: "checkpoint", customVariables: [:], offering: offering)
        )
        controller.remoteConfigEnabledForTesting = true

        controller.simulateWorkflowExitOfferUpdate(offering)
        XCTAssertNil(controller.exitOfferOfferingForTesting)

        controller.simulateOfferingBasedExitOfferPrefetchResult(offering)
        XCTAssertNil(controller.exitOfferOfferingForTesting)
    }
    private func makePaywallViewController() -> PaywallViewController {
        return PaywallViewController(
            offering: Offering(
                identifier: "offering-id",
                serverDescription: "Test offering",
                availablePackages: [],
                webCheckoutUrl: nil
            )
        )
    }

}

#endif
