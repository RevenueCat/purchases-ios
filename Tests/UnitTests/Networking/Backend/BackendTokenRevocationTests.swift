//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendTokenRevocationTests.swift
//
//  Created by RevenueCat on 8/18/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BaseBackendTokenRevocationTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        // These tests assert on the decoded request bodies directly, and there's no recorded
        // snapshot fixture for the new token endpoints.
        self.httpClient.disableSnapshotTesting()
    }

    var tokenManager: MockTokenManager {
        // swiftlint:disable:next force_cast
        return self.httpClient.tokenManager as! MockTokenManager
    }

}

class BackendTokenRevocationTests: BaseBackendTokenRevocationTests {

    // MARK: - revokeTokens(for:completion:)

    func testRevokeTokensDeletesLocallyWithoutANetworkCallWhenThereIsNoRefreshToken() {
        self.tokenManager.stubbedCurrentRefreshToken = nil

        let receivedError = waitUntilValue { completed in
            self.token.revokeTokens(for: "user-id", completion: completed)
        }

        expect(receivedError).to(beNil())
        expect(self.httpClient.calls).to(beEmpty())
        expect(self.tokenManager.invokedDeleteTokensParametersList) == ["user-id"]
    }

    func testRevokeTokensSendsTheRefreshTokenAndDeletesLocalTokensOnSuccess() throws {
        self.tokenManager.stubbedCurrentRefreshToken = "refresh-token-value"
        self.httpClient.mock(requestPath: .tokenLogOut, response: .init(statusCode: .success))

        let receivedError = waitUntilValue { completed in
            self.token.revokeTokens(for: "user-id", completion: completed)
        }

        expect(receivedError).to(beNil())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.tokenManager.invokedDeleteTokensParametersList) == ["user-id"]

        let body = try XCTUnwrap(self.httpClient.calls.first?.request.requestBody as? TokenRevocationOperation.Body)
        expect(body.token) == "refresh-token-value"
        expect(body.tokenTypeHint) == "refresh_token"
    }

    func testRevokeTokensPassesNetworkErrorsAndDoesNotDeleteLocalTokens() {
        self.tokenManager.stubbedCurrentRefreshToken = "refresh-token-value"
        let stubbedError: NetworkError = .unexpectedResponse(nil)
        self.httpClient.mock(requestPath: .tokenLogOut, response: .init(error: stubbedError))

        let receivedError = waitUntilValue { completed in
            self.token.revokeTokens(for: "user-id", completion: completed)
        }

        expect(receivedError) == .networkError(stubbedError)
        expect(self.tokenManager.invokedDeleteTokens) == false
    }

}
