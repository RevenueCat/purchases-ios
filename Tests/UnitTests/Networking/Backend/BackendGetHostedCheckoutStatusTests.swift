//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetHostedCheckoutStatusTests.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetHostedCheckoutStatusTests: BaseBackendTests {

    private static let operationSessionID = "opsession_123"

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testSendsTheExpectedRequest() {
        self.mockStatus(Self.response(status: "started"))

        let result = waitUntilValue { completed in
            self.getStatus(completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testIsNotDelayed() {
        self.mockStatus(Self.response(status: "started"))

        let result = waitUntilValue { completed in
            self.getStatus(completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    // MARK: - Decoding

    /// The session is still under way, which is the answer that keeps the caller asking.
    func testReadsAStartedSessionAsPending() throws {
        self.mockStatus(Self.response(status: "started"))

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status) == .pending
    }

    func testReadsAnInProgressSessionAsPending() throws {
        self.mockStatus(Self.response(status: "in_progress"))

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status) == .pending
    }

    func testReadsASucceededSession() throws {
        self.mockStatus(Self.response(status: "succeeded"))

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status) == .succeeded
    }

    func testReadsAFailedSessionWithItsError() throws {
        self.mockStatus(Self.response(status: "failed",
                                      error: ["code": 3, "message": "payment_charge_failed"]))

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status) == .failed(.init(code: 3, message: "payment_charge_failed"))
    }

    /// The code the backend uses for a product the customer already owns, which the caller tells apart
    /// from other failures.
    func testReadsAFailureForAProductTheCustomerAlreadyOwns() throws {
        self.mockStatus(Self.response(status: "failed",
                                      error: ["code": 5, "message": "already_purchased"]))

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status.failure?.isAlreadyPurchased) == true
    }

    func testReadsAFailedSessionWithoutAnError() throws {
        self.mockStatus(Self.response(status: "failed"))

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status) == .failed(nil)
    }

    /// A status a newer backend adds must not read as an outcome this version cannot vouch for.
    func testReadsAnUnrecognizedStatusAsUnknown() throws {
        self.mockStatus(Self.response(status: "something_new"))

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status) == .unknown
    }

    /// Only used for web product changes, so it says nothing about what became of this session.
    func testIgnoresAnExpiredSession() throws {
        self.mockStatus(["status": "succeeded", "is_expired": true])

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getStatus(completion: completed)
        }?.value)

        expect(response.status) == .succeeded
    }

    // MARK: - Failures

    func testForwardsANetworkError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(requestPath: Self.path, response: .init(error: mockedError))

        let result = waitUntilValue { completed in
            self.getStatus(completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testSkipsTheCallWhenTheAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.getStatus(appUserID: "") {
                completed($0.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
        expect(self.httpClient.calls).to(beEmpty())
    }

    // MARK: - Reuse

    /// Two callers waiting on the same session are answered by one request rather than two.
    func testIdenticalRequestsInFlightAreReusedForASingleCall() {
        self.httpClient.mock(
            requestPath: Self.path,
            response: .init(statusCode: .success,
                            response: Self.response(status: "started"),
                            delay: .milliseconds(10))
        )

        self.getStatus { _ in }
        self.getStatus { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))
    }

}

private extension BackendGetHostedCheckoutStatusTests {

    static let path = HTTPRequest.WebBillingPath.getHostedCheckoutStatus(
        operationSessionID: operationSessionID,
        appUserID: userID
    )

    static func response(status: String) -> [String: Any] {
        return ["status": status, "is_expired": false]
    }

    static func response(status: String, error: [String: Any]) -> [String: Any] {
        return ["status": status, "is_expired": false, "error": error]
    }

    func mockStatus(_ response: [String: Any]) {
        self.httpClient.mock(requestPath: Self.path,
                             response: .init(statusCode: .success, response: response))
    }

    func getStatus(completion: @escaping WebBillingAPI.HostedCheckoutStatusResponseHandler) {
        self.getStatus(appUserID: BackendGetHostedCheckoutStatusTests.userID, completion: completion)
    }

    func getStatus(appUserID: String,
                   completion: @escaping WebBillingAPI.HostedCheckoutStatusResponseHandler) {
        self.webBilling.getHostedCheckoutStatus(
            appUserID: appUserID,
            operationSessionID: BackendGetHostedCheckoutStatusTests.operationSessionID,
            completion: completion
        )
    }

}

private extension HostedCheckoutStatusResponse.Status {

    var failure: HostedCheckoutStatusResponse.Failure? {
        guard case let .failed(failure) = self else { return nil }

        return failure
    }

}
