//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EmbeddedCheckpointPresentationTests.swift
//
//  Created by Cesar de la Vega.
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

/// A parent view controller that is on screen, which is what an embedded checkpoint requires.
@MainActor
@available(iOS 15.0, macOS 12.0, *)
final class EmbeddedParentFixture {

    let window: UIWindow
    let parent: UIViewController

    init(inWindow: Bool = true) {
        self.parent = UIViewController()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        if inWindow {
            self.window.rootViewController = self.parent
            self.window.makeKeyAndVisible()
            self.parent.loadViewIfNeeded()
        }
    }

    var embeddedController: PaywallViewController? {
        return self.parent.children.compactMap { $0 as? PaywallViewController }.first
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, *)
final class EmbeddedCheckpointPresentationTests: TestCase {

    private var fixture: EmbeddedParentFixture!

    override func setUp() {
        super.setUp()
        self.fixture = EmbeddedParentFixture()
    }

    override func tearDown() {
        self.fixture = nil
        super.tearDown()
    }

    func testOfferingEmbedsControllerInParentAndFinishesOnlyOnRemoval() throws {
        let presenter = DefaultPaywallPresenter(presentationContextProvider: { nil })
        let execution = EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {})
        var results: [PaywallPresentationResult] = []

        presenter.present(params: .init(
            checkpointIdentifier: "test", customVariables: ["name": "Ada"],
            offering: Self.offering(), execution: execution
        ), completion: { results.append($0) })

        let controller = try XCTUnwrap(self.fixture.embeddedController)
        XCTAssertTrue(controller.parent === self.fixture.parent)
        XCTAssertTrue(controller.view.superview === self.fixture.parent.view)
        XCTAssertTrue(self.fixture.parent.view.subviews.last === controller.view)
        XCTAssertTrue(controller.delegate === presenter)
        XCTAssertEqual(controller.customVariables, ["name": "Ada"])
        let configuration = try XCTUnwrap(
            Mirror(reflecting: controller).descendant("configuration") as? PaywallViewConfiguration
        )
        XCTAssertFalse(configuration.displaysPurchaseAndRestoreErrors)
        self.fixture.parent.view.layoutIfNeeded()
        XCTAssertEqual(controller.view.frame, self.fixture.parent.view.bounds)

        // A covering modal makes the child disappear without finishing the checkpoint.
        controller.viewDidDisappear(false)
        XCTAssertTrue(results.isEmpty)
        XCTAssertTrue(controller.parent === self.fixture.parent)

        controller.continueAfterCheckpointError()
        controller.continueAfterCheckpointError()
        XCTAssertEqual(results, [.closed])
        XCTAssertNil(controller.parent)
        XCTAssertNil(controller.view.superview)
        XCTAssertNil(controller.delegate)
        XCTAssertTrue(self.fixture.parent.children.isEmpty)
    }

