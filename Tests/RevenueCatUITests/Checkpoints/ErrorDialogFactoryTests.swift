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
        var receivedOutcome: ErrorDialogFactoryOutcome?
        var callCount = 0
        let completion = ErrorDialogFactoryCompletion { outcome in
            receivedOutcome = outcome
            callCount += 1
        }
        let dialog = CheckpointErrorDialog(message: "Message", buttonTitle: "OK")

        completion.complete(with: .show(dialog))

        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(receivedOutcome, .show(CheckpointErrorDialog(message: "Message", buttonTitle: "OK")))
    }

    func testCompletionInvokesHandlerWithUseDefault() {
        var receivedOutcome: ErrorDialogFactoryOutcome?
        var callCount = 0
        let completion = ErrorDialogFactoryCompletion { outcome in
            receivedOutcome = outcome
            callCount += 1
        }

        completion.complete(with: .useDefault)

        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(receivedOutcome, .useDefault)
    }

    func testSecondCompletionCallIsIgnored() {
        var callCount = 0
        let completion = ErrorDialogFactoryCompletion { _ in callCount += 1 }

        completion.complete(with: .useDefault)
        completion.complete(with: .useDefault)
        completion.complete(with: .show(CheckpointErrorDialog(message: "Second", buttonTitle: "OK")))

        XCTAssertEqual(callCount, 1)
    }

    func testSuppressCompletesWithoutCreatingAPresenter() {
        var factoryCompletion: ErrorDialogFactoryCompletion?
        var completionCount = 0
        var presenterCount = 0
        let handler = makeErrorDialogFactoryHandler(
            factory: { _, completion in factoryCompletion = completion },
            makePresenter: { _ in
                presenterCount += 1
                return MockErrorPresenter()
            }
        )

        handler(Self.errorPresentationParams, .init { completionCount += 1 })
        XCTAssertEqual(completionCount, 0)
        XCTAssertEqual(presenterCount, 0)

        factoryCompletion?.complete(with: .suppress)
        factoryCompletion?.complete(with: .useDefault)

        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(presenterCount, 0)
    }

    func testShowAndUseDefaultSelectContentAndWaitForAcknowledgement() {
        let dialog = CheckpointErrorDialog(message: "Custom", buttonTitle: "Continue")
        let cases: [(ErrorDialogFactoryOutcome, CheckpointErrorDialog?)] = [
            (.show(dialog), dialog),
            (.useDefault, nil)
        ]
        for (outcome, expectedDialog) in cases {
            var selectedDialogs: [CheckpointErrorDialog?] = []
            let presenter = DeferredErrorPresenter()
            var completionCount = 0
            let handler = makeErrorDialogFactoryHandler(
                factory: { _, completion in completion.complete(with: outcome) },
                makePresenter: { content in
                    selectedDialogs.append(content)
                    return presenter
                }
            )

            handler(Self.errorPresentationParams, .init { completionCount += 1 })

            XCTAssertEqual(selectedDialogs, [expectedDialog])
            XCTAssertEqual(completionCount, 0)

            presenter.completion?.complete()

            XCTAssertEqual(completionCount, 1)
        }
    }

    func testFactoryPresenterLivesUntilPresentationCompletes() {
        weak var weakPresenter: DeferredErrorPresenter?
        var completionCount = 0
        let handler = makeErrorDialogFactoryHandler(
            factory: { _, completion in completion.complete(with: .useDefault) },
            makePresenter: { _ in
                let presenter = DeferredErrorPresenter()
                weakPresenter = presenter
                return presenter
            }
        )

        handler(Self.errorPresentationParams, .init { completionCount += 1 })
        let acknowledgement = weakPresenter?.completion

        XCTAssertNotNil(weakPresenter)
        XCTAssertEqual(completionCount, 0)

        acknowledgement?.complete()
        acknowledgement?.complete()

        XCTAssertEqual(completionCount, 1)
        XCTAssertNil(weakPresenter)
    }

    // MARK: - CheckpointCallParams factory parameter

    func testCheckpointCallParamsStoresFactory() {
        var factoryCalled = false
        let params = CheckpointCallParams(
            errorDialogFactory: { _, completion in
                factoryCalled = true
                completion.complete(with: .useDefault)
            }
        )

        XCTAssertNotNil(params.localErrorDialogFactory)
        XCTAssertNil(params.localErrorPresentationHandler)
        params.localErrorDialogFactory?(Self.errorPresentationParams, ErrorDialogFactoryCompletion { _ in })
        XCTAssertTrue(factoryCalled)
    }

    func testCheckpointCallParamsWithNoFactoryHasNilFactory() {
        let params = CheckpointCallParams(errorDialogFactory: nil)
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
                completion.complete(with: .useDefault)
            }),
            defaultHandler: {
                return { _, _ in defaultCallCount += 1 }
            },
            dialogPresenterFactory: { _ in MockErrorPresenter() }
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
            defaultHandler: { return { _, _ in } },
            dialogPresenterFactory: { _ in MockErrorPresenter() }
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
                completion.complete(with: .useDefault)
            }),
            defaultHandler: { return { _, _ in } },
            dialogPresenterFactory: { _ in MockErrorPresenter() }
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
        weak var firstPresenter: DeferredErrorPresenter?
        let secondStarted = self.expectation(description: "Second error presented")

        let firstHandler = manager.errorPresentationHandler(
            for: .init(errorDialogFactory: { params, completion in
                presentationOrder.append("factory-\(params.checkpointIdentifier)")
                firstFactoryCompletion = completion
            }),
            defaultHandler: { XCTFail("Default not expected"); return { _, _ in } },
            dialogPresenterFactory: { _ in
                let presenter = DeferredErrorPresenter()
                firstPresenter = presenter
                return presenter
            }
        )
        let secondHandler = manager.errorPresentationHandler(
            for: .init(errorDialogFactory: { params, completion in
                presentationOrder.append("factory-\(params.checkpointIdentifier)")
                completion.complete(with: .useDefault)
                secondStarted.fulfill()
            }),
            defaultHandler: { XCTFail("Default not expected"); return { _, _ in } },
            dialogPresenterFactory: { _ in MockErrorPresenter() }
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

        XCTAssertEqual(presentationOrder, ["factory-first"])

        firstFactoryCompletion?.complete(with: .useDefault)
        XCTAssertEqual(presentationOrder, ["factory-first"])

        firstPresenter?.completion?.complete()

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
        completion.complete()
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class DeferredErrorPresenter: ErrorPresenter {

    private(set) var completion: ErrorPresentationCompletion?

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        self.completion = completion
    }

}
