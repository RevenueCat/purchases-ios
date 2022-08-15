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

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) { _ in }
        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testDoesntCacheCustomerGetsForSameCustomer() {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)
        let userID2 = "user_id_2"
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: Self.userID), response: response)
        httpClient.mock(requestPath: .getCustomerInfo(appUserID: userID2), response: response)

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) { _ in }
        backend.getCustomerInfo(appUserID: userID2, withRandomDelay: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetCustomerCallsBackendProperly() throws {
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.validCustomerResponse)

        self.httpClient.mock(requestPath: path, response: response)

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) { _ in }
        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetsCustomerInfo() {
        httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        var customerInfo: Result<CustomerInfo, BackendError>?

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) { result in
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
                        response: .init(error: .unexpectedResponse(nil)))

        var customerInfo: Result<CustomerInfo, BackendError>?

        backend.getCustomerInfo(appUserID: encodeableUserID, withRandomDelay: false) { result in
            customerInfo = result
        }

        expect(customerInfo).toEventuallyNot(beNil())
        expect(customerInfo?.value).toNot(beNil())
    }

    func testHandlesGetCustomerInfoErrors() throws {
        let mockedError = NetworkError.unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        var result: Result<CustomerInfo, BackendError>?

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) {
            result = $0
        }

        expect(result).toEventuallyNot(beNil())
        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testHandlesInvalidJSON() {
        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: ["sjkaljdklsjadkjs": ""])
        )

        var result: Result<CustomerInfo, BackendError>?

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) {
            result = $0
        }

        expect(result).toEventuallyNot(beNil())

        guard case .failure(.networkError(.decoding)) = result else {
            fail("Unexpected result: \(result!)")
            return
        }
    }

    func testGetCustomerInfoDoesNotMakeTwoRequests() {
        let customerResponse: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "user",
                "subscriptions": [:]
            ]
        ]
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)
        let customerInfoResponse = MockHTTPClient.Response(statusCode: .success, response: customerResponse)
        httpClient.mock(requestPath: path, response: customerInfoResponse)

        var firstResult: Result<CustomerInfo, BackendError>?
        var secondResult: Result<CustomerInfo, BackendError>?

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) {
            firstResult = $0
        }

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) {
            secondResult = $0
        }

        expect(firstResult).toEventuallyNot(beNil())
        expect(firstResult?.value).toNot(beNil())
        expect(secondResult?.value) == firstResult?.value

        expect(self.httpClient.calls.map { $0.request.path }) == [path]
    }
}
