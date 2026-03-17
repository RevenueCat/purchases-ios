//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterActionWrapperTests.swift
//
//  Created by Facundo Menzella on 24/3/25.

import Nimble
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@MainActor
private final class WindowHolder {
    var window: UIWindow?
}

@available(iOS 15.0, *)
final class CustomerCenterActionWrapperTests: TestCase {

    func testRestoreStarted() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "restoreStarted")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterRestoreStarted {
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.restoreStarted)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRestoreFailed() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "restoreFailed")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterRestoreFailed { _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.restoreFailed(TestError.error))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testShowingManageSubscriptions() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "showingManageSubscriptions")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterShowingManageSubscriptions {
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.showingManageSubscriptions)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRestoreCompleted() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "restoreCompleted")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterRestoreCompleted { _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.restoreCompleted(CustomerInfoFixtures.customerInfoWithGoogleSubscriptions))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testFeedbackSurveyCompleted() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "feedbackSurveyCompleted")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterFeedbackSurveyCompleted { _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.feedbackSurveyCompleted(""))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRefundRequestStarted() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "refundRequestStarted")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterRefundRequestStarted { _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.refundRequestStarted(""))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRefundRequestCompleted() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "refundRequestCompleted")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterRefundRequestCompleted { _, _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.refundRequestCompleted("", .error))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testPromotionalOfferSuccess() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "promotionalOfferSuccess")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterPromotionalOfferSuccess {
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.promotionalOfferSuccess)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testChangePlansSelected() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "changePlansSelected")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterChangePlansSelected { _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            actionWrapper.handleAction(.showingChangePlans("group_1"))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testManagementOptionSelected() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "managementOptionSelected")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterManagementOptionSelected { _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        // Send a generic management option (e.g., Cancel)
        await MainActor.run {
            actionWrapper.handleAction(.buttonTapped(action: CustomerCenterManagementOption.Cancel()))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testCustomActionSelected() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "customActionSelected")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterCustomActionSelected { _, _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            let customActionData = CustomActionData(
                actionIdentifier: "delete_user",
                purchaseIdentifier: "monthly_subscription"
            )
            actionWrapper.handleAction(.customActionSelected(customActionData))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testCustomActionSelectedWithNilPurchase() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "customActionSelected with nil purchase")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterCustomActionSelected { _, _ in
                    expectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            let customActionData = CustomActionData(
                actionIdentifier: "rate_app",
                purchaseIdentifier: nil
            )
            actionWrapper.handleAction(.customActionSelected(customActionData))
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testManagementOptionSelectedWithCustomAction() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let customActionExpectation = XCTestExpectation(description: "customActionSelected")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterCustomActionSelected { _, _ in
                    customActionExpectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        let customAction = CustomerCenterManagementOption.CustomAction(
            actionIdentifier: "delete_user",
            purchaseIdentifier: "product_123"
        )

        await MainActor.run {
            actionWrapper.handleAction(
                .customActionSelected(
                    CustomActionData(
                        actionIdentifier: customAction.actionIdentifier,
                        purchaseIdentifier: customAction.purchaseIdentifier
                    )
                )
            )
        }

        await fulfillment(of: [customActionExpectation], timeout: 1.0)
    }

    func testRestoreInitiatedLegacyHandlerCanCancelRestore() async throws {
        let purchasesProvider = await MockCustomerCenterPurchases()
        purchasesProvider.restorePurchasesResult = .success(CustomerInfoFixtures.customerInfoWithGoogleSubscriptions)

        let restoreInitiatedExpectation = XCTestExpectation(description: "restoreInitiated legacy handler called")
        let actionWrapper = await CustomerCenterActionWrapper(legacyActionHandler: { action in
            guard case let .restoreInitiated(resume) = action else { return }

            resume(shouldProceed: false)
            restoreInitiatedExpectation.fulfill()
        })

        let viewModel = await RestorePurchasesAlertViewModel(actionWrapper: actionWrapper)
        var environmentHandlerCalled = false

        let didProceed = await viewModel.performRestore(
            purchasesProvider: purchasesProvider,
            restoreInitiated: { _ in
                environmentHandlerCalled = true
            }
        )

        await fulfillment(of: [restoreInitiatedExpectation], timeout: 1.0)
        expect(didProceed).to(beFalse())
        expect(environmentHandlerCalled).to(beFalse())
        expect(purchasesProvider.restorePurchasesCallCount) == 0
    }

    func testRestoreInitiatedLegacyHandlerCanProceedWithRestore() async throws {
        let purchasesProvider = await MockCustomerCenterPurchases()
        purchasesProvider.restorePurchasesResult = .success(CustomerInfoFixtures.customerInfoWithGoogleSubscriptions)

        let restoreInitiatedExpectation = XCTestExpectation(description: "restoreInitiated legacy handler called")
        let actionWrapper = await CustomerCenterActionWrapper(legacyActionHandler: { action in
            guard case let .restoreInitiated(resume) = action else { return }

            resume(shouldProceed: true)
            restoreInitiatedExpectation.fulfill()
        })

        let viewModel = await RestorePurchasesAlertViewModel(actionWrapper: actionWrapper)

        let didProceed = await viewModel.performRestore(
            purchasesProvider: purchasesProvider,
            restoreInitiated: { _ in
                XCTFail("Environment handler should not be used when legacy handler is present.")
            }
        )

        await fulfillment(of: [restoreInitiatedExpectation], timeout: 1.0)
        expect(didProceed).to(beTrue())
        expect(purchasesProvider.restorePurchasesCallCount) == 1
    }

    func testRestoreInitiatedLegacyHandlerWithoutResumeAutoProceedsAfterTimeout() async throws {
        let purchasesProvider = await MockCustomerCenterPurchases()
        purchasesProvider.restorePurchasesResult = .success(CustomerInfoFixtures.customerInfoWithGoogleSubscriptions)

        let restoreInitiatedExpectation = XCTestExpectation(description: "restoreInitiated legacy handler called")
        let actionWrapper = await CustomerCenterActionWrapper(legacyActionHandler: { action in
            guard case .restoreInitiated = action else { return }
            restoreInitiatedExpectation.fulfill()
        })

        let viewModel = await RestorePurchasesAlertViewModel(
            actionWrapper: actionWrapper,
            restoreInitiatedTimeoutNanoseconds: 50_000_000
        )

        let didProceed = await viewModel.performRestore(
            purchasesProvider: purchasesProvider,
            restoreInitiated: { _ in
                XCTFail("Environment handler should not be used when legacy handler is present.")
            }
        )

        await fulfillment(of: [restoreInitiatedExpectation], timeout: 1.0)
        expect(didProceed).to(beTrue())
        expect(purchasesProvider.restorePurchasesCallCount) == 1
    }

    func testRestoreInitiatedEnvironmentHandlerWithoutResumeAutoProceedsAfterTimeout() async throws {
        let purchasesProvider = await MockCustomerCenterPurchases()
        purchasesProvider.restorePurchasesResult = .success(CustomerInfoFixtures.customerInfoWithGoogleSubscriptions)

        let actionWrapper = await CustomerCenterActionWrapper()
        let viewModel = await RestorePurchasesAlertViewModel(
            actionWrapper: actionWrapper,
            restoreInitiatedTimeoutNanoseconds: 50_000_000
        )

        let didProceed = await viewModel.performRestore(
            purchasesProvider: purchasesProvider,
            restoreInitiated: { _ in
                // Intentionally not calling resume to verify timeout fallback.
            }
        )

        expect(didProceed).to(beTrue())
        expect(purchasesProvider.restorePurchasesCallCount) == 1
    }
}

#endif
