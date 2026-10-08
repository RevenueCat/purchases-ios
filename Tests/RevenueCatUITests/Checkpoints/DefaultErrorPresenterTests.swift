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
        XCTAssertEqual(harness.results, [])
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
                flowCanContinue: true
            ),
            completion: harness.completion
        )

        XCTAssertEqual(harness.presentedMessages.first, expectedMessage)
    }

    func testRecoverableErrorAcknowledgementRetries() {
        let harness = Harness()
        harness.presenter.present(
            params: Self.params(flowCanContinue: true),
            completion: harness.completion
        )

        harness.acknowledgement?()

        XCTAssertEqual(harness.results, ["retry"])
    }

    func testTerminalErrorAcknowledgementContinues() {
        let harness = Harness()
        harness.presenter.present(
            params: Self.params(flowCanContinue: false),
            completion: harness.completion
        )

        harness.acknowledgement?()

        XCTAssertEqual(harness.results, ["continue"])
    }

    func testOnlyFirstAcknowledgementCounts() {
        let harness = Harness()
        harness.presenter.present(params: Self.params(), completion: harness.completion)
        let acknowledgement = harness.acknowledgement

        acknowledgement?()
        acknowledgement?()

        XCTAssertEqual(harness.results, ["retry"])
    }

    func testNewErrorReplacesEarlierPresentationWithRetry() {
        let harness = Harness()
        var secondResults: [String] = []
        harness.presenter.present(params: Self.params(), completion: harness.completion)
        let staleAcknowledgement = harness.acknowledgement

        harness.presenter.present(
            params: Self.params(flowCanContinue: false),
            completion: .init { secondResults.append(Self.name(of: $0)) }
        )

        XCTAssertEqual(harness.results, ["retry"])
        staleAcknowledgement?()
        XCTAssertEqual(harness.results, ["retry"])
        harness.acknowledgement?()
        XCTAssertEqual(secondResults, ["continue"])
    }

    func testNewestErrorWinsWhilePreviousAlertIsDismissing() {
        let harness = Harness(defersDismissal: true)
        var secondResults: [String] = []
        var thirdResults: [String] = []
        harness.presenter.present(
            params: Self.params(message: "first"),
            completion: harness.completion
        )

        harness.presenter.present(
            params: Self.params(message: "second"),
            completion: .init { secondResults.append(Self.name(of: $0)) }
        )
        harness.presenter.present(
            params: Self.params(message: "third", flowCanContinue: false),
            completion: .init { thirdResults.append(Self.name(of: $0)) }
        )

        XCTAssertEqual(secondResults, ["retry"])
        XCTAssertEqual(harness.presentedMessages, ["first"])

        harness.completeNextDismissal()

        XCTAssertEqual(harness.results, ["retry"])
        XCTAssertEqual(harness.presentedMessages, ["first", "third"])
        XCTAssertEqual(thirdResults, [])

        harness.acknowledgement?()
        harness.completeNextDismissal()

        XCTAssertEqual(harness.results, ["retry"])
        XCTAssertEqual(secondResults, ["retry"])
        XCTAssertEqual(thirdResults, ["continue"])
    }

    func testMissingPresentationContextDoesNotLeaveFlowWaiting() {
        var recoverableResults: [String] = []
        var terminalResults: [String] = []
        let presenter = DefaultErrorPresenter(presentationContextProvider: { nil })

        presenter.present(
            params: Self.params(flowCanContinue: true),
            completion: .init { recoverableResults.append(Self.name(of: $0)) }
        )
        presenter.present(
            params: Self.params(flowCanContinue: false),
            completion: .init { terminalResults.append(Self.name(of: $0)) }
        )

        XCTAssertEqual(recoverableResults, ["retry"])
        XCTAssertEqual(terminalResults, ["continue"])
    }

    private static func params(
        message: String = "boom",
        flowCanContinue: Bool = true
    ) -> ErrorPresentationParams {
        return .init(
            checkpointIdentifier: "test_checkpoint",
            error: NSError(
                domain: "DefaultErrorPresenterTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ),
            customVariables: [:],
            flowCanContinue: flowCanContinue
        )
    }

    private static func name(of result: ErrorPresentationCompletion.Result) -> String {
        switch result.action {
        case .retry: return "retry"
        case .continue: return "continue"
        case .navigateBack: return "navigateBack"
        }
    }

    @MainActor
    private final class Harness {
        private let host = UIViewController()
        private let defersDismissal: Bool
        var presentedTitles: [String] = []
        var presentedMessages: [String] = []
        var acknowledgement: (@MainActor () -> Void)?
        var results: [String] = []
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

        lazy var completion = ErrorPresentationCompletion { [weak self] result in
            self?.results.append(DefaultErrorPresenterTests.name(of: result))
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
