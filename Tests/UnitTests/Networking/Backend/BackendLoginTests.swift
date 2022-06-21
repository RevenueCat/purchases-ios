//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendLoginTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendLoginTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testLoginMakesRightCalls() {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID)
        var completionCalled = false

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testLoginPassesNetworkErrorIfCouldntCommunicate() throws {
        let newAppUserID = "new id"

        let stubbedError: NetworkError = .unexpectedResponse(nil)
        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, error: stubbedError)

        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult).to(beFailure())
        expect(receivedResult?.error) == .networkError(stubbedError)
    }

    func testLoginCallsCompletionWithErrorIfCustomerInfoIsEmpty() throws {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"

        _ = self.mockLoginRequest(appUserID: currentAppUserID, statusCode: .createdSuccess)

        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult?.value).to(beNil())

        let receivedError = try XCTUnwrap(receivedResult?.error)

        switch receivedError {
        case .networkError(.decoding): break // correct error
        default: fail("Unexpectede error: \(receivedError)")
        }
    }

    func testLoginCallsCompletionWithCustomerInfoAndCreatedFalseIf201() throws {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: Self.mockCustomerInfoData)

        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult?.value?.created) == true
        expect(receivedResult?.value?.info) == CustomerInfo(testData: Self.mockCustomerInfoData)
    }

    func testLoginCallsCompletionWithCustomerInfoAndCreatedFalseIf200() throws {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .success,
                                  response: Self.mockCustomerInfoData)

        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())

        expect(receivedResult?.value?.created) == false
        expect(receivedResult?.value?.info) == CustomerInfo(testData: Self.mockCustomerInfoData)
    }

    func testLoginCachesForSameUserIDs() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: Self.mockCustomerInfoData)

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _  in }
        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _  in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testLoginDoesntCacheForDifferentNewUserID() {
        let newAppUserID = "new id"
        let secondNewAppUserID = "new id 2"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: Self.mockCustomerInfoData)

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _ in }
        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: secondNewAppUserID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testLoginDoesntCacheForDifferentCurrentUserID() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        let currentAppUserID2 = "old id 2"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: Self.mockCustomerInfoData)

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _ in }
        self.identity.logIn(currentAppUserID: currentAppUserID2, newAppUserID: newAppUserID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testLoginCallsAllCompletionBlocksInCache() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: Self.mockCustomerInfoData)

        var completion1Called = false
        var completion2Called = false

        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _ in
            completion1Called = true
        }
        self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _ in
            completion2Called = true
        }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(completion1Called).toEventually(beTrue())
        expect(completion2Called).toEventually(beTrue())
    }

}

private extension BackendLoginTests {

    func mockLoginRequest(appUserID: String,
                          statusCode: HTTPStatusCode = .success,
                          response: [String: Any] = [:]) -> HTTPRequest.Path {
        let path: HTTPRequest.Path = .logIn
        let response = MockHTTPClient.Response(statusCode: statusCode, response: response)

        self.httpClient.mock(requestPath: path, response: response)

        return path
    }

    func mockLoginRequest(appUserID: String,
                          error: NetworkError) -> HTTPRequest.Path {
        let path: HTTPRequest.Path = .logIn
        let response =  MockHTTPClient.Response(error: error)

        self.httpClient.mock(requestPath: path, response: response)

        return path
    }

    static let mockCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "subscriptions": [:],
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "other_purchases": [:]
        ]
    ]

}
