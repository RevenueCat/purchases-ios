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

        let customerInfo = waitUntilValue { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false, completion: completed)
        }

        expect(customerInfo).to(beSuccess())

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            expect(customerInfo?.value?.entitlements.verification) == .notRequested
        }
    }

    func testHandlesGetCustomerInfoErrors() throws {
        let mockedError = NetworkError.unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false, completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testHandlesInvalidJSON() {
        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: ["sjkaljdklsjadkjs": ""])
        )

        let result = waitUntilValue { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false, completion: completed)
        }

        guard case .failure(.networkError(.decoding)) = result else {
            fail("Unexpected result: \(String(describing: result))")
            return
        }
    }

    func testGetCustomerInfoDoesNotMakeTwoRequests() {
        let customerResponse: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "user",
                "subscriptions": [:] as [String: Any]
            ] as [String: Any]
        ]
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: Self.userID)
        let customerInfoResponse = MockHTTPClient.Response(statusCode: .success, response: customerResponse)
        httpClient.mock(requestPath: path, response: customerInfoResponse)

        let firstResult: Atomic<Result<CustomerInfo, BackendError>?> = nil
        let secondResult: Atomic<Result<CustomerInfo, BackendError>?> = nil

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) {
            firstResult.value = $0
        }

        backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false) {
            secondResult.value = $0
        }

        expect(firstResult.value).toEventuallyNot(beNil())
        expect(firstResult.value).to(beSuccess())
        expect(secondResult.value?.value) == firstResult.value?.value

        expect(self.httpClient.calls.map { $0.request.path as? HTTPRequest.Path }) == [path]
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testGetCustomerInfoWithVerifiedResponse() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.validCustomerResponse, verificationResult: .verified)
        )

        let customerInfo = waitUntilValue { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false, completion: completed)
        }

        expect(customerInfo).to(beSuccess())
        expect(customerInfo?.value?.entitlements.verification) == .verified
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testGetCustomerInfoWithFailedVerification() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.validCustomerResponse,
                            verificationResult: .failed)
        )

        let customerInfo = waitUntilValue { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false, completion: completed)
        }

        expect(customerInfo).to(beSuccess())
        expect(customerInfo?.value?.entitlements.verification) == .failed
    }

    func testUpdatesRequestDateFromResponseHeader() {
        let requestDate = Date().addingTimeInterval(-10000)

        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(
                statusCode: .success,
                response: Self.validCustomerResponse,
                responseHeaders: [
                    HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate.millisecondsSince1970)
                ]
            )
        )

        let response = waitUntilValue { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false, completion: completed)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.requestDate).to(beCloseTo(requestDate, within: 0.01))
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class BackendGetCustomerInfoSignatureTests: BaseBackendTests {

    override var verificationMode: Configuration.EntitlementVerificationMode {
        return .informational
    }

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    override func setUpWithError() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        try super.setUpWithError()
    }

    func testSendsNonceWhenEnabled() {
        self.httpClient.mock(
            requestPath: .getCustomerInfo(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let result = waitUntilValue { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, withRandomDelay: false, completion: completed)
        }
        let request = self.httpClient.calls.onlyElement

        expect(result).to(beSuccess())
        expect(request?.request.nonce).toNot(beNil())
    }

}
