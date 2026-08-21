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

class BaseBackendLoginTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

}

class BackendLoginTests: BaseBackendLoginTests {

    func testLoginMakesRightCalls() {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID)

        waitUntil { completed in
            self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID) { _ in
                completed()
            }
        }
    }

    func testLoginPassesNetworkErrorIfCouldntCommunicate() throws {
        let newAppUserID = "new id"

        let stubbedError: NetworkError = .unexpectedResponse(nil)
        let currentAppUserID = "old id"
        _ = mockLoginRequest(appUserID: currentAppUserID, error: stubbedError)

        let receivedResult = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID, completion: completed)
        }

        expect(receivedResult).to(beFailure())
        expect(receivedResult?.error) == .networkError(stubbedError)
    }

    func testLoginCallsCompletionWithErrorIfCustomerInfoIsEmpty() throws {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"

        _ = self.mockLoginRequest(appUserID: currentAppUserID, statusCode: .createdSuccess)

        let receivedResult = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID, completion: completed)
        }

        expect(receivedResult).to(beFailure())
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

        let receivedResult = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID, completion: completed)
        }

        expect(receivedResult?.value?.created) == true
        expect(receivedResult?.value?.info) == CustomerInfo(testData: Self.mockCustomerInfoData)
    }

    func testLoginCallsCompletionWithCustomerInfoAndCreatedFalseIf200() throws {
        let newAppUserID = "new id"

        let currentAppUserID = "old id"
        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .success,
                                  response: Self.mockCustomerInfoData)

        let receivedResult = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: currentAppUserID, newAppUserID: newAppUserID, completion: completed)
        }

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

// swiftlint:disable:next type_name
class BackendLoginWithSignatureVerificationTests: BaseBackendLoginTests {

    override var verificationMode: Configuration.EntitlementVerificationMode { .informational }

    func testLoginWithVerifiedResponse() {
        let newAppUserID = "new id"
        let currentAppUserID = "old id"

        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: Self.mockCustomerInfoData,
                                  verificationResult: .verified)

        let result = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: currentAppUserID,
                                newAppUserID: newAppUserID,
                                completion: completed)
        }

        expect(result).to(beSuccess())
        expect(result?.value?.info.entitlements.verification) == .verified
    }

    func testLoginWithFailedVerification() {
        let newAppUserID = "F72BF276-CD70-4C27-BCD2-FC1EFD988FA3"
        let currentAppUserID = "$RCAnonymousID:6b2787de2fb848a8b403a45f695ee74f"

        _ = self.mockLoginRequest(appUserID: currentAppUserID,
                                  statusCode: .createdSuccess,
                                  response: Self.mockCustomerInfoData,
                                  verificationResult: .failed)

        let result = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: currentAppUserID,
                                newAppUserID: newAppUserID,
                                completion: completed)
        }

        expect(result).to(beSuccess())
        expect(result?.value?.info.entitlements.verification) == .failed
    }

}

class BackendLoginWithAttributesTests: BaseBackendLoginTests {

