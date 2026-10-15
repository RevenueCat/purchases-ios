//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultErrorPresenterTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class DefaultErrorPresenterTests: TestCase {

    func testPresentCreatesAlertWithoutCompletingFlow() {
        let harness = Harness()

        harness.presenter.present(params: Self.params(), completion: harness.completion)

        XCTAssertEqual(harness.presentedTitles, ["Error"])
        XCTAssertEqual(harness.presentedMessages, ["boom"])
        XCTAssertEqual(harness.completionCount, 0)
    }

    func testPurchaseErrorUsesExistingPaywallMessageFormatting() {
        let harness = Harness()
        let error = ErrorCode.storeProblemError as NSError
        let expectedMessage = LocalizedAlertError.Content(error: error).message

        harness.presenter.present(
            params: .init(
                checkpointIdentifier: "test_checkpoint",
                error: error,
                customVariables: [:],
                kind: .flowActionFailed
            ),
            completion: harness.completion
        )

        XCTAssertEqual(harness.presentedMessages.first, expectedMessage)
    }

    func testRecoverableErrorAcknowledgementCompletes() {
        let harness = Harness()
        harness.presenter.present(
            params: Self.params(kind: .flowActionFailed),
            completion: harness.completion
        )

        harness.acknowledgement?()

        XCTAssertEqual(harness.completionCount, 1)
    }

    func testTerminalErrorAcknowledgementContinues() {
        let harness = Harness()
        harness.presenter.present(
            params: Self.params(kind: .flowCouldNotBeShown),
            completion: harness.completion
        )

        harness.acknowledgement?()

        XCTAssertEqual(harness.completionCount, 1)
    }

    func testOnlyFirstAcknowledgementCounts() {
        let harness = Harness()
        harness.presenter.present(params: Self.params(), completion: harness.completion)
        let acknowledgement = harness.acknowledgement

        acknowledgement?()
        acknowledgement?()

        XCTAssertEqual(harness.completionCount, 1)
    }

    func testNewErrorCompletesEarlierPresentation() {
        let harness = Harness()
        var secondCompletionCount = 0
        harness.presenter.present(params: Self.params(), completion: harness.completion)
        let staleAcknowledgement = harness.acknowledgement

        harness.presenter.present(
            params: Self.params(kind: .flowCouldNotBeShown),
            completion: .init { secondCompletionCount += 1 }
        )

        XCTAssertEqual(harness.completionCount, 1)
        staleAcknowledgement?()
        XCTAssertEqual(harness.completionCount, 1)
        harness.acknowledgement?()
        XCTAssertEqual(secondCompletionCount, 1)
    }

    func testNewestErrorWinsWhilePreviousAlertIsDismissing() {
        let harness = Harness(defersDismissal: true)
        var secondCompletionCount = 0
        var thirdCompletionCount = 0
        harness.presenter.present(
            params: Self.params(message: "first"),
            completion: harness.completion
        )

        harness.presenter.present(
            params: Self.params(message: "second"),
            completion: .init { secondCompletionCount += 1 }
        )
        harness.presenter.present(
            params: Self.params(message: "third", kind: .flowCouldNotBeShown),
            completion: .init { thirdCompletionCount += 1 }
        )

        XCTAssertEqual(secondCompletionCount, 1)
        XCTAssertEqual(harness.presentedMessages, ["first"])

        harness.completeNextDismissal()

        XCTAssertEqual(harness.completionCount, 1)
        XCTAssertEqual(harness.presentedMessages, ["first", "third"])
        XCTAssertEqual(thirdCompletionCount, 0)

        harness.acknowledgement?()
        harness.completeNextDismissal()

        XCTAssertEqual(harness.completionCount, 1)
        XCTAssertEqual(secondCompletionCount, 1)
        XCTAssertEqual(thirdCompletionCount, 1)
    }

    func testMissingPresentationContextDoesNotLeaveFlowWaiting() {
        var recoverableCompletionCount = 0
        var terminalCompletionCount = 0
        let presenter = DefaultErrorPresenter(presentationContextProvider: { nil })

        presenter.present(
            params: Self.params(kind: .flowActionFailed),
            completion: .init { recoverableCompletionCount += 1 }
        )
        presenter.present(
            params: Self.params(kind: .flowCouldNotBeShown),
            completion: .init { terminalCompletionCount += 1 }
        )

        XCTAssertEqual(recoverableCompletionCount, 1)
        XCTAssertEqual(terminalCompletionCount, 1)
    }

    private static func params(
        message: String = "boom",
        kind: CheckpointFailureKind = .flowActionFailed
    ) -> ErrorPresentationParams {
        return .init(
            checkpointIdentifier: "test_checkpoint",
            error: NSError(
                domain: "DefaultErrorPresenterTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ),
            customVariables: [:],
            kind: kind
        )
    }

    @MainActor
    private final class Harness {
        private let host = UIViewController()
        private let defersDismissal: Bool
        var presentedTitles: [String] = []
        var presentedMessages: [String] = []
        var acknowledgement: (@MainActor () -> Void)?
        var completionCount = 0
        var deferredAlerts: [DeferredDismissalViewController] = []

        init(defersDismissal: Bool = false) {
            self.defersDismissal = defersDismissal
        }

        lazy var presenter = DefaultErrorPresenter(
            presentationContextProvider: { [host] in host },
            alertFactory: { [weak self] _, title, message, acknowledgement in
                self?.presentedTitles.append(title)
                self?.presentedMessages.append(message)
                self?.acknowledgement = acknowledgement

                if self?.defersDismissal == true {
                    let alert = DeferredDismissalViewController()
                    self?.deferredAlerts.append(alert)
                    return alert
                }

                return UIViewController()
            }
        )

        lazy var completion = ErrorPresentationCompletion { [weak self] in
            self?.completionCount += 1
        }

        func completeNextDismissal() {
            self.deferredAlerts.first(where: { $0.hasPendingDismissal })?.completeDismissal()
        }
    }

    @MainActor
    private final class DeferredDismissalViewController: UIViewController {
        private let presentingController = UIViewController()
        private var dismissalCompletion: (() -> Void)?

        var hasPendingDismissal: Bool {
            return self.dismissalCompletion != nil
        }

        override var presentingViewController: UIViewController? {
            return self.presentingController
        }

        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            self.dismissalCompletion = completion
        }

        func completeDismissal() {
            let completion = self.dismissalCompletion
            self.dismissalCompletion = nil
            completion?()
        }
    }

}
#endif
