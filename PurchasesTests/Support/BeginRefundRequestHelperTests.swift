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

class BeginRefundRequestHelperTests: XCTestCase {

    private var systemInfo: MockSystemInfo!
    private var customerInfoManager: MockCustomerInfoManager!
    private var identityManager: MockIdentityManager!
    private var helper: BeginRefundRequestHelper!
    private let mockProductID = "1234"
    private let mockEntitlementID = "1234"

    var mockCustomerInfoResponseWithMockEntitlementActive: [String: Any] {
        get {
            return [
                "request_date": "2018-10-19T02:40:36Z",
                "subscriber": [
                    "original_app_user_id": "app_user_id",
                    "original_application_version": "2083",
                    "first_seen": "2019-06-17T16:05:33Z",
                    "non_subscriptions": [],
                    "subscriptions": [],
                    "entitlements": [
                        "\(mockEntitlementID)" : [
                            "expires_date" : "2100-08-30T02:40:36Z",
                            "product_identifier": "onemonth_freetrial",
                            "purchase_date": "2018-10-26T23:17:53Z"
                        ]
                    ]
                ]
            ]
        }
    }

    var mockCustomerInfoResponseWithNoActiveEntitlement: [String: Any] {
        get {
            return [
                "request_date": "2018-10-19T02:40:36Z",
                "subscriber": [
                    "original_app_user_id": "app_user_id",
                    "original_application_version": "2083",
                    "first_seen": "2019-06-17T16:05:33Z",
                    "non_subscriptions": [],
                    "subscriptions": [],
                    "entitlements": [
                        "\(mockEntitlementID)" : [
                            "expires_date" : "2000-08-30T02:40:36Z",
                            "product_identifier": "onemonth_freetrial",
                            "purchase_date": "2018-10-26T23:17:53Z"
                        ]
                    ]
                ]
            ]
        }
    }

