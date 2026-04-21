//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetAdMobSSVStatusTests.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class BackendGetAdMobSSVStatusTests: BaseBackendTests {

    private static let clientTransactionID = "AABBCCDD-1111-2222-3333-444455556666"

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    // MARK: - HTTP path / wiring

    func testGetAdMobSSVStatusCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(statusCode: .success, response: Self.validatedResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    // MARK: - Response shapes

    func testGetAdMobSSVStatusValidated() throws {
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(statusCode: .success, response: Self.validatedResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .validated
    }

    func testGetAdMobSSVStatusPending() throws {
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(statusCode: .success, response: Self.pendingResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .pending
    }

    func testGetAdMobSSVStatusFailed() throws {
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(statusCode: .success, response: Self.failedResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .failed
    }

    func testGetAdMobSSVStatusUnknownStatusDecodesAsUnknown() throws {
        // Defence-in-depth: future backend additions must not break decode.
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(statusCode: .success, response: ["status": "some_future_state"])
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .unknown
    }

    // MARK: - Error handling

    func testGetAdMobSSVStatusFailSendsError() {
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                completion: completed
            )
        }

        expect(result).to(beFailure())
    }

    func testGetAdMobSSVStatusNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                completion: completed
            )
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    // MARK: - Empty user ID

    func testGetAdMobSSVStatusSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: "",
                clientTransactionID: Self.clientTransactionID
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetAdMobSSVStatusCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: "",
                clientTransactionID: Self.clientTransactionID
            ) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }

    func testGetAdMobSSVStatusSkipsBackendCallIfClientTransactionIDIsEmpty() {
        waitUntil { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: ""
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetAdMobSSVStatusCallsCompletionWithErrorIfClientTransactionIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: ""
            ) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingClientTransactionID()
    }

    // MARK: - Caching / dedupe

    func testGetAdMobSSVStatusDedupesConcurrentCallsForSameTransactionID() {
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(statusCode: .success,
                            response: Self.pendingResponse,
                            delay: .milliseconds(10))
        )

        self.adsAPI.getAdMobSSVStatus(
            appUserID: Self.userID,
            clientTransactionID: Self.clientTransactionID
        ) { _ in }

        self.adsAPI.getAdMobSSVStatus(
            appUserID: Self.userID,
            clientTransactionID: Self.clientTransactionID
        ) { _ in }

        // Both calls share a cache key (UUID is per-ad), so only one HTTP request fires.
        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))
    }

    func testGetAdMobSSVStatusDoesNotDedupeAcrossDifferentTransactionIDs() {
        let secondTransactionID = "ZZZZZZZZ-9999-8888-7777-666655554444"
        let response = MockHTTPClient.Response(
            statusCode: .success,
            response: Self.pendingResponse
        )

        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: response
        )
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: secondTransactionID
            ),
            response: response
        )

        self.adsAPI.getAdMobSSVStatus(
            appUserID: Self.userID,
            clientTransactionID: Self.clientTransactionID
        ) { _ in }
        self.adsAPI.getAdMobSSVStatus(
            appUserID: Self.userID,
            clientTransactionID: secondTransactionID
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(self.httpClient.calls).toNever(haveCount(3))
    }

    func testGetAdMobSSVStatusSequentialCallsForSameTransactionIDReissueRequest() {
        // The retry loop in the adapter polls the same UUID multiple times.
        // Once a request finishes, its callbacks are removed from the cache,
        // so the next call must hit the network again.
        self.httpClient.mock(
            requestPath: .adMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ),
            response: .init(statusCode: .success, response: Self.pendingResponse)
        )

        waitUntil { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ) { _ in completed() }
        }

        waitUntil { completed in
            self.adsAPI.getAdMobSSVStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(haveCount(2))
    }
}

private extension BackendGetAdMobSSVStatusTests {

    static let validatedResponse: [String: Any] = ["status": "validated"]
    static let pendingResponse: [String: Any] = ["status": "pending"]
    static let failedResponse: [String: Any] = ["status": "failed"]

}
