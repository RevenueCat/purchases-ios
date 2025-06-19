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

import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

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

}

#endif
