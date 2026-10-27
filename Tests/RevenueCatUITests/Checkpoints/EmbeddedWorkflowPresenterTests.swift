//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EmbeddedWorkflowPresenterTests.swift
//
//  Created by Cesar de la Vega.
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@MainActor
@available(iOS 15.0, macOS 12.0, *)
final class EmbeddedWorkflowPresenterTests: TestCase {

    private var fixture: EmbeddedParentFixture!

    override func setUp() {
        super.setUp()
        self.fixture = EmbeddedParentFixture()
    }

    override func tearDown() {
        self.fixture = nil
        super.tearDown()
    }

    func testEmbeddedWorkflowAttachesToParentAndReportsBackOutOnRemoval() async throws {
        let presenter = WorkflowPresenter()
        let execution = EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {})
        var completed = false
        let task = Task {
            defer { completed = true }
            return try await presenter.present(try self.request(execution: execution, customVariables: ["name": "Ada"]))
        }
        await self.waitForEmbeddedController()

        let controller = try XCTUnwrap(self.fixture.embeddedController)
        XCTAssertTrue(controller.parent === self.fixture.parent)
        XCTAssertTrue(controller.delegate === presenter)
        XCTAssertEqual(controller.customVariables, ["name": "Ada"])
        XCTAssertNotNil(controller.workflowContextForTesting)
        let configuration = try XCTUnwrap(
            Mirror(reflecting: controller).descendant("configuration") as? PaywallViewConfiguration
        )
        XCTAssertFalse(configuration.displaysPurchaseAndRestoreErrors)
        // Still owned by the parent and still running after a covering modal hides it.
        XCTAssertNil(self.fixture.parent.presentedViewController)
        controller.viewDidDisappear(false)
        await Task.yield()
        XCTAssertFalse(completed)
        XCTAssertTrue(controller.parent === self.fixture.parent)

        presenter.stage(.dismissalReason(.navigatedBack))
        controller.continueAfterCheckpointError()
        controller.continueAfterCheckpointError()

        XCTAssertTrue(self.fixture.parent.children.isEmpty)
        guard case .backedOut = try await task.value else { return XCTFail("Expected native back outcome") }
        XCTAssertNil(controller.delegate)
    }

    func testEmbeddedWorkflowFailsWithoutModalFallbackWhenParentIsOffScreen() async throws {
        let offscreen = EmbeddedParentFixture(inWindow: false)
        let presenter = WorkflowPresenter()
        let execution = EmbeddedCheckpointExecution(parentViewController: offscreen.parent, onFinished: {})

        do {
            _ = try await presenter.present(try self.request(execution: execution))
            XCTFail("Expected presentation failure")
        } catch {
            guard case CheckpointError.presentationFailed = error else {
                return XCTFail("Unexpected error \(error)")
            }
        }

        XCTAssertTrue(offscreen.parent.children.isEmpty)
        XCTAssertNil(self.fixture.parent.presentedViewController)

        // The presenter is reusable with a valid parent afterwards.
        let retry = EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {})
        let task = Task { try await presenter.present(try self.request(execution: retry)) }
        await self.waitForEmbeddedController()
        try XCTUnwrap(self.fixture.embeddedController).continueAfterCheckpointError()
        _ = try await task.value
    }

    func testOldControllerCannotRemoveNextEmbeddedWorkflow() async throws {
        let presenter = WorkflowPresenter()
        var errorCount = 0
        let errorHandler: ErrorPresentationHandler = { _, completion in errorCount += 1; completion.complete() }
        let first = Task {
            try await presenter.present(try self.request(
                execution: EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {}),
                errorHandler: errorHandler
            ))
        }
        await self.waitForEmbeddedController()
        let oldController = try XCTUnwrap(self.fixture.embeddedController)
        oldController.continueAfterCheckpointError()
        _ = try await first.value

        let second = Task {
            try await presenter.present(try self.request(
                execution: EmbeddedCheckpointExecution(parentViewController: self.fixture.parent, onFinished: {}),
                errorHandler: errorHandler
            ))
        }
        await self.waitForEmbeddedController()
        let newController = try XCTUnwrap(self.fixture.embeddedController)
        XCTAssertFalse(newController === oldController)

        oldController.continueAfterCheckpointError()
        oldController.simulateWorkflowPresentationError(NSError(domain: "test", code: 1), behavior: .endFlow)

        XCTAssertEqual(errorCount, 0)
        XCTAssertTrue(newController.parent === self.fixture.parent)
        newController.continueAfterCheckpointError()
        _ = try await second.value
    }

    private func request(
        execution: EmbeddedCheckpointExecution,
        customVariables: [String: CustomVariableValue] = [:],
        errorHandler: @escaping ErrorPresentationHandler = { _, completion in completion.complete() }
    ) throws -> WorkflowPresentationRequest {
        return WorkflowPresentationRequest(
            checkpointIdentifier: "test",
            workflow: try EmbeddedCheckpointPresentationTests.workflow(),
            customVariables: customVariables,
            presentationMode: .modalFullScreen,
            initialActiveEntitlementIdentifiers: [],
            execution: execution,
            errorPresentationHandler: errorHandler
        )
    }

    private func waitForEmbeddedController() async {
        let deadline = Date().addingTimeInterval(2)
        while self.fixture.embeddedController == nil, Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

}

#endif
