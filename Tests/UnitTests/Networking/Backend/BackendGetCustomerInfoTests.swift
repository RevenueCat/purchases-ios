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

        backend.getCustomerInfo(appUserID: Self.userID) { _ in }
        backend.getCustomerInfo(appUserID: Self.userID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testDoesntCacheCustomerGetsForSameCustomer() {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: Self.userID), response: response)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID2), response: response)

        backend.getCustomerInfo(appUserID: Self.userID) { _ in }
        backend.getCustomerInfo(appUserID: userID2) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetCustomerCallsBackendProperly() throws {
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)

        self.httpClient.mock(requestPath: path, response: response)

        backend.getCustomerInfo(appUserID: Self.userID) { _ in }
        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetsCustomerInfo() {
        httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var customerInfo: Result<CustomerInfo, Error>?

        backend.getCustomerInfo(appUserID: Self.userID) { result in
            customerInfo = result
        }

        expect(customerInfo).toEventuallyNot(beNil())
        expect(customerInfo?.value).toNot(beNil())
    }

    func testEncodesCustomerUserID() {
        let encodeableUserID = "userid with spaces"
        let encodedUserID = "userid%20with%20spaces"
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)

        httpClient.mock(requestPath: .getCustomerInfo(appUserID: encodedUserID), response: response)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: encodeableUserID),
                        response: .init(error: ErrorUtils.networkError(withUnderlyingError: ErrorUtils.unknownError())))

        var customerInfo: Result<CustomerInfo, Error>?

        backend.getCustomerInfo(appUserID: encodeableUserID) { result in
            customerInfo = result
        }

        expect(customerInfo).toEventuallyNot(beNil())
        expect(customerInfo?.value).toNot(beNil())
    }

    func testHandlesGetCustomerInfoErrors() throws {
        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .notFoundError, response: [:])
        )

        var result: Result<CustomerInfo, NSError>?

        backend.getCustomerInfo(appUserID: Self.userID) {
            result = $0.mapError { $0 as NSError }
        }

        expect(result).toEventuallyNot(beNil())

        let error = try XCTUnwrap(result?.error)
        expect(error.domain) == RCPurchasesErrorCodeDomain
        expect(error.userInfo["finishable"] as? Bool) == true

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)
        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
    }

    func testHandlesInvalidJSON() {
        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: ["sjkaljdklsjadkjs": ""])
        )

        var result: Result<CustomerInfo, NSError>?

        backend.getCustomerInfo(appUserID: Self.userID) {
            result = $0.mapError { $0 as NSError }
        }

        expect(result).toEventuallyNot(beNil())
        expect(result?.error?.domain) == RCPurchasesErrorCodeDomain
        expect(result?.error?.code) == ErrorCode.unknownBackendError.rawValue
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

        var firstResult: Result<CustomerInfo, Error>?
        var secondResult: Result<CustomerInfo, Error>?

        backend.getCustomerInfo(appUserID: Self.userID) {
            firstResult = $0
        }

        backend.getCustomerInfo(appUserID: Self.userID) {
            secondResult = $0
        }

        expect(firstResult).toEventuallyNot(beNil())
        expect(firstResult?.value).toNot(beNil())
        expect(secondResult?.value) == firstResult?.value

        expect(self.httpClient.calls.map { $0.request.path }) == [path]
    }
}
