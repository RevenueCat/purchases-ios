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
    private var helper: BeginRefundRequestHelper!
    private let mockProductID = "1234"


    override func setUp() {
        systemInfo = try! MockSystemInfo(platformFlavor: "", platformFlavorVersion: "", finishTransactions: true)
        helper = BeginRefundRequestHelper(systemInfo: systemInfo)
    }

    func testBeginRefundRequestFatalErrorIfNotIosOrCatalyst() {
        #if os(watchOS) || os(macOS) || os(tvOS)
        expectFatalError(expectedMessage: "Tried to call beginRefundRequest in a platform that doesn't support it!") {
            helper.beginRefundRequest(productID: mockProductID) { result in }
        }
        #endif
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    func testBeginRefundRequestFailsIfCantGetWindowScene() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        

        helper.beginRefundRequest(productID: mockProductID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        let expectedError = ErrorUtils.storeProblemError(withMessage: "Failed to get UIWindowScene")
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
    }

    func testBeginRefundRequestMapsSKErrorsCorrectly() throws {
        
    }

    func testBeginRefundRequestFailsAndPassesErrorThroughIfPurchasesUnverified() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let expectedError = ErrorUtils.beginRefundRequestError(withMessage: "test")

        let requestHelperSk2 = MockRefundRequestHelperSK2()
        requestHelperSk2.transactionVerified = false
        requestHelperSk2.mockError = expectedError
        helper.refundRequestHelperSK2 = requestHelperSk2

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(productID: mockProductID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        expect(nonNilReceivedResult).to(beFailure { error in
            expect(error).to(matchError(expectedError))
        })
        expect(requestHelperSk2.verifyTransactionCalled).to(beTrue())

        // confirm we don't call refund request method if transaction not verified
        expect(requestHelperSk2.refundRequestCalled).to(beFalse())
    }

    func testBeginRefundRequestCallsStoreKitRefundRequestMethodForVerifiedTransaction() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let requestHelperSk2 = MockRefundRequestHelperSK2()
        requestHelperSk2.mockStatus = StoreKit.Transaction.RefundRequestStatus.success
        requestHelperSk2.transactionVerified = true
        helper.refundRequestHelperSK2 = requestHelperSk2

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(productID: mockProductID) { result in
            callbackCalled = true
            receivedResult = result
        }

        expect(callbackCalled).toEventually(beTrue())
        let nonNilReceivedResult: Result<RefundRequestStatus, Error> = try XCTUnwrap(receivedResult)
        let expectedStatus = RefundRequestStatus.success
        expect(nonNilReceivedResult).to(beSuccess { status in
            expect(status) == expectedStatus
        })
        expect(requestHelperSk2.verifyTransactionCalled).to(beTrue())
        expect(requestHelperSk2.refundRequestCalled).to(beTrue())
    }

    func testBeginRefundReturnsSuccessOnStoreKitSuccess() throws {
        guard #available(iOS 15.0, macCatalyst 15.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        let requestHelperSk2 = MockRefundRequestHelperSK2()
        requestHelperSk2.mockStatus = StoreKit.Transaction.RefundRequestStatus.success
        helper.refundRequestHelperSK2 = requestHelperSk2

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(productID: mockProductID) { result in
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

        let requestHelperSk2 = MockRefundRequestHelperSK2()
        requestHelperSk2.mockError = expectedError
        helper.refundRequestHelperSK2 = requestHelperSk2

        var callbackCalled = false
        var receivedResult: Result<RefundRequestStatus, Error>?

        helper.beginRefundRequest(productID: mockProductID) { result in
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
