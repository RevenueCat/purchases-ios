//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TokenManagerTests.swift
//
//  Created by RevenueCat on 8/13/26.

import Nimble
import XCTest

@testable @_spi(Internal) import RevenueCat

class TokenManagerTests: TestCase {

    private var storage: MockSecureItemStorage!
    private var userProvider: MockCurrentUserProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.storage = MockSecureItemStorage()
        self.userProvider = MockCurrentUserProvider(mockAppUserID: "test-user")
    }

    // MARK: - enabled

    func testEnabledReflectsTheValuePassedToTheInitializer() {
        expect(TokenManager(enabled: true, storage: self.storage).enabled) == true
        expect(TokenManager(enabled: false, storage: self.storage).enabled) == false
    }

    // MARK: - currentRefreshToken

    func testCurrentRefreshTokenIsNilWhenDisabled() {
        let manager = TokenManager(enabled: false, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.currentRefreshToken = "refresh-token"

        expect(manager.currentRefreshToken).to(beNil())
        expect(self.storage.invokedSaveItemIdentifiers).to(beEmpty())
    }

    func testCurrentRefreshTokenIsNilWhenThereIsNoCurrentUser() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        // `currentUserProvider` is intentionally left unset.

        manager.currentRefreshToken = "refresh-token"

        expect(manager.currentRefreshToken).to(beNil())
        expect(self.storage.invokedSaveItemIdentifiers).to(beEmpty())
    }

    func testCurrentRefreshTokenRoundTripsWhenEnabledWithACurrentUser() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.currentRefreshToken = "refresh-token"

        expect(manager.currentRefreshToken) == "refresh-token"
    }

    func testCurrentRefreshTokenCanBeClearedBySettingItToNil() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "refresh-token"

        manager.currentRefreshToken = nil

        expect(manager.currentRefreshToken).to(beNil())
    }

    func testCurrentRefreshTokenIsIsolatedPerUser() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "user-a-refresh-token"

        self.userProvider.mockAppUserID = "another-user"

        expect(manager.currentRefreshToken).to(beNil())

        manager.currentRefreshToken = "user-b-refresh-token"
        expect(manager.currentRefreshToken) == "user-b-refresh-token"

        self.userProvider.mockAppUserID = "test-user"
        expect(manager.currentRefreshToken) == "user-a-refresh-token"
    }

    // MARK: - currentAccessToken

    func testCurrentAccessTokenIsNilWhenDisabled() {
        let manager = TokenManager(enabled: false, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.currentAccessToken = "access-token"

        expect(manager.currentAccessToken).to(beNil())
        expect(self.storage.invokedSaveItemIdentifiers).to(beEmpty())
    }

    func testCurrentAccessTokenRoundTripsWhenEnabledWithACurrentUser() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.currentAccessToken = "access-token"

        expect(manager.currentAccessToken) == "access-token"
    }

    // MARK: - hasCurrentAccessToken

    func testHasCurrentAccessTokenIsFalseWhenNoAccessTokenIsStored() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        expect(manager.hasCurrentAccessToken) == false
    }

    func testHasCurrentAccessTokenIsTrueAfterSettingAnAccessToken() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentAccessToken = "access-token"

        expect(manager.hasCurrentAccessToken) == true
    }

    func testHasCurrentAccessTokenIsFalseWhenDisabledEvenIfATokenWasPreviouslySavedForThatUser() {
        let enabledManager = TokenManager(enabled: true, storage: self.storage)
        enabledManager.currentUserProvider = self.userProvider
        enabledManager.currentAccessToken = "access-token"

        let disabledManager = TokenManager(enabled: false, storage: self.storage)
        disabledManager.currentUserProvider = self.userProvider

        expect(disabledManager.hasCurrentAccessToken) == false
    }

    // MARK: - currentIDToken

    func testCurrentIDTokenIsNilWhenDisabled() {
        let manager = TokenManager(enabled: false, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.currentIDToken = "id-token"

        expect(manager.currentIDToken).to(beNil())
    }

    func testCurrentIDTokenRoundTripsWhenEnabledWithACurrentUser() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.currentIDToken = "id-token"

        expect(manager.currentIDToken) == "id-token"
    }

    // MARK: - idToken(for:)

    func testIDTokenForUserReadsDirectlyFromStorageEvenWhenDisabled() {
        // Unlike `currentIDToken`, `idToken(for:)` bypasses the `enabled` and `currentUser` checks
        // and always reads whatever is in storage for the given user.
        let manager = TokenManager(enabled: false, storage: self.storage)

        manager.saveTokens(refreshToken: nil,
                           accessToken: "access",
                           idToken: "id-token-for-explicit-user",
                           for: "explicit-user")

        expect(manager.idToken(for: "explicit-user")) == "id-token-for-explicit-user"
    }

    func testIDTokenForUserReturnsNilWhenNoTokenHasBeenSaved() {
        let manager = TokenManager(enabled: true, storage: self.storage)

        expect(manager.idToken(for: "unknown-user")).to(beNil())
    }

    // MARK: - saveTokens(refreshToken:accessToken:idToken:for:)

    func testSaveTokensSavesAllThreeTokensForTheGivenUser() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.saveTokens(refreshToken: "refresh", accessToken: "access", idToken: "id", for: "test-user")

        expect(manager.currentRefreshToken) == "refresh"
        expect(manager.currentAccessToken) == "access"
        expect(manager.currentIDToken) == "id"
    }

    func testSaveTokensWritesToStorageEvenWhenDisabled() {
        // `saveTokens` writes directly to storage using the passed-in `userID`, bypassing the
        // `enabled`/`currentUser` guard used by the computed properties.
        let manager = TokenManager(enabled: false, storage: self.storage)

        manager.saveTokens(refreshToken: "refresh", accessToken: "access", idToken: "id", for: "test-user")

        expect(manager.idToken(for: "test-user")) == "id"
    }

    func testSaveTokensAllowsNilRefreshAndIDTokens() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        manager.saveTokens(refreshToken: nil, accessToken: "access", idToken: nil, for: "test-user")

        expect(manager.currentRefreshToken).to(beNil())
        expect(manager.currentAccessToken) == "access"
        expect(manager.currentIDToken).to(beNil())
    }

    // MARK: - deleteTokens(for:)

    func testDeleteTokensRemovesAllThreeTokensForTheGivenUser() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.saveTokens(refreshToken: "refresh", accessToken: "access", idToken: "id", for: "test-user")

        manager.deleteTokens(for: "test-user")

        expect(manager.currentRefreshToken).to(beNil())
        expect(manager.currentAccessToken).to(beNil())
        expect(manager.currentIDToken).to(beNil())
    }

    func testDeleteTokensDoesNotAffectTokensBelongingToOtherUsers() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.saveTokens(refreshToken: "refresh", accessToken: "access", idToken: "id", for: "test-user")
        manager.saveTokens(refreshToken: "other-refresh",
                           accessToken: "other-access",
                           idToken: "other-id",
                           for: "other-user")

        manager.deleteTokens(for: "test-user")

        expect(manager.idToken(for: "test-user")).to(beNil())
        expect(manager.idToken(for: "other-user")) == "other-id"
    }

    // MARK: - deleteAccessToken(for:)

    func testDeleteAccessTokenOnlyRemovesTheAccessToken() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.saveTokens(refreshToken: "refresh", accessToken: "access", idToken: "id", for: "test-user")

        manager.deleteAccessToken(for: "test-user")

        expect(manager.currentAccessToken).to(beNil())
        expect(manager.currentRefreshToken) == "refresh"
        expect(manager.currentIDToken) == "id"
    }

    // MARK: - reportError

    func testReportErrorIsNilByDefault() {
        let manager = TokenManager(enabled: true, storage: self.storage)

        expect(manager.reportError).to(beNil())
    }

    func testReportErrorCanBeSetAndIsInvokedWhenCalled() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        let expectedError = NSError(domain: "TokenManagerTests", code: 1)
        var receivedError: PublicError?

        manager.reportError = { error in
            receivedError = error
        }
        manager.reportError?(expectedError)

        expect(receivedError) == expectedError
    }

    // MARK: - currentIdentitySources

    func testCurrentIdentitySourcesIsNilWhenThereIsNoCurrentIDToken() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        expect(manager.currentIdentitySources).to(beNil())
    }

    func testCurrentIdentitySourcesIsNilWhenTheIDTokenIsNotAValidJWT() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = "not-a-jwt"

        expect(manager.currentIdentitySources).to(beNil())
    }

    func testCurrentIdentitySourcesIsNilWhenTheAmrClaimIsMissing() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(payload: ["sub": "abc"])

        expect(manager.currentIdentitySources).to(beNil())
    }

    func testCurrentIdentitySourcesParsesKnownSourcesFromTheAmrClaim() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: ["oidc", "google"])

        expect(manager.currentIdentitySources) == [.oidc, .google]
    }

    func testCurrentIdentitySourcesFiltersOutUnrecognizedAmrValues() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: ["some-unknown-value", "anonymous"])

        expect(manager.currentIdentitySources) == [.anonymous]
    }

    func testCurrentIdentitySourcesIsEmptyArrayWhenAmrClaimIsEmpty() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: [])

        expect(manager.currentIdentitySources) == []
    }

    // MARK: - isCurrentIdentityAnonymous

    func testIsCurrentIdentityAnonymousIsFalseWhenThereAreNoIdentitySources() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        expect(manager.isCurrentIdentityAnonymous) == false
    }

    func testIsCurrentIdentityAnonymousIsFalseWhenTheAmrClaimIsEmpty() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: [])

        expect(manager.isCurrentIdentityAnonymous) == false
    }

    func testIsCurrentIdentityAnonymousIsTrueWhenEveryIdentitySourceIsAnonymous() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: ["anonymous", "anonymous"])

        expect(manager.isCurrentIdentityAnonymous) == true
    }

    func testIsCurrentIdentityAnonymousIsFalseWhenAnyIdentitySourceIsNotAnonymous() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: ["anonymous", "oidc"])

        expect(manager.isCurrentIdentityAnonymous) == false
    }

    // MARK: - currentIdentitySource

    func testCurrentIdentitySourceIsNilWhenThereAreNoIdentitySources() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        expect(manager.currentIdentitySource).to(beNil())
    }

    func testCurrentIdentitySourceIsNilWhenTheAmrClaimIsEmpty() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: [])

        expect(manager.currentIdentitySource).to(beNil())
    }

    func testCurrentIdentitySourceReturnsTheLastIdentitySource() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentIDToken = try Self.makeIDToken(amr: ["anonymous", "oidc"])

        expect(manager.currentIdentitySource) == .oidc
    }

    // MARK: - authorizationHeaders(for:)

    func testAuthorizationHeadersIsEmptyWhenDisabled() {
        let manager = TokenManager(enabled: false, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentAccessToken = "access-token"

        expect(manager.authorizationHeaders(for: Self.makeRequest())).to(beEmpty())
    }

    func testAuthorizationHeadersIsEmptyWhenThereIsNoAccessToken() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        expect(manager.authorizationHeaders(for: Self.makeRequest())).to(beEmpty())
    }

    func testAuthorizationHeadersIsEmptyForIAMPathsEvenWithAnAccessToken() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentAccessToken = "access-token"

        expect(manager.authorizationHeaders(for: Self.makeRequest(path: .tokenRefresh))).to(beEmpty())
    }

    func testAuthorizationHeadersReturnsBearerTokenForNonIAMPathsWithAnAccessToken() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentAccessToken = "access-token"

        expect(manager.authorizationHeaders(for: Self.makeRequest())) == [
            HTTPClient.RequestHeader.authorization.rawValue: "Bearer access-token"
        ]
    }

    // MARK: - tokenRefreshRequest(for:response:duplicateRequestHandler:)

    func testTokenRefreshRequestReturnsNoActionWhenDisabled() {
        let manager = TokenManager(enabled: false, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "refresh-token"

        let action = manager.tokenRefreshRequest(for: Self.makeRequest(),
                                                 response: Self.unauthorizedResponse) { _ in }

        expect(Self.isNoAction(action)) == true
    }

    func testTokenRefreshRequestReturnsNoActionForIAMPaths() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "refresh-token"

        let action = manager.tokenRefreshRequest(for: Self.makeRequest(path: .tokenRefresh),
                                                 response: Self.unauthorizedResponse) { _ in }

        expect(Self.isNoAction(action)) == true
    }

    func testTokenRefreshRequestReturnsNoActionWhenTheRequestHasAlreadyBeenRetried() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "refresh-token"

        let action = manager.tokenRefreshRequest(for: Self.makeRequest().retriedRequest(),
                                                 response: Self.unauthorizedResponse) { _ in }

        expect(Self.isNoAction(action)) == true
    }

    func testTokenRefreshRequestReturnsNoActionWhenThereIsNoResponse() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "refresh-token"

        let action = manager.tokenRefreshRequest(for: Self.makeRequest(), response: nil) { _ in }

        expect(Self.isNoAction(action)) == true
    }

    func testTokenRefreshRequestReturnsNoActionWhenTheResponseIsNotUnauthorized() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "refresh-token"

        let action = manager.tokenRefreshRequest(for: Self.makeRequest(),
                                                 response: Self.successResponse) { _ in }

        expect(Self.isNoAction(action)) == true
    }

    func testTokenRefreshRequestReturnsNoActionWhenThereIsNoRefreshToken() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider

        let action = manager.tokenRefreshRequest(for: Self.makeRequest(),
                                                 response: Self.unauthorizedResponse) { _ in }

        expect(Self.isNoAction(action)) == true
    }

    func testTokenRefreshRequestReturnsARefreshRequestUsingTheCurrentRefreshToken() throws {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "current-refresh-token"

        let action = manager.tokenRefreshRequest(for: Self.makeRequest(),
                                                 response: Self.unauthorizedResponse) { _ in }

        guard case let .refresh(refreshRequest) = action else {
            fail("Expected .refresh, got \(action)")
            return
        }
        expect(refreshRequest.path as? HTTPRequest.Path) == .tokenRefresh
        expect(refreshRequest.isRetryable) == false
        let body = try XCTUnwrap(refreshRequest.requestBody as? TokenRefreshOperation.Body)
        expect(body.refreshToken) == "current-refresh-token"
    }

    func testTokenRefreshRequestReturnsWaitingForOtherRequestWhileARefreshIsInFlight() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "current-refresh-token"

        let firstAction = manager.tokenRefreshRequest(for: Self.makeRequest(),
                                                       response: Self.unauthorizedResponse) { _ in }
        expect(Self.isRefresh(firstAction)) == true

        var duplicateHandlerResult: Bool?
        let secondAction = manager.tokenRefreshRequest(
            for: Self.makeRequest(path: .getOfferings(appUserID: "user")),
            response: Self.unauthorizedResponse
        ) { wasSuccessful in
            duplicateHandlerResult = wasSuccessful
        }

        guard case .waitingForOtherRequest = secondAction else {
            fail("Expected the second call to wait for the first, got \(secondAction)")
            return
        }
        expect(duplicateHandlerResult).to(beNil())

        _ = manager.handleTokenRefreshResponse(.success(Self.makeTokenResponse()))

        expect(duplicateHandlerResult) == true
    }

    func testTokenRefreshRequestStartsANewRefreshAfterThePreviousOneCompletes() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "current-refresh-token"

        let firstAction = manager.tokenRefreshRequest(for: Self.makeRequest(),
                                                       response: Self.unauthorizedResponse) { _ in }
        expect(Self.isRefresh(firstAction)) == true

        _ = manager.handleTokenRefreshResponse(.success(Self.makeTokenResponse()))

        let secondAction = manager.tokenRefreshRequest(for: Self.makeRequest(),
                                                        response: Self.unauthorizedResponse) { _ in }

        expect(Self.isRefresh(secondAction)) == true
    }

    // MARK: - handleTokenRefreshResponse(_:)

    func testHandleTokenRefreshResponseReturnsFalseAndDoesNothingWhenDisabled() {
        let manager = TokenManager(enabled: false, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        var reportedError: PublicError?
        manager.reportError = { reportedError = $0 }

        let didHandle = manager.handleTokenRefreshResponse(.failure(Self.makeNetworkError()))

        expect(didHandle) == false
        expect(reportedError).to(beNil())
    }

    func testHandleTokenRefreshResponseSavesTokensAndReturnsTrueOnSuccess() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        var reportedError: PublicError?
        manager.reportError = { reportedError = $0 }

        let didHandle = manager.handleTokenRefreshResponse(.success(Self.makeTokenResponse(
            accessToken: "new-access",
            idToken: "new-id",
            refreshToken: "new-refresh"
        )))

        expect(didHandle) == true
        expect(reportedError).to(beNil())
        expect(manager.currentAccessToken) == "new-access"
        expect(manager.currentIDToken) == "new-id"
        expect(manager.currentRefreshToken) == "new-refresh"
    }

    func testHandleTokenRefreshResponseReportsTheErrorAndReturnsFalseOnFailure() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentAccessToken = "old-access"
        var reportedError: PublicError?
        manager.reportError = { reportedError = $0 }
        let networkError = Self.makeNetworkError()

        let didHandle = manager.handleTokenRefreshResponse(.failure(networkError))

        expect(didHandle) == false
        expect(reportedError).to(matchError(networkError.asPublicError))
        // a failed refresh should not clear out whatever access token was already stored
        expect(manager.currentAccessToken) == "old-access"
    }

    func testHandleTokenRefreshResponseReportsAnErrorWhenTheResponseIsNotSuccessful() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        var reportedError: PublicError?
        manager.reportError = { reportedError = $0 }
        let response = VerifiedHTTPResponse<TokenResponse>(
            httpStatusCode: .unauthorized,
            responseHeaders: [:],
            body: TokenResponse(accessToken: "access-token",
                                idToken: "id-token",
                                refreshToken: "refresh-token",
                                scope: "openid",
                                expiresIn: 3600),
            verificationResult: .notRequested,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        )

        let didHandle = manager.handleTokenRefreshResponse(.success(response))

        expect(didHandle) == false
        expect(reportedError).toNot(beNil())
    }

    func testHandleTokenRefreshResponseNotifiesDuplicateRequestHandlersOnFailure() {
        let manager = TokenManager(enabled: true, storage: self.storage)
        manager.currentUserProvider = self.userProvider
        manager.currentRefreshToken = "current-refresh-token"

        _ = manager.tokenRefreshRequest(for: Self.makeRequest(), response: Self.unauthorizedResponse) { _ in }
        var duplicateResult: Bool?
        _ = manager.tokenRefreshRequest(for: Self.makeRequest(path: .getOfferings(appUserID: "user")),
                                        response: Self.unauthorizedResponse) { wasSuccessful in
            duplicateResult = wasSuccessful
        }

        _ = manager.handleTokenRefreshResponse(.failure(Self.makeNetworkError()))

        expect(duplicateResult) == false
    }

}

