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

@testable import RevenueCat

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

}
