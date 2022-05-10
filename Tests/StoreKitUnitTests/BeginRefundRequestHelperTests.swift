//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BeginRefundRequestHelperTests.swift
//
//  Created by Madeline Beyl on 10/15/21.

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class BeginRefundRequestHelperTests: TestCase {

    private var systemInfo: MockSystemInfo!
    private var customerInfoManager: MockCustomerInfoManager!
    private var currentUserProvider: MockCurrentUserProvider!
    private var helper: BeginRefundRequestHelper!
    private let mockProductID = "1234"
    private let mockEntitlementID = "1234"
    private let mockEntitlementID2 = "2345"

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    private lazy var sk2Helper: MockSK2BeginRefundRequestHelper! = nil

    override func setUpWithError() throws {
        try super.setUpWithError()
        systemInfo = MockSystemInfo(finishTransactions: true)
        customerInfoManager = MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                      deviceCache: MockDeviceCache(systemInfo: systemInfo),
                                                      backend: MockBackend(),
                                                      systemInfo: systemInfo)
        currentUserProvider = MockCurrentUserProvider(mockAppUserID: "appUserID")
        helper = BeginRefundRequestHelper(systemInfo: systemInfo,
                                          customerInfoManager: customerInfoManager,
                                          currentUserProvider: currentUserProvider)

        if #available(iOS 15.0, macCatalyst 15.0, *) {
            sk2Helper = MockSK2BeginRefundRequestHelper()
            helper.sk2Helper = sk2Helper
        }
    }

    func testBeginRefundRequestForProductFatalErrorIfNotIosOrCatalyst() throws {
        #if os(watchOS) || os(macOS) || os(tvOS)
        expectFatalError(expectedMessage: Strings.purchase.begin_refund_request_unsupported.description) {
            _ = try await helper.beginRefundRequest(forProduct: mockProductID)
        }
        #else
        throw XCTSkip("beginRefundRequestForProduct is not available for this test.")
        #endif
    }

    func testBeginRefundRequestForEntitlementFatalErrorIfNotIosOrCatalyst() throws {
        #if os(watchOS) || os(macOS) || os(tvOS)
        expectFatalError(expectedMessage: Strings.purchase.begin_refund_request_unsupported.description) {
            _ = try await helper.beginRefundRequest(forEntitlement: mockEntitlementID)
        }
        #else
        throw XCTSkip("beginRefundRequestForEntitlement is not available for this test.")
        #endif
    }

    func testBeginRefundRequestForActiveEntitlementFatalErrorIfNotIosOrCatalyst() throws {
        #if os(watchOS) || os(macOS) || os(tvOS)
        expectFatalError(expectedMessage: Strings.purchase.begin_refund_request_unsupported.description) {
            _ = try await helper.beginRefundRequestforActiveEntitlement()
        }
        #else
        throw XCTSkip("beginRefundRequestForEntitlement is not available for this test.")
        #endif
    }

