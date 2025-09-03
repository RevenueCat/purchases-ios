//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenter.swift
//
//  Created by Facundo Menzella on 16/6/25.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@MainActor
private final class WindowHolder {
    var window: UIWindow?
}

@MainActor
@available(iOS 15.0, *)
final class CustomerCenterActionWrapperTests: TestCase {

    func testRestoreStarted() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterRestoreStarted called")

        wrapper.onCustomerCenterRestoreStarted {
            expectation.fulfill()
        }

        wrapper.handleAction(.restoreStarted)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRestoreFailed() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterRestoreFailed called")

        wrapper.onCustomerCenterRestoreFailed { error in
            // swiftlint:disable:next force_cast
            XCTAssertEqual((error as! TestError), TestError.error)
            expectation.fulfill()
        }

        wrapper.handleAction(.restoreFailed(TestError.error))
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRestoreCompleted() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterRestoreCompleted called")

        let expectedInfo = CustomerInfoFixtures.customerInfoWithGoogleSubscriptions

        wrapper.onCustomerCenterRestoreCompleted { info in
            XCTAssertEqual(info, expectedInfo)
            expectation.fulfill()
        }

        wrapper.handleAction(.restoreCompleted(expectedInfo))
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testShowingManageSubscriptions() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterShowingManageSubscriptions called")

        wrapper.onCustomerCenterShowingManageSubscriptions {
            expectation.fulfill()
        }

        wrapper.handleAction(.showingManageSubscriptions)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRefundRequestStarted() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterRefundRequestStarted called")

        let productId = "test_product"

        wrapper.onCustomerCenterRefundRequestStarted { id in
            XCTAssertEqual(id, productId)
            expectation.fulfill()
        }

        wrapper.handleAction(.refundRequestStarted(productId))
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testRefundRequestCompleted() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterRefundRequestCompleted called")

        let productId = "completed_product"
        let status: RefundRequestStatus = .success

        wrapper.onCustomerCenterRefundRequestCompleted { id, result in
            XCTAssertEqual(id, productId)
            XCTAssertEqual(result, status)
            expectation.fulfill()
        }

        wrapper.handleAction(.refundRequestCompleted(productId, status))
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testFeedbackSurveyCompleted() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterFeedbackSurveyCompleted called")

        let option = "option-id"

        wrapper.onCustomerCenterFeedbackSurveyCompleted { value in
            XCTAssertEqual(value, option)
            expectation.fulfill()
        }

        wrapper.handleAction(.feedbackSurveyCompleted(option))
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testManagementOptionSelected() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterManagementOptionSelected called")

        wrapper.onCustomerCenterManagementOptionSelected { _ in
            expectation.fulfill()
        }

        wrapper.handleAction(.buttonTapped(action: CustomerCenterManagementOption.MissingPurchase()))
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testPromotionalOfferSuccess() async throws {
        let wrapper = CustomerCenterActionWrapper()
        let expectation = XCTestExpectation(description: "onCustomerCenterPromotionalOfferSuccess called")

        wrapper.onCustomerCenterPromotionalOfferSuccess {
            expectation.fulfill()
        }

        wrapper.handleAction(.promotionalOfferSuccess)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testNestedActionWrappers() async throws {
        let actionWrapper = await CustomerCenterActionWrapper()
        let expectation1 = XCTestExpectation(description: "inner promotionalOfferSuccess should not fire")
        expectation1.isInverted = true
        let expectation2 = XCTestExpectation(description: "outer promotionalOfferSuccess should fire")

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

}

#endif