    private static let attribute = SubscriberAttribute(withKey: "plan", value: "annual")
    private static let previousAttribute = SubscriberAttribute(withKey: "channel", value: "tiktok")

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.httpClient.disableSnapshotTesting()
    }

    func testLoginSendsBothAttributeBuckets() throws {
        _ = self.mockLoginRequest(appUserID: "old id",
                                  statusCode: .success,
                                  response: Self.mockCustomerInfoData)

        waitUntil { completed in
            self.identity.logIn(currentAppUserID: "old id",
                                newAppUserID: "new id",
                                attributes: ["plan": Self.attribute],
                                previousUnsyncedAttributes: ["channel": Self.previousAttribute]) { _ in
                completed()
            }
        }

        let body = try self.encodedBodyOfFirstCall()
        expect(body["attributes"] as? [String: NSObject]) == [
            "plan": ["value": "annual",
                     "updated_at_ms": Self.attribute.setTime.millisecondsSince1970] as NSDictionary
        ]
        expect(body["previous_unsynced_attributes"] as? [String: NSObject]) == [
            "channel": ["value": "tiktok",
                        "updated_at_ms": Self.previousAttribute.setTime.millisecondsSince1970] as NSDictionary
        ]
    }

    func testLoginOmitsAttributeKeysWhenThereIsNothingToSend() throws {
        _ = self.mockLoginRequest(appUserID: "old id",
                                  statusCode: .success,
                                  response: Self.mockCustomerInfoData)

        waitUntil { completed in
            self.identity.logIn(currentAppUserID: "old id", newAppUserID: "new id") { _ in
                completed()
            }
        }

        let body = try self.encodedBodyOfFirstCall()
        expect(Set(body.keys)) == ["app_user_id", "new_app_user_id"]
    }

    func testLoginDoesNotHashAttributesInPostParamsHeader() throws {
        let body = LogInOperation.Body(appUserID: "old id",
                                       newAppUserID: "new id",
                                       attributes: ["plan": Self.attribute],
                                       previousUnsyncedAttributes: ["channel": Self.previousAttribute])

        expect(body.contentForSignature.map(\.key)) == ["app_user_id", "new_app_user_id"]
    }

    func testLoginStillCachesForTheSameAttributes() {
        _ = self.mockLoginRequest(appUserID: "old id",
                                  statusCode: .success,
                                  response: Self.mockCustomerInfoData)

        for _ in 0..<2 {
            self.identity.logIn(currentAppUserID: "old id",
                                newAppUserID: "new id",
                                attributes: ["plan": Self.attribute],
                                previousUnsyncedAttributes: ["channel": Self.previousAttribute]) { _ in }
        }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testLoginDoesNotCacheForDifferentAttributes() {
        _ = self.mockLoginRequest(appUserID: "old id",
                                  statusCode: .success,
                                  response: Self.mockCustomerInfoData)

        self.identity.logIn(currentAppUserID: "old id",
                            newAppUserID: "new id",
                            attributes: ["plan": Self.attribute],
                            previousUnsyncedAttributes: [:]) { _ in }
        self.identity.logIn(currentAppUserID: "old id",
                            newAppUserID: "new id",
                            attributes: [:],
                            previousUnsyncedAttributes: [:]) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testLoginParsesAttributesErrorResponseWithoutFailing() throws {
        var response = Self.mockCustomerInfoData
        response["attributes_error_response"] = [
            "attributes": [
                "code": BackendErrorCode.invalidSubscriberAttributes.rawValue,
                "message": "Some subscriber attributes keys were unable to be saved.",
                "attribute_errors": [["key_name": "$$invalid", "message": "Invalid key"]]
            ] as [String: Any],
            "previous_unsynced_attributes": [
                "code": BackendErrorCode.internalServerError.rawValue,
                "message": "Subscriber not found."
            ] as [String: Any]
        ]

        _ = self.mockLoginRequest(appUserID: "old id", statusCode: .success, response: response)

        let result = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: "old id", newAppUserID: "new id", completion: completed)
        }

        expect(result).to(beSuccess())

        let attributesErrorResponse = try XCTUnwrap(result?.value?.attributesErrorResponse)
        expect(attributesErrorResponse.attributes?.code) == .invalidSubscriberAttributes
        expect(attributesErrorResponse.attributes?.attributeErrors) == ["$$invalid": "Invalid key"]
        expect(attributesErrorResponse.previousUnsyncedAttributes?.code) == .internalServerError
    }

    func testLoginHasNoAttributesErrorResponseWhenBackendDoesNotReturnOne() {
        _ = self.mockLoginRequest(appUserID: "old id",
                                  statusCode: .success,
                                  response: Self.mockCustomerInfoData)

        let result = waitUntilValue { completed in
            self.identity.logIn(currentAppUserID: "old id", newAppUserID: "new id", completion: completed)
        }

        expect(result).to(beSuccess())
        expect(result?.value?.attributesErrorResponse).to(beNil())
    }

    private func encodedBodyOfFirstCall() throws -> [String: Any] {
        let body = try XCTUnwrap(self.httpClient.calls.onlyElement?.request.requestBody as? LogInOperation.Body)

        return try XCTUnwrap(
            try JSONSerialization.jsonObject(with: JSONEncoder.default.encode(body)) as? [String: Any]
        )
    }

}

private extension IdentityAPI {

    /// Convenience for the tests that don't exercise the inline attributes.
    func logIn(currentAppUserID: String,
               newAppUserID: String,
               completion: @escaping LogInResponseHandler) {
        self.logIn(currentAppUserID: currentAppUserID,
                   newAppUserID: newAppUserID,
                   attributes: [:],
                   previousUnsyncedAttributes: [:],
                   completion: completion)
    }

}

private extension BaseBackendLoginTests {

    func mockLoginRequest(
        appUserID: String,
        statusCode: HTTPStatusCode = .success,
        response: [String: Any] = [:],
        verificationResult: VerificationResult = .notRequested
    ) -> HTTPRequest.Path {
        let path: HTTPRequest.Path = .logIn
        let response = MockHTTPClient.Response(statusCode: statusCode,
                                               response: response,
                                               verificationResult: verificationResult)

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
            "subscriptions": [:] as [String: Any],
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "other_purchases": [:] as [String: Any]
        ] as [String: Any]
    ]

}
