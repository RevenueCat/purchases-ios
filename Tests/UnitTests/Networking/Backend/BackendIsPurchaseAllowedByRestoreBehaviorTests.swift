//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendIsPurchaseAllowedByRestoreBehaviorTests.swift
//
//  Created by Will Taylor on 2/4/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable:next type_name
final class BackendIsPurchaseAllowedByRestoreBehaviorTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testRestoreEligibilitySendsExpectedRequest() throws {
        self.httpClient.mock(
            requestPath: .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID),
            response: .init(
                statusCode: .success,
                response: Self.allowedTransferResponse
            )
        )

        let transactionJWS = "jws-token"

        let result = self.restoreEligibilityResult(
            appUserID: Self.userID,
            transactionJWS: transactionJWS
        )

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).toEventually(haveCount(1))

        let call = try XCTUnwrap(self.httpClient.calls.first)
        let path = try XCTUnwrap(call.request.path as? HTTPRequest.Path)
        expect(path) == .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID)
        expect(call.request.method.httpMethod) == "POST"

        let bodyDict = try XCTUnwrap(call.request.requestBody?.asJSONDictionary())
        expect(bodyDict["fetch_token"] as? String) == transactionJWS
        expect(bodyDict["app_transaction"]).to(beNil())
    }

    func testRestoreEligibilityReturnsDecodedResponse() {
        self.httpClient.mock(
            requestPath: .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID),
            response: .init(
                statusCode: .success,
                response: Self.blockedTransferResponse
            )
        )

        let result = self.restoreEligibilityResult(
            appUserID: Self.userID,
            transactionJWS: "jws-token"
        )

        expect(result).to(beSuccess())
        expect(result?.value?.isPurchaseAllowedByRestoreBehavior) == false
    }

    // MARK: - Jitterable Delay Tests
    func testRestoreEligibilityUsesDefaultJitterableDelayWhenAppBackgrounded() {
        self.httpClient.mock(
            requestPath: .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID),
            response: .init(
                statusCode: .success,
                response: Self.allowedTransferResponse
            )
        )

        let result = self.restoreEligibilityResult(
            appUserID: Self.userID,
            transactionJWS: "jws-token",
            isAppBackgrounded: true
        )

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.default
    }

    func testRestoreEligibilityUsesNoJitterableDelayWhenAppNotBackgrounded() {
        self.httpClient.mock(
            requestPath: .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID),
            response: .init(
                statusCode: .success,
                response: Self.allowedTransferResponse
            )
        )

        let result = self.restoreEligibilityResult(
            appUserID: Self.userID,
            transactionJWS: "jws-token"
        )

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    // MARK: - Error Handling
    func testRestoreEligibilityNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        let result = self.restoreEligibilityResult(
            appUserID: Self.userID,
            transactionJWS: "jws-token"
        )

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testRestoreEligibilityFailSendsError() {
        self.httpClient.mock(
            requestPath: .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = self.restoreEligibilityResult(
            appUserID: Self.userID,
            transactionJWS: "jws-token"
        )

        expect(result).to(beFailure())
    }

    // MARK: - Logging Tests
    func testRepeatedRequestsLogDebugMessage() {
        self.httpClient.mock(
            requestPath: .isPurchaseAllowedByRestoreBehavior(appUserID: Self.userID),
            response: .init(
                statusCode: .success,
                response: Self.allowedTransferResponse,
                delay: .milliseconds(10)
            )
        )

        self.backend.isPurchaseAllowedByRestoreBehavior(
            appUserID: Self.userID,
            transactionJWS: "jws-token",
            isAppBackgrounded: false
        ) { _ in }
        self.backend.isPurchaseAllowedByRestoreBehavior(
            appUserID: Self.userID,
            transactionJWS: "jws-token",
            isAppBackgrounded: false
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(PostIsPurchaseAllowedByRestoreBehaviorOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    // MARK: - Empty User ID Tests
    func testRestoreEligibilitySkipsBackendCallIfAppUserIDIsEmpty() {
        let result = self.restoreEligibilityResult(
            appUserID: "",
            transactionJWS: "jws-token"
        )

        expect(self.httpClient.calls).to(beEmpty())
        expect(result).to(beFailure())
        expect(result?.error) == .missingAppUserID()
    }

    func testRestoreEligibilitySkipsBackendCallIfTransactionJWSIsEmpty() {
        let result = self.restoreEligibilityResult(
            appUserID: Self.userID,
            transactionJWS: ""
        )

        expect(self.httpClient.calls).to(beEmpty())
        expect(result).to(beFailure())
        expect(result?.error) == .missingTransactionJWS()
    }

}

    private extension BackendIsPurchaseAllowedByRestoreBehaviorTests {

    func restoreEligibilityResult(
        appUserID: String,
        transactionJWS: String,
        isAppBackgrounded: Bool = false
    ) -> Result<IsPurchaseAllowedByRestoreBehaviorResponse, BackendError>? {
        return waitUntilValue { completed in
            self.backend.isPurchaseAllowedByRestoreBehavior(
                appUserID: appUserID,
                transactionJWS: transactionJWS,
                isAppBackgrounded: isAppBackgrounded,
                completion: completed
            )
        }
    }

    static let allowedTransferResponse: [String: Any] = [
        "is_purchase_allowed_by_restore_behavior": true
    ]

    static let blockedTransferResponse: [String: Any] = [
        "is_purchase_allowed_by_restore_behavior": false
    ]

}