#if os(iOS)
    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundRequestFailsAndPassesErrorThroughIfPurchasesUnverified() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")

        sk2Helper.transactionVerified = false
        sk2Helper.mockSK2Error = expectedError

        do {
            _ = try await helper.beginRefundRequest(forProduct: mockProductID)
            XCTFail("beginRefundRequestForProduct should have thrown error")
        } catch {
            expect(self.sk2Helper.verifyTransactionCalled).to(beTrue())
            // confirm we don't call refund request method if transaction not verified
            expect(self.sk2Helper.refundRequestCalled).to(beFalse())

            expect(error).to(matchError(expectedError))
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundRequestCallsStoreKitRefundRequestMethodForVerifiedTransaction() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        sk2Helper.mockSK2Status = StoreKit.Transaction.RefundRequestStatus.success
        sk2Helper.transactionVerified = true

        let receivedStatus = try await helper.beginRefundRequest(forProduct: mockProductID)
        let expectedStatus = RefundRequestStatus.success

        expect(receivedStatus) == expectedStatus
        expect(self.sk2Helper.verifyTransactionCalled).to(beTrue())
        expect(self.sk2Helper.refundRequestCalled).to(beTrue())
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundReturnsSuccessOnStoreKitSuccess() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        sk2Helper.mockSK2Status = StoreKit.Transaction.RefundRequestStatus.success

        let receivedStatus = try await helper.beginRefundRequest(forProduct: mockProductID)

        let expectedStatus = RefundRequestStatus.success
        expect(receivedStatus) == expectedStatus
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundReturnsFailureOnStoreKitRefundRequestFailure() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        sk2Helper.mockSK2Error = expectedError

        do {
            _ = try await helper.beginRefundRequest(forProduct: mockProductID)
            XCTFail("beginRefundRequestForProduct should have thrown error")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundForEntitlementFailsOnCustomerInfoFetchFail() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCustomerInfoResult = .failure(.missingAppUserID())

        let expectedError = ErrorUtils.beginRefundRequestError(
            withMessage: Strings.purchase.begin_refund_customer_info_error(
                entitlementID: mockEntitlementID).description)

        do {
            _ = try await helper.beginRefundRequest(forEntitlement: mockEntitlementID)
            XCTFail("beginRefundRequestForEntitlement should have thrown error")
        } catch {
            expect(error).to(matchError(expectedError))
            expect(error.localizedDescription) == expectedError.localizedDescription
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundForActiveEntitlementFailsOnCustomerInfoFetchFail() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCustomerInfoResult = .failure(.missingAppUserID())

        let expectedError = ErrorUtils.beginRefundRequestError(
            withMessage: Strings.purchase.begin_refund_customer_info_error(entitlementID: nil).description)

        do {
            _ = try await helper.beginRefundRequestForActiveEntitlement()
            XCTFail("beginRefundRequestForActiveEntitlement should have thrown error")
        } catch {
            expect(error).to(matchError(expectedError))
            expect(error.localizedDescription) == expectedError.localizedDescription
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundForEntitlementFailsIfEntitlementNotInCustomerInfo() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCustomerInfoResult = .success(
            try CustomerInfo(data: mockCustomerInfoResponseWithoutMockEntitlement)
        )

        let expectedMessage =
            Strings.purchase.begin_refund_no_entitlement_found(entitlementID: mockEntitlementID).description
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: expectedMessage)

        do {
            _ = try await helper.beginRefundRequest(forEntitlement: mockEntitlementID)
            XCTFail("beginRefundRequestForEntitlement should have thrown error")
        } catch {
            expect(error).to(matchError(expectedError))
            expect(error.localizedDescription) == expectedError.localizedDescription
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundForActiveEntitlementFailsIfNoActiveEntitlement() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCustomerInfoResult = .success(
            try CustomerInfo(data: mockCustomerInfoResponseWithNoActiveEntitlement)
        )

        let expectedMessage = Strings.purchase.begin_refund_no_active_entitlement.description
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: expectedMessage)

        do {
            _ = try await helper.beginRefundRequestForActiveEntitlement()
            XCTFail("beginRefundRequestForActiveEntitlement should have thrown error")
        } catch {
            expect(error).to(matchError(expectedError))
            expect(error.localizedDescription) == expectedError.localizedDescription
        }
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func testBeginRefundForActiveEntitlementFailsIfMultipleActiveEntitlements() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        customerInfoManager.stubbedCustomerInfoResult = .success(
            try CustomerInfo(data: mockCustomerInfoResponseWithMockEntitlementActiveMultiple)
        )

        let expectedMessage = Strings.purchase.begin_refund_multiple_active_entitlements.description
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: expectedMessage)

        do {
            _ = try await helper.beginRefundRequestForActiveEntitlement()
            XCTFail("beginRefundRequestForActiveEntitlement should have thrown error")
        } catch {
            expect(error).to(matchError(expectedError))
            expect(error.localizedDescription) == expectedError.localizedDescription
        }
    }
#endif

}

private extension BeginRefundRequestHelperTests {

    var mockCustomerInfoResponseWithMockEntitlementActive: [String: Any] {
        return [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [],
                "subscriptions": [
                    "onemonth_freetrial": [:]
                ],
                "entitlements": [
                    "\(mockEntitlementID)": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "product_identifier": "onemonth_freetrial",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ]
                ]
            ]
        ]
    }

    var mockCustomerInfoResponseWithMockEntitlementActiveMultiple: [String: Any] {
        return [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [],
                "subscriptions": [
                    "onemonth_freetrial": [:],
                    "onemonth_freetrial2": [:]
                ],
                "entitlements": [
                    "\(mockEntitlementID)": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "product_identifier": "onemonth_freetrial",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ],
                    "\(mockEntitlementID2)": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "product_identifier": "onemonth_freetrial2",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ]
                ]
            ]
        ]
    }

    var mockCustomerInfoResponseWithNoActiveEntitlement: [String: Any] {
        return [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [],
                "subscriptions": [],
                "entitlements": [
                    "\(mockEntitlementID)": [
                        "expires_date": "2000-08-30T02:40:36Z",
                        "product_identifier": "onemonth_freetrial",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ]
                ]
            ]
        ]
    }

    var mockCustomerInfoResponseWithoutMockEntitlement: [String: Any] {
        return [
            "request_date": "2018-10-19T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "original_application_version": "2083",
                "first_seen": "2019-06-17T16:05:33Z",
                "non_subscriptions": [],
                "subscriptions": [],
                "entitlements": [
                    "pro": [
                        "expires_date": "2100-08-30T02:40:36Z",
                        "product_identifier": "onemonth_freetrial",
                        "purchase_date": "2018-10-26T23:17:53Z"
                    ]
                ]
            ]
        ]
    }

}
