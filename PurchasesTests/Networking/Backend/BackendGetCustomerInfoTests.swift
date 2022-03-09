//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetCustomerInfoTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetCustomerInfoTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testCachesCustomerGetsForSameCustomer() {
        httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        backend.getCustomerInfo(appUserID: Self.userID) { _, _ in }
        backend.getCustomerInfo(appUserID: Self.userID) { _, _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testDoesntCacheCustomerGetsForSameCustomer() {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: Self.userID), response: response)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID2), response: response)

        backend.getCustomerInfo(appUserID: Self.userID) { _, _ in }
        backend.getCustomerInfo(appUserID: userID2) { _, _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetCustomerCallsBackendProperly() throws {
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)

        self.httpClient.mock(requestPath: path, response: response)

        backend.getCustomerInfo(appUserID: Self.userID) { _, _ in }

        let expectedCall = MockHTTPClient.Call(request: .init(method: .get, path: path),
                                               headers: HTTPClient.authorizationHeader(withAPIKey: Self.apiKey))

        expect(self.httpClient.calls).toEventually(haveCount(1))

        if self.httpClient.calls.count > 0 {
            let call = self.httpClient.calls[0]

            try call.expectToEqual(expectedCall)
        }
    }

    func testGetsCustomerInfo() {
        httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var customerInfo: CustomerInfo?

        backend.getCustomerInfo(appUserID: Self.userID) { (info, _) in
            customerInfo = info
        }

        expect(customerInfo).toEventuallyNot(beNil())
    }

    func testEncodesCustomerUserID() {
        let encodeableUserID = "userid with spaces"
        let encodedUserID = "userid%20with%20spaces"
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)

        httpClient.mock(requestPath: .getCustomerInfo(appUserID: encodedUserID), response: response)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: encodeableUserID),
                        response: .init(statusCode: .notFoundError, response: nil))

        var customerInfo: CustomerInfo?

        backend.getCustomerInfo(appUserID: encodeableUserID) { (info, _) in
            customerInfo = info
        }

        expect(customerInfo).toEventuallyNot(beNil())
    }

    func testHandlesGetCustomerInfoErrors() {
        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .notFoundError, response: nil)
        )

        var error: NSError?

        backend.getCustomerInfo(appUserID: Self.userID) { (_, newError) in
            error = newError as NSError?
        }

        expect(error).toEventuallyNot(beNil())
        expect(error?.domain).to(equal(RCPurchasesErrorCodeDomain))
        let underlyingError = (error?.userInfo[NSUnderlyingErrorKey]) as? NSError
        expect(underlyingError).toEventuallyNot(beNil())
        expect(underlyingError?.domain).to(equal("RevenueCat.BackendErrorCode"))
        expect(error?.userInfo["finishable"]).to(be(true))
    }

    func testHandlesInvalidJSON() {
        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: ["sjkaljdklsjadkjs": ""])
        )

        var error: NSError?

        backend.getCustomerInfo(appUserID: Self.userID) { (_, newError) in
            error = newError as NSError?
        }

        expect(error).toEventuallyNot(beNil())
        expect(error?.domain).to(equal(RCPurchasesErrorCodeDomain))
        expect(error?.code).to(equal(ErrorCode.unexpectedBackendResponseError.rawValue))
    }

    func testGetCustomerInfoDoesNotMakeTwoRequests() {
        let customerResponse: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "user",
                "subscriptions": []
            ]
        ]
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)
        let customerInfoResponse = MockHTTPClient.Response(statusCode: .success, response: customerResponse)
        httpClient.mock(requestPath: path, response: customerInfoResponse)

        var firstCustomerInfo: CustomerInfo?
        var secondCustomerInfo: CustomerInfo?

        backend.getCustomerInfo(appUserID: Self.userID, completion: { (customerInfo, _) in
            firstCustomerInfo = customerInfo
        })

        backend.getCustomerInfo(appUserID: Self.userID, completion: { (customerInfo, _) in
            secondCustomerInfo = customerInfo
        })

        expect(firstCustomerInfo).toEventuallyNot(beNil())
        expect(secondCustomerInfo) == firstCustomerInfo

        expect(self.httpClient.calls.map { $0.request.path }) == [path]
    }
}
