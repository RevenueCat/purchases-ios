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

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testSendsTheExpectedRequest() throws {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: "storekit-token")

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))

        let call = try XCTUnwrap(self.httpClient.calls.first)
        let path = try XCTUnwrap(call.request.path as? HTTPRequest.Path)
        expect(path) == .postExternalPurchaseToken
        expect(path.relativePath) == "/v1/external_purchase_tokens"
        expect(call.request.method.httpMethod) == "POST"

        let body = try XCTUnwrap(call.request.requestBody?.asJSONDictionary())
        expect(body["app_user_id"] as? String) == Self.userID
        expect(body["purchase_type"] as? String) == "LINK_OUT"
        expect(body["token"] as? String) == "storekit-token"
    }

    func testOmitsTheTokenWhenStoreKitDidNotProvideOne() throws {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.backendGeneratedResponse)
        )

        let result = self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: nil)

        expect(result).to(beSuccess())

        let call = try XCTUnwrap(self.httpClient.calls.first)
        let body = try XCTUnwrap(call.request.requestBody?.asJSONDictionary())
        expect(body["app_user_id"] as? String) == Self.userID
        expect(body.keys).toNot(contain("token"))
    }

    func testReturnsTheDecodedResponse() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: "storekit-token")

        expect(result).to(beSuccess())
        expect(result?.value?.id) == "ept13dcbc01adaa44db9b1691a6be2f9929"
        expect(result?.value?.externalPurchaseId) == "b2158121-7af9-49d4-9561-1f14c46b3bc1"
        expect(result?.value?.isSandbox) == false
        expect(result?.value?.purchaseType) == .linkOut
        expect(result?.value?.tokenSource) == "APPLE_SDK"
    }

    /// Storing a token is idempotent on Apple's purchase identifier: the first registration answers `201`
    /// and re-submitting the same token answers `200`, so both have to be read as success.
    func testAcceptsTheCreatedStatusOfAFirstRegistration() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .createdSuccess, response: Self.response)
        )

        let result = self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: "storekit-token")

        expect(result).to(beSuccess())
        expect(result?.value?.id) == "ept13dcbc01adaa44db9b1691a6be2f9929"
    }

    /// Only the identifier is needed to open checkout, so an otherwise sparse response must still decode.
    func testDecodesAResponseThatOnlyCarriesAnIdentifier() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: ["id": "ept13dcbc01adaa44db9b1691a6be2f9929"])
        )

        let result = self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: "storekit-token")

        expect(result).to(beSuccess())
        expect(result?.value?.id) == "ept13dcbc01adaa44db9b1691a6be2f9929"
        expect(result?.value?.externalPurchaseId).to(beNil())
        expect(result?.value?.purchaseType).to(beNil())
    }

    func testForwardsAnUnrecognizedPurchaseType() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: ["id": "ept1", "purchase_type": "SOMETHING_NEW"])
        )

        let result = self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: "storekit-token")

        expect(result?.value?.purchaseType) == ExternalPurchaseTokenType(rawValue: "SOMETHING_NEW")
    }

    func testForwardsANetworkError() {
        let error: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(error: error)
        )

        let result = self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: "storekit-token")

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(error)
    }

    func testSkipsTheBackendCallWhenTheAppUserIDIsEmpty() {
        let result = self.postToken(appUserID: "", purchaseType: .linkOut, token: "storekit-token")

        expect(self.httpClient.calls).to(beEmpty())
        expect(result?.error) == .missingAppUserID()
    }

    func testIsNotDelayed() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.response)
        )

        expect(self.postToken(appUserID: Self.userID, purchaseType: .linkOut, token: "storekit-token")).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    /// A double tap on the same button must not register the same token twice.
    func testIdenticalRequestsInFlightAreReusedForASingleCall() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.response, delay: .milliseconds(10))
        )

        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .linkOut,
                                                                token: "storekit-token") { _ in }
        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .linkOut,
                                                                token: "storekit-token") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(PostExternalPurchaseTokenOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    func testRequestsForDifferentPurchaseTypesAreNotReused() {
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.response, delay: .milliseconds(10))
        )

        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .linkOut,
                                                                token: "storekit-token") { _ in }
        self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: Self.userID,
                                                                purchaseType: .inApp,
                                                                token: "storekit-token") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

}

private extension BackendPostExternalPurchaseTokenTests {

    func postToken(
        appUserID: String,
        purchaseType: ExternalPurchaseTokenType,
        token: String?
    ) -> Result<ExternalPurchaseTokenResponse, BackendError>? {
        return waitUntilValue { completed in
            self.externalPurchaseTokenAPI.postExternalPurchaseToken(appUserID: appUserID,
                                                                    purchaseType: purchaseType,
                                                                    token: token,
                                                                    completion: completed)
        }
    }

    static let response: [String: Any] = [
        "external_purchase_id": "b2158121-7af9-49d4-9561-1f14c46b3bc1",
        "id": "ept13dcbc01adaa44db9b1691a6be2f9929",
        "is_sandbox": false,
        "purchase_type": "LINK_OUT",
        "token_source": "APPLE_SDK"
    ]

    static let backendGeneratedResponse: [String: Any] = [
        "external_purchase_id": "$rc-81bc448a-1322-49f2-b46e-5683f317169b",
        "id": "epta51d06bc57f344ffb386dff7e2353bea",
        "is_sandbox": false,
        "purchase_type": "LINK_OUT",
        "token_source": "RC_GENERATED"
    ]

}
