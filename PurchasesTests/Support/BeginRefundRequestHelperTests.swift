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

    func testBeginRefundForEntitlementFailsOnCustomerInfoFetchFail() {

    }

    func testBeginRefundForActiveEntitlementFailsOnCustomerInfoFetchFail() {

    }

    func testBeginRefundForEntitlementFailsIfCustomerInfoNil() {

    }

    func testBeginRefundForActiveEntitlementFailsIfCustomerInfoNil() {

    }

    func testBeginRefundForEntitlementFailsIfEntitlementNotInCustomerInfo() {

    }

    func testBeginRefundForActiveEntitlementFailsIfNoActiveEntitlement() {

    }

#endif

}
