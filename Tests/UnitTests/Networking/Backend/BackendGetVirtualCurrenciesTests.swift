//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetVirtualCurrenciesTests.swift
//
//  Created by Will Taylor on 6/12/25.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class BackendGetVirtualCurrenciesTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetVirtualCurrenciesCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.twoVirtualCurrenciesResponse)
        )

        let result = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: Self.userID,
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    // MARK: - Jitterable Delay Tests
    func testGetVirtualCurrenciesUsesDefaultJitterableDelayWhenAppBackgrounded() {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.twoVirtualCurrenciesResponse)
        )

        let result = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: Self.userID,
                isAppBackgrounded: true,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.default
    }

    func testGetVirtualCurrenciesUsesDefaultJitterableDelayWhenAppNotBackgrounded() {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.twoVirtualCurrenciesResponse)
        )

        let result = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: Self.userID,
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    // MARK: - Caching Tests
    func testGetVirtualCurrenciesCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.twoVirtualCurrenciesResponse,
                            delay: .milliseconds(10))
        )
        self.virtualCurrenciesAPI.getVirtualCurrencies(
            appUserID: Self.userID,
            isAppBackgrounded: false
        ) { _ in }

        self.virtualCurrenciesAPI.getVirtualCurrencies(
            appUserID: Self.userID,
            isAppBackgrounded: false
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))
    }

    func testGetVirtualCurrenciesDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(
            statusCode: .success,
            response: Self.twoVirtualCurrenciesResponse
        )
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getVirtualCurrencies(appUserID: Self.userID), response: response)
        self.httpClient.mock(requestPath: .getVirtualCurrencies(appUserID: userID2), response: response)

        self.virtualCurrenciesAPI.getVirtualCurrencies(
            appUserID: Self.userID,
            isAppBackgrounded: false
        ) { _ in }
        self.virtualCurrenciesAPI.getVirtualCurrencies(
            appUserID: userID2,
            isAppBackgrounded: false
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(self.httpClient.calls).toNever(haveCount(3))
    }

    // MARK: - Response Tests
    func testGetVirtualCurrenciesTwoCurrencies() throws {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.twoVirtualCurrenciesResponse,
                            delay: .milliseconds(10))
        )

        let result: Result<VirtualCurrenciesResponse, BackendError>? = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: Self.userID,
                isAppBackgrounded: false
            ) {
                completed($0)
            }
        }

        let response = try XCTUnwrap(result?.value)
        let virtualCurrencies = try XCTUnwrap(response.virtualCurrencies)
        expect(virtualCurrencies.count).to(equal(2))

        let coinVC = try XCTUnwrap(virtualCurrencies["COIN"])
        expect(coinVC.balance).to(equal(1))
        expect(coinVC.code).to(equal("COIN"))
        expect(coinVC.description).to(equal("It's a coin"))
        expect(coinVC.name).to(equal("Coin"))

        let rcCoinVC = try XCTUnwrap(virtualCurrencies["RC_COIN"])
        expect(rcCoinVC.balance).to(equal(0))
        expect(rcCoinVC.code).to(equal("RC_COIN"))
        expect(rcCoinVC.description).to(beNil())
        expect(rcCoinVC.name).to(equal("RC Coin"))
    }

    func testGetVirtualCurrenciesNoCurrencies() throws {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.noVirtualCurrenciesResponse,
                            delay: .milliseconds(10))
        )

        let result: Result<VirtualCurrenciesResponse, BackendError>? = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: Self.userID,
                isAppBackgrounded: false
            ) {
                completed($0)
            }
        }

        let response = try XCTUnwrap(result?.value)
        let virtualCurrencies = try XCTUnwrap(response.virtualCurrencies)
        expect(virtualCurrencies.count).to(equal(0))
    }

    // MARK: - Error Handling
    func testGetVirtualCurrenciesFailSendsError() {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: Self.userID,
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beFailure())
    }

    func testGetVirtualCurrenciesNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: Self.userID,
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    // MARK: - Logging Tests
    func testRepeatedRequestsLogDebugMessage() {
        self.httpClient.mock(
            requestPath: .getVirtualCurrencies(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.twoVirtualCurrenciesResponse,
                            delay: .milliseconds(10))
        )
        self.virtualCurrenciesAPI.getVirtualCurrencies(
            appUserID: Self.userID,
            isAppBackgrounded: false
        ) { _ in }
        self.virtualCurrenciesAPI.getVirtualCurrencies(
            appUserID: Self.userID,
            isAppBackgrounded: false
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(GetVirtualCurrenciesOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    // MARK: - Empty User ID Tests
    func testGetVirtualCurrenciesSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: "",
                isAppBackgrounded: false
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetVirtualCurrenciesCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.virtualCurrenciesAPI.getVirtualCurrencies(
                appUserID: "",
                isAppBackgrounded: false
            ) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }
}

private extension BackendGetVirtualCurrenciesTests {

    static let noVirtualCurrenciesResponse: [String: Any] = [
        "virtual_currencies": [:]
    ]

    static let twoVirtualCurrenciesResponse: [String: Any] = [
        "virtual_currencies": [
            "COIN": [
                "balance": 1,
                "code": "COIN",
                "description": "It's a coin",
                "name": "Coin"
            ],
            "RC_COIN": [
                "balance": 0,
                "code": "RC_COIN",
                "name": "RC Coin"
            ]
        ]
    ]
}
