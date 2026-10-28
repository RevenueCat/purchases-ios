//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorDialogFactoryTests.swift
//
//  Created by Cesar de la Vega.
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ErrorDialogFactoryTests: TestCase {

    // MARK: - ErrorDialogFactoryCompletion

    func testCompletionInvokesHandlerWithProvidedDialog() {
        var receivedDialog: CheckpointErrorDialog?
        var callCount = 0
        let completion = ErrorDialogFactoryCompletion(timeoutInterval: 60) { dialog in
            receivedDialog = dialog
            callCount += 1
        }
        let dialog = CheckpointErrorDialog(message: "Message", buttonTitle: "OK")

        completion.complete(with: dialog)

        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(receivedDialog?.message, "Message")
        XCTAssertEqual(receivedDialog?.buttonTitle, "OK")
    }

    func testCompletionInvokesHandlerWithNilDialog() {
        var receivedDialog: CheckpointErrorDialog?
        var callCount = 0
        let completion = ErrorDialogFactoryCompletion(timeoutInterval: 60) { dialog in
            receivedDialog = dialog
            callCount += 1
        }

        completion.complete(with: nil)

        XCTAssertEqual(callCount, 1)
        XCTAssertNil(receivedDialog)
    }

    func testSecondCompletionCallIsIgnored() {
        var callCount = 0
        let completion = ErrorDialogFactoryCompletion(timeoutInterval: 60) { _ in callCount += 1 }

        completion.complete(with: nil)
        completion.complete(with: nil)
        completion.complete(with: CheckpointErrorDialog(message: "Second", buttonTitle: "OK"))

        XCTAssertEqual(callCount, 1)
    }

    func testTimeoutFiresWithNilAndWarningIsLogged() async {
        let completed = self.expectation(description: "Timeout fires")
        var receivedDialog: CheckpointErrorDialog?? = .none
        // Keep a strong reference so the timeout task can fire via [weak self].
        let completion = ErrorDialogFactoryCompletion(timeoutInterval: 0.05) { dialog in
            receivedDialog = .some(dialog)
            completed.fulfill()
        }

        await self.fulfillment(of: [completed], timeout: 2)
        XCTAssertEqual(receivedDialog, .some(nil))
        self.logger.verifyMessageWasLogged(
            "ErrorDialogFactory timed out",
            level: .warn
        )
        _ = completion // Keep alive until the assertion above
    }

    func testCompletionAfterTimeoutIsIgnored() async {
        let timedOut = self.expectation(description: "Timeout fires")
        var callCount = 0
        let completion = ErrorDialogFactoryCompletion(timeoutInterval: 0.05) { _ in
            callCount += 1
            timedOut.fulfill()
        }

        await self.fulfillment(of: [timedOut], timeout: 2)
        XCTAssertEqual(callCount, 1)

        // Late call after timeout
        completion.complete(with: CheckpointErrorDialog(message: "Late", buttonTitle: "OK"))
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - CheckpointCallParams factory parameter

    func testCheckpointCallParamsStoresFactory() {
        var factoryCalled = false
        let params = CheckpointCallParams(
            errorDialogFactory: { _, _ in factoryCalled = true }
        )

        XCTAssertNotNil(params.localErrorDialogFactory)
        XCTAssertNil(params.localErrorPresentationHandler)
        params.localErrorDialogFactory?(Self.errorPresentationParams, ErrorDialogFactoryCompletion { _ in })
        XCTAssertTrue(factoryCalled)
    }

    func testCheckpointCallParamsWithNoFactoryHasNilFactory() {
        let params = CheckpointCallParams()
        XCTAssertNil(params.localErrorDialogFactory)
    }

    // MARK: - CheckpointsManager precedence

    func testFactoryIsUsedWhenNoLocalPresenterIsSet() {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        var factoryCallCount = 0
        var defaultCallCount = 0

        let handler = manager.errorPresentationHandler(
            for: .init(errorDialogFactory: { _, completion in
                factoryCallCount += 1
                completion.complete(with: nil)
            }),
            defaultHandler: {
                return { _, _ in defaultCallCount += 1 }
            }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(factoryCallCount, 1)
        XCTAssertEqual(defaultCallCount, 0)
    }

    func testLocalPresenterTakesPrecedenceOverFactory() {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        var presenterCallCount = 0
        var factoryCallCount = 0

        let handler = manager.errorPresentationHandler(
            for: .init(
                errorPresenter: { _, _ in presenterCallCount += 1 },
                errorDialogFactory: { _, _ in factoryCallCount += 1 }
            ),
            defaultHandler: { return { _, _ in } }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(presenterCallCount, 1)
        XCTAssertEqual(factoryCallCount, 0)
    }

    func testFactoryTakesPrecedenceOverGlobalPresenter() {
        let globalPresenter = MockErrorPresenter()
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        manager.errorPresenter = globalPresenter
        var factoryCallCount = 0

        // Precedence: per-call errorPresenter > per-call errorDialogFactory > global errorPresenter > default.
        let handler = manager.errorPresentationHandler(
            for: .init(errorDialogFactory: { _, completion in
                factoryCallCount += 1
                completion.complete(with: nil)
            }),
            defaultHandler: { return { _, _ in } }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(factoryCallCount, 1)
        XCTAssertEqual(globalPresenter.callCount, 0)
    }

    func testDefaultPresenterUsedWhenNoFactoryOrPresenterIsSet() {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        var defaultCallCount = 0

        let handler = manager.errorPresentationHandler(
            for: .init(),
            defaultHandler: { return { _, _ in defaultCallCount += 1 } }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(defaultCallCount, 1)
    }

    // MARK: - Several errors in order

    func testFactoryHandlerFlowsThroughExistingPresentationQueue() async {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        var presentationOrder: [String] = []
        var firstFactoryCompletion: ErrorDialogFactoryCompletion?
        let secondStarted = self.expectation(description: "Second error presented")

        let firstHandler = manager.errorPresentationHandler(
            for: .init(errorDialogFactory: { params, completion in
                presentationOrder.append("factory-\(params.checkpointIdentifier)")
                firstFactoryCompletion = completion
            }),
            defaultHandler: { XCTFail("Default not expected"); return { _, _ in } }
        )
        let secondHandler = manager.errorPresentationHandler(
            for: .init(errorDialogFactory: { params, completion in
                presentationOrder.append("factory-\(params.checkpointIdentifier)")
                completion.complete(with: nil)
                secondStarted.fulfill()
            }),
            defaultHandler: { XCTFail("Default not expected"); return { _, _ in } }
        )

        let firstParams = ErrorPresentationParams(
            checkpointIdentifier: "first",
            error: NSError(domain: "test", code: 1),
            customVariables: [:],
            kind: .flowActionFailed
        )
        let secondParams = ErrorPresentationParams(
            checkpointIdentifier: "second",
            error: NSError(domain: "test", code: 2),
            customVariables: [:],
            kind: .flowCouldNotBeShown
        )

        firstHandler(firstParams, Self.errorPresentationCompletion)
        secondHandler(secondParams, Self.errorPresentationCompletion)

        // Only first should be presenting; second waits in the queue.
        XCTAssertEqual(presentationOrder, ["factory-first"])

        firstFactoryCompletion?.complete(with: nil)

        await self.fulfillment(of: [secondStarted], timeout: 1)
        XCTAssertEqual(presentationOrder, ["factory-first", "factory-second"])
    }

    // MARK: - No factory: default behaviour is untouched

    func testNilFactoryLeavesDefaultBehaviourUntouched() {
        let manager = CheckpointsManager { _, _ in .noAction(.unknownCheckpoint) }
        var defaultCallCount = 0

        let handler = manager.errorPresentationHandler(
            for: .init(errorDialogFactory: nil),
            defaultHandler: { return { _, _ in defaultCallCount += 1 } }
        )
        handler(Self.errorPresentationParams, Self.errorPresentationCompletion)

        XCTAssertEqual(defaultCallCount, 1)
    }

    // MARK: - CheckpointErrorDialog fields

    func testCheckpointErrorDialogStoredFields() {
        let dialog = CheckpointErrorDialog(message: "Custom Message", buttonTitle: "Got it")

        XCTAssertEqual(dialog.message, "Custom Message")
        XCTAssertEqual(dialog.buttonTitle, "Got it")
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ErrorDialogFactoryTests {

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
            customerInfoProvider: {
                throw NSError(domain: "test", code: 0)
            }
        )
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
