//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostExternalPurchaseTokenTests.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendPostExternalPurchaseTokenTests: BaseBackendTests {

    private static let tokenID = "ept13dcbc01adaa44db9b1691a6be2f9929"
    private static let otherTokenID = "epta51d06bc57f344ffb386dff7e2353bea"

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testSendsTheExpectedRequest() throws {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success)
        )

        let error = self.postToken(appUserID: Self.userID,
                                   purchaseType: .linkOut,
                                   tokenID: Self.tokenID,
                                   token: "storekit-token")

        expect(error).to(beNil())
        expect(self.httpClient.calls).to(haveCount(1))

        let call = try XCTUnwrap(self.httpClient.calls.first)
        let path = try XCTUnwrap(call.request.path as? HTTPRequest.Path)
        expect(path) == .postExternalPurchaseToken
        expect(path.relativePath) == "/v1/external_purchase_tokens"
        expect(call.request.method.httpMethod) == "POST"

        let body = try XCTUnwrap(call.request.requestBody?.asJSONDictionary())
        expect(body["app_user_id"] as? String) == Self.userID
        expect(body["purchase_type"] as? String) == "LINK_OUT"
        expect(body["id"] as? String) == Self.tokenID
        expect(body["token"] as? String) == "storekit-token"
    }

    func testOmitsTheTokenWhenStoreKitDidNotProvideOne() throws {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success)
        )

        let error = self.postToken(appUserID: Self.userID,
                                   purchaseType: .linkOut,
                                   tokenID: Self.tokenID,
                                   token: nil)

        expect(error).to(beNil())

        let call = try XCTUnwrap(self.httpClient.calls.first)
        let body = try XCTUnwrap(call.request.requestBody?.asJSONDictionary())
        expect(body["app_user_id"] as? String) == Self.userID
        expect(body["id"] as? String) == Self.tokenID
        expect(body.keys).toNot(contain("token"))
    }

    /// The identifier travels with the token, so nothing is read back and any body has to be accepted.
    func testIgnoresTheResponseBody() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.response)
        )

        let error = self.postToken(appUserID: Self.userID,
                                   purchaseType: .linkOut,
                                   tokenID: Self.tokenID,
                                   token: "storekit-token")

        expect(error).to(beNil())
    }

    /// Storing a token is idempotent on Apple's purchase identifier: the first registration answers `201`
    /// and re-submitting the same token answers `200`, so both have to be read as success.
    func testAcceptsTheCreatedStatusOfAFirstRegistration() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .createdSuccess, response: Self.response)
        )

        let error = self.postToken(appUserID: Self.userID,
                                   purchaseType: .linkOut,
                                   tokenID: Self.tokenID,
                                   token: "storekit-token")

        expect(error).to(beNil())
    }

    func testForwardsANetworkError() {
        let networkError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(error: networkError)
        )

        let error = self.postToken(appUserID: Self.userID,
                                   purchaseType: .linkOut,
                                   tokenID: Self.tokenID,
                                   token: "storekit-token")

        expect(error) == .networkError(networkError)
    }

    func testSkipsTheBackendCallWhenTheAppUserIDIsEmpty() {
        let error = self.postToken(appUserID: "",
                                   purchaseType: .linkOut,
                                   tokenID: Self.tokenID,
                                   token: "storekit-token")

        expect(self.httpClient.calls).to(beEmpty())
        expect(error) == .missingAppUserID()
    }

    func testIsNotDelayed() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success)
        )

        expect(self.postToken(appUserID: Self.userID,
                              purchaseType: .linkOut,
                              tokenID: Self.tokenID,
                              token: "storekit-token")).to(beNil())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    /// Retrying a registration must not store it twice, so the identifier is what requests are reused on.
    func testIdenticalRequestsInFlightAreReusedForASingleCall() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, delay: .milliseconds(10))
        )

        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .linkOut,
                                                                tokenID: Self.tokenID,
                                                                token: "storekit-token") { _ in }
        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .linkOut,
                                                                tokenID: Self.tokenID,
                                                                token: "storekit-token") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(PostExternalPurchaseTokenOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    func testRequestsForDifferentTokenIDsAreNotReused() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, delay: .milliseconds(10))
        )

        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .linkOut,
                                                                tokenID: Self.tokenID,
                                                                token: "storekit-token") { _ in }
        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .linkOut,
                                                                tokenID: Self.otherTokenID,
                                                                token: "storekit-token") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

}

private extension BackendPostExternalPurchaseTokenTests {

    func postToken(
        appUserID: String,
        purchaseType: ExternalPurchaseTokenType,
        tokenID: String,
        token: String?
    ) -> BackendError? {
        var receivedError: BackendError?

        waitUntil { completed in
            self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: appUserID,
                                                                    purchaseType: purchaseType,
                                                                    tokenID: tokenID,
                                                                    token: token) { error in
                receivedError = error
                completed()
            }
        }

        return receivedError
    }

    static let response: [String: Any] = [
        "external_purchase_id": "b2158121-7af9-49d4-9561-1f14c46b3bc1",
        "id": "ept13dcbc01adaa44db9b1691a6be2f9929",
        "is_sandbox": false,
        "purchase_type": "LINK_OUT",
        "token_source": "APPLE_SDK"
    ]

}
