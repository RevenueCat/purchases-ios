//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendCreateAliasTests.swift
//
//  Created by Nacho Soto on 3/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendCreateAliasTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testAliasCallsBackendProperly() throws {
        let completionCalled: Atomic<Bool?> = .init(nil)

        let path: HTTPRequest.Path = .createAlias(appUserID: Self.userID)
        let response = MockHTTPClient.Response(statusCode: .success)

        self.httpClient.mock(requestPath: path, response: response)

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in
            completionCalled.value = true
        }

        expect(completionCalled.value).toEventuallyNot(beNil())
        expect(completionCalled.value) == true
        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testCreateAliasCachesForSameUserIDs() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success)
        )

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testCreateAliasDoesntCacheForDifferentNewUserID() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success)
        )

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: Self.userID, newAppUserID: "another_new_alias") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testCreateAliasCachesWhenCallbackNil() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success)
        )

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias", completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testCreateAliasCallsAllCompletionBlocksInCache() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success)
        )

        var completion1Called = false
        var completion2Called = false

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias", completion: nil)
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in
            completion1Called = true
        }
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in
            completion2Called = true
        }

        expect(completion2Called).toEventually(beTrue())
        expect(completion1Called).toEventually(beTrue())
        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testCreateAliasDoesntCacheForDifferentCurrentUserID() {
        let newAppUserID = "new_alias"
        let currentAppUserID1 = Self.userID
        let currentAppUserID2 = Self.userID + "2"

        let response = MockHTTPClient.Response(statusCode: .success)

        httpClient.mock(requestPath: .createAlias(appUserID: currentAppUserID1), response: response)
        backend.createAlias(appUserID: currentAppUserID1, newAppUserID: newAppUserID) { _ in }

        httpClient.mock(requestPath: .createAlias(appUserID: currentAppUserID2), response: response)
        backend.createAlias(appUserID: currentAppUserID2, newAppUserID: newAppUserID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testNetworkErrorIsForwarded() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        var receivedError: BackendError?
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new") { error in
            receivedError = error
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError) == .networkError(mockedError)
    }

}