    let mockCustomerInfoResponseWithoutMockEntitlement: [String: Any] = [
        "request_date": "2018-10-19T02:40:36Z",
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "original_application_version": "2083",
            "first_seen": "2019-06-17T16:05:33Z",
            "non_subscriptions": [],
            "subscriptions": [],
            "entitlements": [
                "pro" : [
                    "expires_date" : "2100-08-30T02:40:36Z",
                    "product_identifier": "onemonth_freetrial",
                    "purchase_date": "2018-10-26T23:17:53Z"
                ]
            ]
        ]
    ]

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    private lazy var sk2Helper = MockSK2BeginRefundRequestHelper()

    override func setUpWithError() throws {
        try super.setUpWithError()
        systemInfo = MockSystemInfo(finishTransactions: true)
        customerInfoManager = MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                      deviceCache: MockDeviceCache(systemInfo: systemInfo),
                                                      backend: MockBackend(),
                                                      systemInfo: systemInfo)
        identityManager = MockIdentityManager(mockAppUserID: "appUserID")
        helper = BeginRefundRequestHelper(systemInfo: systemInfo,
                                          customerInfoManager: customerInfoManager,
                                          identityManager: identityManager)

        if #available(iOS 15.0, macCatalyst 15.0, *) {
            helper.sk2Helper = sk2Helper
        }

    }

    func testBeginRefundRequestForProductFatalErrorIfNotIosOrCatalyst() {
        #if os(watchOS) || os(macOS) || os(tvOS)
        expectFatalError(expectedMessage: Strings.purchase.begin_refund_request_unsupported.description) {
            helper.beginRefundRequest(forProduct: mockProductID) { result in }
        }
        #endif
    }

    func testBeginRefundRequestForEntitlementFatalErrorIfNotIosOrCatalyst() {
        #if os(watchOS) || os(macOS) || os(tvOS)
        expectFatalError(expectedMessage: Strings.purchase.begin_refund_request_unsupported.description) {
            helper.beginRefundRequest(forEntitlement: mockEntitlementID) { result in }
        }
        #endif
    }

    func testBeginRefundRequestForActiveEntitlementFatalErrorIfNotIosOrCatalyst() {
        #if os(watchOS) || os(macOS) || os(tvOS)
        expectFatalError(expectedMessage: Strings.purchase.begin_refund_request_unsupported.description) {
            helper.beginRefundRequestforActiveEntitlement { result in }
        }
        #endif
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    func testBeginRefundRequestFailsAndPassesErrorThroughIfPurchasesUnverified() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")

        sk2Helper.transactionVerified = false
        sk2Helper.maybeMockSK2Error = expectedError


        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(forProduct: mockProductID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
        expect(self.sk2Helper.verifyTransactionCalled).to(beTrue())

        // confirm we don't call refund request method if transaction not verified
        expect(self.sk2Helper.refundRequestCalled).to(beFalse())
    }

    func testBeginRefundRequestCallsStoreKitRefundRequestMethodForVerifiedTransaction() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        sk2Helper.maybeMockSK2Status = StoreKit.Transaction.RefundRequestStatus.success
        sk2Helper.transactionVerified = true

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(forProduct: mockProductID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        let expectedStatus = RefundRequestStatus.success
        expect(nonNilReceivedResult).to(beSuccess { status in
            expect(status) == expectedStatus
        })
        expect(self.sk2Helper.verifyTransactionCalled).to(beTrue())
        expect(self.sk2Helper.refundRequestCalled).to(beTrue())
    }

    func testBeginRefundReturnsSuccessOnStoreKitSuccess() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        sk2Helper.maybeMockSK2Status = StoreKit.Transaction.RefundRequestStatus.success

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(forProduct: mockProductID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        let expectedStatus = RefundRequestStatus.success
        expect(nonNilReceivedResult).to(beSuccess { status in
            expect(status) == expectedStatus
        })
    }

    func testBeginRefundReturnsFailureOnStoreKitRefundRequestFailure() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")
        sk2Helper.maybeMockSK2Error = expectedError

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(forProduct: mockProductID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

    func testBeginRefundForEntitlementFailsOnCustomerInfoFetchFail() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        let customerInfoError = ErrorUtils.customerInfoError(withMessage: "")
        customerInfoManager.stubbedError = ErrorUtils.customerInfoError(withMessage: "", error: customerInfoError)

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: Strings.purchase.begin_refund_customer_info_error(entitlementID: nil).description, error: customerInfoError)

        helper.beginRefundRequest(forEntitlement: mockEntitlementID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

    func testBeginRefundForActiveEntitlementFailsOnCustomerInfoFetchFail() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        let customerInfoError = ErrorUtils.customerInfoError(withMessage: "")
        customerInfoManager.stubbedError = ErrorUtils.customerInfoError(withMessage: "", error: customerInfoError)

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: Strings.purchase.begin_refund_customer_info_error(entitlementID: nil).description, error: customerInfoError)

        helper.beginRefundRequestForActiveEntitlement { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })

    }

    func testBeginRefundForEntitlementFailsIfCustomerInfoNil() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        customerInfoManager.stubbedCustomerInfo = nil

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: Strings.purchase.begin_refund_for_entitlement_nil_customer_info(entitlementID: nil).description)

        helper.beginRefundRequest(forEntitlement: mockEntitlementID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

    func testBeginRefundForActiveEntitlementFailsIfCustomerInfoNil() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        customerInfoManager.stubbedCustomerInfo = nil

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: Strings.purchase.begin_refund_for_entitlement_nil_customer_info(entitlementID: nil).description)

        helper.beginRefundRequestForActiveEntitlement { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

    func testBeginRefundForEntitlementFailsIfEntitlementNotInCustomerInfo() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        customerInfoManager.stubbedCustomerInfo = try CustomerInfo(data: mockCustomerInfoResponseWithoutMockEntitlement)

        let expectedMessage =
            Strings.purchase.begin_refund_no_active_entitlement(entitlementID: mockEntitlementID).description
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: expectedMessage)

        helper.beginRefundRequest(forEntitlement: mockEntitlementID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

    func testBeginRefundForActiveEntitlementFailsIfNoActiveEntitlement() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        customerInfoManager.stubbedCustomerInfo =
            try CustomerInfo(data: mockCustomerInfoResponseWithNoActiveEntitlement)

        let expectedMessage = Strings.purchase.begin_refund_no_active_entitlement(entitlementID: nil).description
        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: expectedMessage)

        helper.beginRefundRequestForActiveEntitlement { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

#endif

}
