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

    func testExplicitPresentationContextDoesNotFallBackToAnotherScene() throws {
        let sceneClass = try XCTUnwrap(NSClassFromString("UIScene") as? NSObject.Type)
        let scene = try XCTUnwrap(sceneClass.init() as? UIScene)
        var fallbackCallCount = 0
        var completionCount = 0
        let presenter = DefaultErrorPresenter(
            presentationContext: .init(scene: scene),
            presentationContextProvider: {
                fallbackCallCount += 1
                return UIViewController()
            }
        )

        presenter.present(
            params: Self.params(),
            completion: .init { completionCount += 1 }
        )

        XCTAssertEqual(fallbackCallCount, 0)
        XCTAssertEqual(completionCount, 1)
    }

    func testPresentCreatesAlertWithoutCompletingFlow() {
        let harness = Harness()

        harness.presenter.present(params: Self.params(), completion: harness.completion)

        XCTAssertNil(harness.presentedTitle)
        XCTAssertEqual(harness.presentedMessages, ["Something went wrong. Please try again."])
        XCTAssertEqual(harness.presentedAcknowledgementTitles, ["OK"])
        XCTAssertEqual(harness.completionCount, 0)
    }

    func testPurchaseErrorDoesNotExposeDeveloperFacingDescription() {
        let harness = Harness()
        let error = ErrorCode.storeProblemError as NSError
        let developerFacingMessage = LocalizedAlertError.Content(error: error).message

        harness.presenter.present(
            params: .init(
                checkpointIdentifier: "test_checkpoint",
                error: error,
                customVariables: [:],
                kind: .flowActionFailed
            ),
            completion: harness.completion
        )

        XCTAssertEqual(
            harness.presentedMessages,
            ["There was a problem with the store. Please try again later."]
        )
        XCTAssertNotEqual(harness.presentedMessages.first, developerFacingMessage)
    }

    func testFlowCouldNotBeShownUsesContentLoadMessage() {
        let harness = Harness()

        harness.presenter.present(
            params: Self.params(errorCode: .configurationError, kind: .flowCouldNotBeShown),
            completion: harness.completion
        )

        XCTAssertEqual(harness.presentedMessages, ["This content couldn't be loaded. Please try again later."])
    }

    func testFlowResultSyncFailedUsesPurchaseVerificationMessage() {
        let harness = Harness()

        harness.presenter.present(
            params: Self.params(errorCode: .unknownBackendError, kind: .flowResultSyncFailed),
            completion: harness.completion
        )

        XCTAssertEqual(harness.presentedMessages, ["Your purchases couldn't be verified. Please try again later."])
    }

    func testConnectionErrorsUseNetworkMessageForEveryFailureKind() {
        let expectedMessage = "Couldn't connect. Check your internet connection and try again."

        for errorCode in [ErrorCode.networkError, .offlineConnectionError] {
            for kind in [
                CheckpointFailureKind.flowCouldNotBeShown,
                .flowActionFailed,
                .flowResultSyncFailed
            ] {
                let harness = Harness()

                harness.presenter.present(
                    params: Self.params(errorCode: errorCode, kind: kind),
                    completion: harness.completion
                )

                XCTAssertEqual(harness.presentedMessages, [expectedMessage])
            }
        }
    }

    func testFlowActionFailedUsesPurchaseErrorCodeMessage() {
        let expectedMessages: [(ErrorCode, String)] = [
            (.storeProblemError, "There was a problem with the store. Please try again later."),
            (.purchaseNotAllowedError, "Purchases aren't allowed on this device."),
            (.productNotAvailableForPurchaseError, "This product isn't available right now."),
            (.productAlreadyPurchasedError, "You already own this product."),
            (.paymentPendingError, "Your payment is pending. You'll get access once it's approved."),
            (.unknownError, "Something went wrong. Please try again."),
            (.invalidReceiptError, "Something went wrong. Please try again.")
        ]

        for (errorCode, expectedMessage) in expectedMessages {
            let harness = Harness()

            harness.presenter.present(
                params: Self.params(errorCode: errorCode, kind: .flowActionFailed),
                completion: harness.completion
            )

            XCTAssertEqual(harness.presentedMessages, [expectedMessage])
        }
    }

    func testSimulatedTestStoreFailureUsesOriginalDescription() {
        let harness = Harness()
        let message = "Purchase failure simulated successfully in Test Store."

        harness.presenter.present(
            params: .init(
                checkpointIdentifier: "test_checkpoint",
                error: NSError(
                    domain: ErrorCode.errorDomain,
                    code: ErrorCode.testStoreSimulatedPurchaseError.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: message]
                ),
                customVariables: [:],
                kind: .flowActionFailed
            ),
            completion: harness.completion
        )

        XCTAssertEqual(harness.presentedMessages, [message])
    }

    func testMessageUsesPreferredUILocaleOverride() {
        let harness = Harness(localeIdentifier: "ja")

        harness.presenter.present(
            params: Self.params(errorCode: .configurationError, kind: .flowCouldNotBeShown),
            completion: harness.completion
        )

        XCTAssertEqual(
            harness.presentedMessages,
            ["このコンテンツを読み込めませんでした。しばらくしてからもう一度お試しください。"]
        )
        XCTAssertNil(harness.presentedTitle)
        XCTAssertEqual(harness.presentedAcknowledgementTitles, ["わかりました"])
    }

    func testMessageUsesSystemLocalizationWithoutPreferredUILocaleOverride() {
        let harness = Harness(localeIdentifier: nil)
        let key = "This content couldn't be loaded. Please try again later."

        harness.presenter.present(
            params: Self.params(errorCode: .configurationError, kind: .flowCouldNotBeShown),
            completion: harness.completion
        )

        XCTAssertEqual(
            harness.presentedMessages,
            [Bundle.revenueCatUI.localizedString(forKey: key, value: key, table: nil)]
        )
    }

    func testFlowActionErrorAcknowledgementCompletes() {
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
        XCTAssertEqual(harness.presentedMessages, ["Something went wrong. Please try again."])

        harness.completeNextDismissal()

        XCTAssertEqual(harness.completionCount, 1)
        XCTAssertEqual(
            harness.presentedMessages,
            [
                "Something went wrong. Please try again.",
                "This content couldn't be loaded. Please try again later."
            ]
        )
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

    func testFailedAlertPresentationDoesNotLeaveFlowWaiting() {
        let harness = Harness(failsPresentation: true)

        harness.presenter.present(
            params: Self.params(kind: .flowCouldNotBeShown),
            completion: harness.completion
        )

        XCTAssertEqual(harness.completionCount, 1)
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

    private static func params(
        errorCode: ErrorCode,
        kind: CheckpointFailureKind
    ) -> ErrorPresentationParams {
        return .init(
            checkpointIdentifier: "test_checkpoint",
            error: NSError(
                domain: ErrorCode.errorDomain,
                code: errorCode.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "raw detail"]
            ),
            customVariables: [:],
            kind: kind
        )
    }

    @MainActor
    private final class Harness {
        private let host = UIViewController()
        private let defersDismissal: Bool
        private let failsPresentation: Bool
        private let localeIdentifier: String?
        var presentedTitle: String?
        var presentedMessages: [String] = []
        var presentedAcknowledgementTitles: [String] = []
        var acknowledgement: (@MainActor () -> Void)?
        var completionCount = 0
        var deferredAlerts: [DeferredDismissalViewController] = []

        init(
            defersDismissal: Bool = false,
            failsPresentation: Bool = false,
            localeIdentifier: String? = "en"
        ) {
            self.defersDismissal = defersDismissal
            self.failsPresentation = failsPresentation
            self.localeIdentifier = localeIdentifier
        }

        lazy var presenter = DefaultErrorPresenter(
            presentationContextProvider: { [host] in host },
            preferredUILocaleProvider: { [localeIdentifier] in localeIdentifier },
            alertFactory: { [weak self] _, title, message, acknowledgementTitle, acknowledgement in
                self?.presentedTitle = title
                self?.presentedMessages.append(message)
                self?.presentedAcknowledgementTitles.append(acknowledgementTitle)
                self?.acknowledgement = acknowledgement

                if self?.defersDismissal == true {
                    let alert = DeferredDismissalViewController()
                    self?.deferredAlerts.append(alert)
                    return alert
                }

                if self?.failsPresentation == true {
                    return UIViewController()
                }

                return PresentedViewController()
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
    private final class PresentedViewController: UIViewController {
        private let presentingController = UIViewController()

        override var presentingViewController: UIViewController? {
            return self.presentingController
        }

        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            completion?()
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
