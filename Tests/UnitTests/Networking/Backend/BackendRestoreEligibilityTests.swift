//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendRestoreEligibilityTests.swift
//
//  Created by Will Taylor on 2/4/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class BackendRestoreEligibilityTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testRestoreEligibilitySendsExpectedRequest() throws {
        self.httpClient.mock(
            requestPath: .restoreEligibility(appUserID: Self.userID),
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
        expect(path) == .restoreEligibility(appUserID: Self.userID)
        expect(call.request.method.httpMethod) == "POST"

        let bodyDict = try XCTUnwrap(call.request.requestBody?.asJSONDictionary())
        expect(bodyDict["fetch_token"] as? String) == transactionJWS
        expect(bodyDict["app_transaction"]).to(beNil())
    }

    func testRestoreEligibilityReturnsDecodedResponse() {
        self.httpClient.mock(
            requestPath: .restoreEligibility(appUserID: Self.userID),
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
        expect(result?.value?.receiptBelongsToOtherSubscriber) == true
        expect(result?.value?.transferIsAllowed) == false
    }

    // MARK: - Jitterable Delay Tests
    func testRestoreEligibilityUsesDefaultJitterableDelayWhenAppBackgrounded() {
        self.httpClient.mock(
            requestPath: .restoreEligibility(appUserID: Self.userID),
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
            requestPath: .restoreEligibility(appUserID: Self.userID),
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
            requestPath: .restoreEligibility(appUserID: Self.userID),
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
            requestPath: .restoreEligibility(appUserID: Self.userID),
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
            requestPath: .restoreEligibility(appUserID: Self.userID),
            response: .init(
                statusCode: .success,
                response: Self.allowedTransferResponse,
                delay: .milliseconds(10)
            )
        )

        self.backend.willPurchaseBeBlockedDueToRestoreBehavior(
            appUserID: Self.userID,
            transactionJWS: "jws-token",
            isAppBackgrounded: false
        ) { _ in }
        self.backend.willPurchaseBeBlockedDueToRestoreBehavior(
            appUserID: Self.userID,
            transactionJWS: "jws-token",
            isAppBackgrounded: false
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))

        // swiftlint:disable:next line_length
        self.logger.verifyMessageWasLogged(
            "Network operation '\(PostWillPurchaseBeBlockedByRestoreBehaviorOperation.self)' found with the same cache key",
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

}

    private extension BackendRestoreEligibilityTests {

    func restoreEligibilityResult(
        appUserID: String,
        transactionJWS: String,
        isAppBackgrounded: Bool = false
    ) -> Result<WillPurchaseBeBlockedByRestoreBehaviorResponse, BackendError>? {
        return waitUntilValue { completed in
            self.backend.willPurchaseBeBlockedDueToRestoreBehavior(
                appUserID: appUserID,
                transactionJWS: transactionJWS,
                isAppBackgrounded: isAppBackgrounded,
                completion: completed
            )
        }
    }

    static let allowedTransferResponse: [String: Any] = [
        "receipt_belongs_to_other_subscriber": false,
        "transfer_is_allowed": true
    ]

    static let blockedTransferResponse: [String: Any] = [
        "receipt_belongs_to_other_subscriber": true,
        "transfer_is_allowed": false
    ]

}