    func testOfferingFailsCleanlyWhenParentIsNotOnScreen() {
        let offscreen = EmbeddedParentFixture(inWindow: false)
        let presenter = DefaultPaywallPresenter(presentationContextProvider: { self.fixture.parent })
        let execution = EmbeddedCheckpointExecution(parentViewController: offscreen.parent, onFinished: {})
        var results: [PaywallPresentationResult] = []
        var errors: [CheckpointFailureKind] = []

        presenter.present(params: .init(
            checkpointIdentifier: "test", offering: Self.offering(),
            errorPresentationHandler: { params, completion in
                errors.append(params.kind)
                completion.complete()
            },
            execution: execution
        ), completion: { results.append($0) })

        XCTAssertEqual(results, [.failed])
        XCTAssertEqual(errors, [.flowCouldNotBeShown])
        XCTAssertTrue(offscreen.parent.children.isEmpty)
        // No modal fallback through the presentation context.
        XCTAssertNil(self.fixture.parent.presentedViewController)
        XCTAssertTrue(self.fixture.parent.children.isEmpty)

        // The presenter is reusable afterwards.
        presenter.present(params: .init(
            checkpointIdentifier: "test", offering: Self.offering(),
            execution: EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {})
        ), completion: { results.append($0) })
        XCTAssertNotNil(self.fixture.embeddedController)
        XCTAssertEqual(results, [.failed])
    }

    func testOfferingFailsWhenParentWasReleasedBeforePresentation() {
        let presenter = DefaultPaywallPresenter(presentationContextProvider: { self.fixture.parent })
        var released: UIViewController? = UIViewController()
        let execution = EmbeddedCheckpointExecution(parentViewController: released, onFinished: {})
        released = nil
        var results: [PaywallPresentationResult] = []

        presenter.present(params: .init(checkpointIdentifier: "test", offering: Self.offering(),
                                        execution: execution),
                          completion: { results.append($0) })

        XCTAssertEqual(results, [.failed])
        XCTAssertNil(self.fixture.parent.presentedViewController)
    }

    func testPurchaseOutcomeSurvivesEmbeddedRemoval() throws {
        let presenter = DefaultPaywallPresenter(presentationContextProvider: { nil })
        let execution = EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {})
        var result: PaywallPresentationResult?
        presenter.present(params: .init(checkpointIdentifier: "test", offering: Self.offering(),
                                        execution: execution),
                          completion: { result = $0 })
        let controller = try XCTUnwrap(self.fixture.embeddedController)
        presenter.paywallViewController(controller, didFinishPurchasingWith: TestData.customerInfo, transaction: nil)
        XCTAssertNil(result)
        controller.continueAfterCheckpointError()

        XCTAssertEqual(result, .continued)
        XCTAssertTrue(self.fixture.parent.children.isEmpty)
    }

    func testOldControllerCannotRemoveNextEmbeddedOffering() throws {
        let presenter = DefaultPaywallPresenter(presentationContextProvider: { nil })
        var errorCount = 0
        func params() -> PaywallPresentationParams {
            return .init(
                checkpointIdentifier: "test", offering: Self.offering(),
                errorPresentationHandler: { _, completion in errorCount += 1; completion.complete() },
                execution: EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {})
            )
        }
        presenter.present(params: params(), completion: { _ in })
        let oldController = try XCTUnwrap(self.fixture.embeddedController)
        oldController.continueAfterCheckpointError()
        presenter.present(params: params(), completion: { _ in })
        let newController = try XCTUnwrap(self.fixture.embeddedController)
        XCTAssertFalse(newController === oldController)

        oldController.continueAfterCheckpointError()
        oldController.simulateWorkflowPresentationError(NSError(domain: "test", code: 1), behavior: .endFlow)

        XCTAssertEqual(errorCount, 0)
        XCTAssertTrue(newController.parent === self.fixture.parent)
        newController.continueAfterCheckpointError()
    }

    func testCancelRemovesEmbeddedChildAndReportsFailureWithoutSynchronizing() throws {
        let presenter = DefaultPaywallPresenter(presentationContextProvider: { nil })
        var finishes = 0
        let execution = EmbeddedCheckpointExecution(parentViewController: self.fixture.parent,
                                                    onFinished: { finishes += 1 })
        var results: [PaywallPresentationResult] = []
        presenter.present(params: .init(checkpointIdentifier: "test", offering: Self.offering(),
                                        execution: execution),
                          completion: { results.append($0) })
        let controller = try XCTUnwrap(self.fixture.embeddedController)

        execution.cancel()
        execution.cancel()

        XCTAssertTrue(self.fixture.parent.children.isEmpty)
        XCTAssertNil(controller.parent)
        XCTAssertEqual(results, [.closed])
        XCTAssertEqual(finishes, 1)
    }

    static func workflow() throws -> ResolvedCheckpointWorkflow {
        let configJSON = """
        {"base":{"stack":{"type":"stack","components":[],
        "dimension":{"type":"vertical","alignment":"center","distribution":"center"},
        "size":{"width":{"type":"fill"},"height":{"type":"fill"}},
        "padding":{"top":0,"bottom":0,"leading":0,"trailing":0},
        "margin":{"top":0,"bottom":0,"leading":0,"trailing":0}},
        "background":{"type":"color","value":{"light":{"type":"hex","value":"#FFFFFF"}}}}}
        """
        let config = try JSONDecoder.default.decode(PaywallComponentsData.ComponentsConfig.self,
                                                    from: Data(configJSON.utf8))
        let screen = WorkflowScreen(name: nil, templateName: "test",
                                    assetBaseURL: try XCTUnwrap(URL(string: "https://assets.revenuecat.com")),
                                    componentsConfig: config, componentsLocalizations: [:],
                                    defaultLocale: "en_US", offeringIdentifier: "offering-id")
        return ResolvedCheckpointWorkflow(workflow: PublishedWorkflow(
            id: "workflow-id", displayName: "Test", initialStepId: "step-id", singleStepFallbackId: nil,
            steps: ["step-id": WorkflowStep(id: "step-id", type: "screen", screenId: "screen-id")],
            screens: ["screen-id": screen]
        ), uiConfig: .empty, offerings: .preview(offerings: [Self.offering()]))
    }

    static func offering() -> Offering {
        Offering(identifier: "offering-id", serverDescription: "Test", availablePackages: [], webCheckoutUrl: nil)
    }

}

#endif
