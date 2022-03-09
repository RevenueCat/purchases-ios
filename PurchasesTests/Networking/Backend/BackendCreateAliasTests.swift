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
        var completionCalled = false

        let path: HTTPRequest.Path = .createAlias(appUserID: Self.userID)
        let response = MockHTTPClient.Response(statusCode: .success, response: nil)

        self.httpClient.mock(requestPath: path, response: response)

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias", completion: { (_) in
            completionCalled = true
        })

        expect(completionCalled).toEventually(beTrue())
        expect(self.httpClient.calls).toEventually(haveCount(1))

        let call = self.httpClient.calls[0]

        expect(call.request.path) == path
        expect(call.headers) == HTTPClient.authorizationHeader(withAPIKey: Self.apiKey)
    }

    func testCreateAliasCachesForSameUserIDs() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success, response: nil)
        )

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testCreateAliasDoesntCacheForDifferentNewUserID() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success, response: nil)
        )

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: Self.userID, newAppUserID: "another_new_alias") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testCreateAliasCachesWhenCallbackNil() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success, response: nil)
        )

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias") { _ in }
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new_alias", completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testCreateAliasCallsAllCompletionBlocksInCache() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success, response: nil)
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

        let response = MockHTTPClient.Response(statusCode: .success, response: nil)

        httpClient.mock(requestPath: .createAlias(appUserID: currentAppUserID1), response: response)
        backend.createAlias(appUserID: currentAppUserID1, newAppUserID: newAppUserID) { _ in }

        httpClient.mock(requestPath: .createAlias(appUserID: currentAppUserID2), response: response)
        backend.createAlias(appUserID: currentAppUserID2, newAppUserID: newAppUserID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testNetworkErrorIsForwarded() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: nil,
                            error: NSError(domain: NSURLErrorDomain, code: -1009))
        )

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?
        backend.createAlias(appUserID: Self.userID, newAppUserID: "new", completion: { error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.domain).toEventually(equal(RCPurchasesErrorCodeDomain))
        expect(receivedError?.code).toEventually(equal(ErrorCode.networkError.rawValue))
        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.domain).toEventually(equal(NSURLErrorDomain))
        expect(receivedUnderlyingError?.code).toEventually(equal(-1009))
    }

    func testForwards500ErrorsCorrectly() {
        self.httpClient.mock(
            requestPath: .createAlias(appUserID: Self.userID),
            response: .init(statusCode: .internalServerError, response: Self.serverErrorResponse)
        )

        var receivedError: NSError?
        var receivedUnderlyingError: NSError?

        backend.createAlias(appUserID: Self.userID, newAppUserID: "new", completion: { error in
            receivedError = error as NSError?
            receivedUnderlyingError = receivedError?.userInfo[NSUnderlyingErrorKey] as? NSError
        })

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError?.code).toEventually(be(ErrorCode.invalidCredentialsError.rawValue))

        expect(receivedUnderlyingError).toEventuallyNot(beNil())
        expect(receivedUnderlyingError?.localizedDescription) == Self.serverErrorResponse["message"]
    }

}
