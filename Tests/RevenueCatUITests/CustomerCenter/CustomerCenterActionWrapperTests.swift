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

    func testNestedActionWrappers() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation1 = XCTestExpectation(description: "promotionalOfferSuccess")
        let expectation2 = XCTestExpectation(description: "promotionalOfferSuccess")

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = VStack {
                Text("test")
                    .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                    .onCustomerCenterPromotionalOfferSuccess {
                        expectation1.fulfill()
                    }
            }
                .onCustomerCenterPromotionalOfferSuccess {
                    expectation2.fulfill()
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

        await fulfillment(of: [expectation1, expectation2], timeout: 1.0)
    }

    func testCustomActionSelected() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "customActionSelected")
        var receivedActionData: (String, String?)?

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterCustomActionSelected { actionIdentifier, activePurchaseId in
                    receivedActionData = (actionIdentifier, activePurchaseId)
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
                activePurchaseId: "monthly_subscription"
            )
            actionWrapper.handleAction(.customActionSelected(customActionData))
        }

        await fulfillment(of: [expectation], timeout: 1.0)

        expect(receivedActionData?.0) == "delete_user"
        expect(receivedActionData?.1) == "monthly_subscription"
    }

    func testCustomActionSelectedWithNilPurchase() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "customActionSelected with nil purchase")
        var receivedActionData: (String, String?)?

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterCustomActionSelected { actionIdentifier, activePurchaseId in
                    receivedActionData = (actionIdentifier, activePurchaseId)
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
                activePurchaseId: nil
            )
            actionWrapper.handleAction(.customActionSelected(customActionData))
        }

        await fulfillment(of: [expectation], timeout: 1.0)

        expect(receivedActionData?.0) == "rate_app"
        expect(receivedActionData?.1).to(beNil())
    }

    func testManagementOptionSelectedWithCustomAction() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let customActionExpectation = XCTestExpectation(description: "customActionSelected")
        let managementOptionExpectation = XCTestExpectation(description: "managementOptionSelected")

        var receivedCustomActionData: (String, String?)?
        var receivedManagementAction: CustomerCenterActionable?

        let windowHolder = await WindowHolder()

        await MainActor.run {
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterCustomActionSelected { actionIdentifier, activePurchaseId in
                    receivedCustomActionData = (actionIdentifier, activePurchaseId)
                    customActionExpectation.fulfill()
                }
                .onCustomerCenterManagementOptionSelected { action in
                    receivedManagementAction = action
                    managementOptionExpectation.fulfill()
                }

            let viewController = UIHostingController(rootView: testView)
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()

            windowHolder.window = window
        }

        await MainActor.run {
            let customAction = CustomerCenterManagementOption.CustomAction(
                actionIdentifier: "delete_user",
                activePurchaseId: "product_123"
            )
            actionWrapper.handleAction(.buttonTapped(action: customAction))
        }

        await fulfillment(of: [customActionExpectation, managementOptionExpectation], timeout: 1.0)

        // Verify both handlers received the action
        expect(receivedCustomActionData?.0) == "delete_user"
        expect(receivedCustomActionData?.1) == "product_123"

        let receivedCustomAction = receivedManagementAction as? CustomerCenterManagementOption.CustomAction
        expect(receivedCustomAction?.actionIdentifier) == "delete_user"
        expect(receivedCustomAction?.activePurchaseId) == "product_123"
    }
}

#endif
