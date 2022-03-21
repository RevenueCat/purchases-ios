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

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testLoginPassesNetworkErrorIfCouldntCommunicate() throws {
        let newAppUserID = "new id"

        let errorCode = 123465
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain, code: errorCode, userInfo: [:])
        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, response: .failure(stubbedError))

        var receivedResult: Result<(info: CustomerInfo, created: Bool), Error>?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult?.value).to(beNil())

        let receivedNSError = try XCTUnwrap(receivedResult?.error as NSError?)
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
        let expectedUserInfoError = try XCTUnwrap(receivedNSError.userInfo[NSUnderlyingErrorKey] as? NSError)
        expect(expectedUserInfoError) == stubbedError
    }

    func testLoginPassesErrors() throws {
        let newAppUserID = "new id"

        let errorCode = 123465
        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: errorCode,
                                   userInfo: [:])
        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID, response: .failure(stubbedError))

        var receivedResult: Result<(info: CustomerInfo, created: Bool), Error>?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult?.value).to(beNil())

        let receivedNSError = try XCTUnwrap(receivedResult?.error as NSError?)
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
        let expectedUserInfoError = try XCTUnwrap(receivedNSError.userInfo[NSUnderlyingErrorKey] as? NSError)
        expect(expectedUserInfoError) == stubbedError
    }

    func testLoginConsidersErrorStatusCodesAsErrors() throws {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"
        let underlyingErrorMessage = "header fields too large"
        let underlyingErrorCode = BackendErrorCode.cannotTransferPurchase.rawValue
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: 431,
                                  response: .success(["code": underlyingErrorCode, "message": underlyingErrorMessage]))

        var receivedResult: Result<(info: CustomerInfo, created: Bool), Error>?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult?.value).to(beNil())

        let receivedNSError = try XCTUnwrap(receivedResult?.error as NSError?)
        expect(receivedNSError.code) == ErrorCode.networkError.rawValue

        // custom errors get wrapped in a backendError
        let backendUnderlyingError = receivedNSError.userInfo[NSUnderlyingErrorKey] as? NSError
        expect(backendUnderlyingError).toNot(beNil())
        let underlyingError = backendUnderlyingError?.userInfo[NSUnderlyingErrorKey] as? NSError
        expect(underlyingError?.code) == underlyingErrorCode
        expect(underlyingError?.localizedDescription) == underlyingErrorMessage
    }

    func testLoginCallsCompletionWithErrorIfCustomerInfoNil() throws {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID, statusCode: .createdSuccess)

        var receivedResult: Result<(info: CustomerInfo, created: Bool), Error>?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult?.value).to(beNil())

        let receivedNSError = try XCTUnwrap(receivedResult?.error as NSError?)
        expect(receivedNSError.code) == ErrorCode.unexpectedBackendResponseError.rawValue
    }

    func testLoginCallsCompletionWithCustomerInfoAndCreatedFalseIf201() throws {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: .success(Self.mockCustomerInfoData))

        var receivedResult: Result<(info: CustomerInfo, created: Bool), Error>?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { result in
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
                                  response: .success(Self.mockCustomerInfoData))

        var receivedResult: Result<(info: CustomerInfo, created: Bool), Error>?

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { result in
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
                                  response: .success(Self.mockCustomerInfoData))

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _  in }
        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _  in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testLoginDoesntCacheForDifferentNewUserID() {
        let newAppUserID = "new id"
        let secondNewAppUserID = "new id 2"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: .success(Self.mockCustomerInfoData))

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _ in }
        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: secondNewAppUserID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testLoginDoesntCacheForDifferentCurrentUserID() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        let currentAppUserID2 = "old id 2"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: .success(Self.mockCustomerInfoData))

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _ in }
        backend.logIn(currentAppUserID: currentAppUserID2,
                      newAppUserID: newAppUserID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testLoginCallsAllCompletionBlocksInCache() {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: .success(Self.mockCustomerInfoData))

        var completion1Called = false
        var completion2Called = false

        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _ in
            completion1Called = true
        }
        backend.logIn(currentAppUserID: currentAppUserID,
                      newAppUserID: newAppUserID) { _ in
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
                          response: Result<[String: Any], Error> = .success([:])) -> HTTPRequest.Path {
        let path: HTTPRequest.Path = .logIn
        let response = MockHTTPClient.Response(statusCode: statusCode, response: response)

        self.httpClient.mock(requestPath: path, response: response)

        return path
    }

    static let mockCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "subscriptions": [],
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "other_purchases": [:]
        ]
    ]

}