private extension TokenManagerTests {

    /// Builds an unsigned (`alg: "none"`) JWT string with the given payload, suitable for exercising
    /// `TokenManager`'s ID-token-derived properties, which don't validate the JWT's signature.
    static func makeIDToken(amr: [String]? = nil, payload: [String: Any] = [:]) throws -> String {
        var payload = payload
        if let amr {
            payload["amr"] = amr
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

    // MARK: - Test helpers for `authorizationHeaders`/`tokenRefreshRequest`/`handleTokenRefreshResponse`

    static var mockURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://api.revenuecat.com/v1/subscribers/user")!
    }

    static var unauthorizedResponse: HTTPURLResponse? {
        HTTPURLResponse(url: Self.mockURL, statusCode: 401, httpVersion: nil, headerFields: nil)
    }

    static var successResponse: HTTPURLResponse? {
        HTTPURLResponse(url: Self.mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)
    }

    /// Builds a minimal `HTTPClient.Request` for exercising `TokenManager` methods that take one,
    /// without needing to spin up a full `HTTPClient`.
    static func makeRequest(path: HTTPRequest.Path = .getCustomerInfo(appUserID: "user")) -> HTTPClient.Request {
        let httpRequest = HTTPRequest(method: .get, path: path)
        return HTTPClient.Request(httpRequest: httpRequest,
                                  authHeaders: [:],
                                  defaultHeaders: [:],
                                  verificationMode: .disabled,
                                  preferIAMPath: false,
                                  internalSettings: DangerousSettings.Internal.default,
                                  completionHandler: { (_: VerifiedHTTPResponse<Data>.Result) in })
    }

    static func makeTokenResponse(
        accessToken: String = "access-token",
        idToken: String? = "id-token",
        refreshToken: String? = "refresh-token"
    ) -> VerifiedHTTPResponse<TokenResponse> {
        return VerifiedHTTPResponse<TokenResponse>(
            httpStatusCode: .success,
            responseHeaders: [:],
            body: TokenResponse(accessToken: accessToken,
                                idToken: idToken,
                                refreshToken: refreshToken,
                                scope: "openid",
                                expiresIn: 3600),
            verificationResult: .notRequested,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        )
    }

    static func makeNetworkError() -> NetworkError {
        return NetworkError.networkError(NSError(domain: "TokenManagerTests", code: 401))
    }

    static func isNoAction(_ action: TokenManager.TokenRefreshAction) -> Bool {
        if case .noAction = action { return true }
        return false
    }

    static func isRefresh(_ action: TokenManager.TokenRefreshAction) -> Bool {
        if case .refresh = action { return true }
        return false
    }

}
