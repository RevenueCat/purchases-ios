//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendTokenLoginTests.swift
//
//  Created by RevenueCat on 8/18/26.

import Foundation
import Nimble
import XCTest

@testable @_spi(Internal) import RevenueCat

class BaseBackendTokenLoginTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        // These tests assert on the decoded response/request bodies directly, and there's no
        // recorded snapshot fixture for the new token endpoints.
        self.httpClient.disableSnapshotTesting()
    }

}

class BackendTokenLoginTests: BaseBackendTokenLoginTests {

    func testLoginFailsWithoutANetworkCallWhenTheIdentityTokenIsInvalid() {
        // An empty token payload fails `IdentityAuthToken.validate()` before any request is made.
        let receivedResult = waitUntilValue { completed in
            self.token.logIn(currentAppUserID: "old-user", identity: .signInWithApple(Data()), completion: completed)
        }

        expect(receivedResult?.error) == .invalidAuthorizationToken()
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testLoginPassesNetworkErrorIfCouldntCommunicate() {
        let stubbedError: NetworkError = .unexpectedResponse(nil)
        self.mockTokenLoginRequest(error: stubbedError)

        let receivedResult = waitUntilValue { completed in
            self.token.logIn(currentAppUserID: "old-user", identity: .anonymous, completion: completed)
        }

        expect(receivedResult?.error) == .networkError(stubbedError)
    }

    func testLoginFailsWhenTheAccessTokenIsNotAValidJWT() {
        self.mockTokenLoginRequest(response: [
            "access_token": "not-a-jwt",
            "scope": "openid offline_access",
            "expires_in": 3600
        ])

        let receivedResult = waitUntilValue { completed in
            self.token.logIn(currentAppUserID: "old-user", identity: .anonymous, completion: completed)
        }

        expect(receivedResult?.error) == .unexpectedBackendResponse(.loginResponseDecoding)
    }

    func testLoginFailsWhenTheAccessTokenJWTIsMissingTheAppUserIDClaim() throws {
        let accessToken = try Self.makeAccessToken(appUserID: nil, extraClaims: ["sub": "abc"])
        self.mockTokenLoginRequest(response: [
            "access_token": accessToken,
            "scope": "openid offline_access",
            "expires_in": 3600
        ])

        let receivedResult = waitUntilValue { completed in
            self.token.logIn(currentAppUserID: "old-user", identity: .anonymous, completion: completed)
        }

        expect(receivedResult?.error) == .unexpectedBackendResponse(.loginResponseDecoding,
                                                                    extraContext: "JWT missing RC user ID")
    }

    func testLoginSucceedsAndSavesTokensForAnAnonymousIdentity() throws {
        let accessToken = try Self.makeAccessToken(appUserID: "rc-user-id")
        self.mockTokenLoginRequest(response: [
            "access_token": accessToken,
            "refresh_token": "refresh-token-value",
            "id_token": "id-token-value",
            "scope": "openid offline_access",
            "expires_in": 3600
        ])

        let receivedResult = waitUntilValue { completed in
            self.token.logIn(currentAppUserID: "old-user", identity: .anonymous, completion: completed)
        }

        expect(receivedResult?.value?.1) == "rc-user-id"
        expect(receivedResult?.value?.0.accessToken) == accessToken

        let tokenManager = try XCTUnwrap(self.httpClient.tokenManager as? MockTokenManager)
        expect(tokenManager.invokedSaveTokens) == true
        expect(tokenManager.invokedSaveTokensParametersList.last?.userID) == "rc-user-id"
        expect(tokenManager.invokedSaveTokensParametersList.last?.accessToken) == accessToken
        expect(tokenManager.invokedSaveTokensParametersList.last?.refreshToken) == "refresh-token-value"
        expect(tokenManager.invokedSaveTokensParametersList.last?.idToken) == "id-token-value"
    }

    func testLoginDoesNotSaveTokensWhenItFails() {
        self.mockTokenLoginRequest(error: .unexpectedResponse(nil))

        waitUntil { completed in
            self.token.logIn(currentAppUserID: "old-user", identity: .anonymous) { _ in completed() }
        }

        let tokenManager = self.httpClient.tokenManager as? MockTokenManager
        expect(tokenManager?.invokedSaveTokens) == false
    }

    func testLoginIncludesTheLinkToIDTokenFromThePreviousUser() throws {
        let tokenManager = try XCTUnwrap(self.httpClient.tokenManager as? MockTokenManager)
        tokenManager.stubbedIDToken = "existing-id-token"

        let accessToken = try Self.makeAccessToken(appUserID: "rc-user-id")
        self.mockTokenLoginRequest(response: [
            "access_token": accessToken,
            "scope": "openid offline_access",
            "expires_in": 3600
        ])

        waitUntil { completed in
            self.token.logIn(currentAppUserID: "old-user",
                             identity: .signInWithApple(Data("apple-identity-token".utf8))) { _ in completed() }
        }

        expect(tokenManager.invokedIDTokenForParametersList) == ["old-user"]

        let body = try XCTUnwrap(self.httpClient.calls.last?.request.requestBody as? TokenLogInOperation.StandardBody)
        expect(body.method) == "apple"
        expect(body.linkToID) == "existing-id-token"
    }

    // MARK: - Linked identity

    func testAnonymousLoginFromAnAnonymousUserIncludesTheCurrentAppUserID() throws {
        let tokenManager = try XCTUnwrap(self.httpClient.tokenManager as? MockTokenManager)
        tokenManager.stubbedIDToken = "existing-id-token"
        try self.mockSuccessfulTokenLogin()

        waitUntil { completed in
            self.token.logIn(currentAppUserID: Self.anonymousAppUserID, identity: .anonymous) { _ in completed() }
        }

        let body = try XCTUnwrap(self.httpClient.calls.last?.request.requestBody as? TokenLogInOperation.AnonymousBody)
        expect(body.method) == "anonymous"
        expect(body.appUserID) == Self.anonymousAppUserID
        expect(tokenManager.invokedIDTokenFor) == false
    }

    func testAnonymousLoginFromANonAnonymousUserDoesNotIncludeAnAppUserID() throws {
        let tokenManager = try XCTUnwrap(self.httpClient.tokenManager as? MockTokenManager)
        tokenManager.stubbedIDToken = "existing-id-token"
        try self.mockSuccessfulTokenLogin()

        waitUntil { completed in
            self.token.logIn(currentAppUserID: "identified-user", identity: .anonymous) { _ in completed() }
        }

        let body = try XCTUnwrap(self.httpClient.calls.last?.request.requestBody as? TokenLogInOperation.AnonymousBody)
        expect(body.appUserID).to(beNil())
        expect(tokenManager.invokedIDTokenFor) == false
    }

    func testAnonymousLoginDoesNotTreatAMalformedAnonymousIDAsAnonymous() throws {
        try self.mockSuccessfulTokenLogin()

        waitUntil { completed in
            self.token.logIn(currentAppUserID: "$RCAnonymousID:not-a-valid-id", identity: .anonymous) { _ in
                completed()
            }
        }

        let body = try XCTUnwrap(self.httpClient.calls.last?.request.requestBody as? TokenLogInOperation.AnonymousBody)
        expect(body.appUserID).to(beNil())
    }

    func testNonAnonymousLoginFromAnAnonymousUserLinksTheIDTokenNotTheAppUserID() throws {
        let tokenManager = try XCTUnwrap(self.httpClient.tokenManager as? MockTokenManager)
        tokenManager.stubbedIDToken = "existing-id-token"
        try self.mockSuccessfulTokenLogin()

        waitUntil { completed in
            self.token.logIn(currentAppUserID: Self.anonymousAppUserID,
                             identity: .oidc(Data("oidc-identity-token".utf8))) { _ in completed() }
        }

        expect(tokenManager.invokedIDTokenForParametersList) == [Self.anonymousAppUserID]

        let body = try XCTUnwrap(self.httpClient.calls.last?.request.requestBody as? TokenLogInOperation.StandardBody)
        expect(body.method) == "oidc"
        expect(body.linkToID) == "existing-id-token"
    }

    func testNonAnonymousLoginWithoutAnExistingIDTokenDoesNotLinkAnything() throws {
        let tokenManager = try XCTUnwrap(self.httpClient.tokenManager as? MockTokenManager)
        tokenManager.stubbedIDToken = nil
        try self.mockSuccessfulTokenLogin()

        waitUntil { completed in
            self.token.logIn(currentAppUserID: Self.anonymousAppUserID,
                             identity: .firebase(Data("firebase-identity-token".utf8))) { _ in completed() }
        }

        let body = try XCTUnwrap(self.httpClient.calls.last?.request.requestBody as? TokenLogInOperation.StandardBody)
        expect(body.method) == "firebase"
        expect(body.linkToID).to(beNil())
    }

    func testLoginCachesForTheSameIdentityAndCurrentAppUserID() throws {
        let accessToken = try Self.makeAccessToken(appUserID: "rc-user-id")
        self.mockTokenLoginRequest(response: [
            "access_token": accessToken,
            "scope": "openid offline_access",
            "expires_in": 3600
        ])

        self.token.logIn(currentAppUserID: "old-user", identity: .anonymous) { _ in }
        self.token.logIn(currentAppUserID: "old-user", identity: .anonymous) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testLoginDoesNotCacheForDifferentIdentityTokens() throws {
        let accessToken = try Self.makeAccessToken(appUserID: "rc-user-id")
        self.mockTokenLoginRequest(response: [
            "access_token": accessToken,
            "scope": "openid offline_access",
            "expires_in": 3600
        ])

        self.token.logIn(currentAppUserID: "old-user",
                         identity: .signInWithApple(Data("token-a".utf8))) { _ in }
        self.token.logIn(currentAppUserID: "old-user",
                         identity: .signInWithApple(Data("token-b".utf8))) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

}

private extension BaseBackendTokenLoginTests {

    static let anonymousAppUserID = "$RCAnonymousID:6b2787de2fb848a8b403a45f695ee74f"

    func mockSuccessfulTokenLogin() throws {
        self.mockTokenLoginRequest(response: [
            "access_token": try Self.makeAccessToken(appUserID: "rc-user-id"),
            "scope": "openid offline_access",
            "expires_in": 3600
        ])
    }

    func mockTokenLoginRequest(response: [String: Any], statusCode: HTTPStatusCode = .success) {
        let mockResponse = MockHTTPClient.Response(statusCode: statusCode, response: response)
        self.httpClient.mock(requestPath: .tokenLogin, response: mockResponse)
    }

    func mockTokenLoginRequest(error: NetworkError) {
        self.httpClient.mock(requestPath: .tokenLogin, response: .init(error: error))
    }

    /// Builds an unsigned (`alg: "none"`) JWT string, suitable for exercising `TokenLogInOperation`'s
    /// response handling, which doesn't validate the JWT's signature.
    static func makeAccessToken(appUserID: String?, extraClaims: [String: Any] = [:]) throws -> String {
        var payload = extraClaims
        if let appUserID {
            payload["rc.app_user_id"] = appUserID
        }
        return try Self.makeToken(header: ["alg": "none", "typ": "JWT"], payload: payload)
    }

    static func makeToken(header: [String: Any], payload: [String: Any]) throws -> String {
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        let signatureData = try XCTUnwrap("signature-bytes".data(using: .utf8))

        return [headerData, payloadData, signatureData]
            .map { Self.base64URLString(from: $0) }
            .joined(separator: ".")
    }

    static func base64URLString(from data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}


class TokenLogInAnonymousBodyTests: TestCase {

    func testEncodesAppUserIDWhenPresent() throws {
        let body = TokenLogInOperation.AnonymousBody(method: "anonymous",
                                                     scope: "openid offline_access",
                                                     appUserID: "$RCAnonymousID:abc")

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body.jsonEncodedData) as? [String: Any])
        expect(json["method"] as? String) == "anonymous"
        expect(json["scope"] as? String) == "openid offline_access"
        expect(json["app_user_id"] as? String) == "$RCAnonymousID:abc"
    }

    func testOmitsAppUserIDWhenNil() throws {
        let body = TokenLogInOperation.AnonymousBody(method: "anonymous",
                                                     scope: "openid offline_access",
                                                     appUserID: nil)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body.jsonEncodedData) as? [String: Any])
        expect(json.keys.sorted()) == ["method", "scope"]
    }

    func testContentForSignatureIncludesAppUserID() {
        let body = TokenLogInOperation.AnonymousBody(method: "anonymous",
                                                     scope: "openid offline_access",
                                                     appUserID: "$RCAnonymousID:abc")

        expect(body.contentForSignature.map(\.key)) == ["method", "scope", "app_user_id"]
        expect(body.contentForSignature.map(\.value)) == ["anonymous", "openid offline_access", "$RCAnonymousID:abc"]
    }

}
