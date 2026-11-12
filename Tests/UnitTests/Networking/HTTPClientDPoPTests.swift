//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPClientDPoPTests.swift
//
//  Created by Dave DeLong on 11/9/26.

import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable @_spi(Internal) import RevenueCat

final class HTTPClientDPoPTests: BaseHTTPClientTests<MockETagManager, HTTPRequestTimeoutManager> {

    private var userProvider: MockCurrentUserProvider!

    override func setUpWithError() throws {
        self.eTagManager = MockETagManager()
        self.timeoutManager = HTTPRequestTimeoutManager(
            networkTimeout: .default,
            dateProvider: MockCurrentDateProvider()
        )

        self.userProvider = MockCurrentUserProvider(mockAppUserID: "test-user")
        let tokenManager = TokenManager(enabled: true, storage: MockSecureItemStorage())
        tokenManager.currentUserProvider = self.userProvider
        tokenManager.currentAccessToken = try TokenManagerTests.makeToken(
            header: ["alg": "none"],
            payload: ["cnf": ["jkt": "key-thumbprint"]]
        )
        self.tokenManager = tokenManager

        try super.setUpWithError()
    }

    func testProofIsBoundToTheURLTheRequestIsSentTo() throws {
        let request = HTTPRequest(method: .get, path: .getCustomerInfo(appUserID: "dave@revenuecat.com"))

        let host = try XCTUnwrap(SystemInfo.apiBaseURL.host)

        let sentRequest: URLRequest? = waitUntilValue { completion in
            stub(condition: isHost(host)) { request in
                completion(request)
                return .emptySuccessResponse()
            }

            self.client.perform(request) { (_: EmptyResponse) in }
        }

        let headers = try XCTUnwrap(sentRequest?.allHTTPHeaderFields)
        let proof = try JWT(from: try XCTUnwrap(headers[HTTPClient.RequestHeader.dpop.rawValue]))
        let expectedHTU = try XCTUnwrap(sentRequest?.url?.absoluteString)

        expect(headers[HTTPClient.RequestHeader.authorization.rawValue]).to(beginWith("DPoP "))
        expect(proof.payload["htm"] as? String) == "GET"
        expect(proof.payload["htu"] as? String) == expectedHTU
        expect(expectedHTU).to(contain("dave%40revenuecat.com"))
    }

    func testRetriedRequestsGetAFreshProof() throws {
        let request = HTTPRequest(method: .get, path: .getCustomerInfo(appUserID: "test-user"), isRetryable: true)
        let proofIdentifiers: Atomic<[String]> = .init([])
        let host = try XCTUnwrap(SystemInfo.apiBaseURL.host)

        stub(condition: isHost(host)) { request in
            let proof = request.allHTTPHeaderFields?[HTTPClient.RequestHeader.dpop.rawValue]
            let jti = proof.flatMap { try? JWT(from: $0) }?.payload["jti"] as? String
            let count = proofIdentifiers.modify { identifiers in
                identifiers.append(jti ?? "")
                return identifiers.count
            }

            guard count > 1 else {
                return HTTPStubsResponse(data: Data(),
                                         statusCode: Int32(HTTPStatusCode.tooManyRequests.rawValue),
                                         headers: [HTTPClient.ResponseHeader.retryAfter.rawValue: "0"])
            }
            return .emptySuccessResponse()
        }

        waitUntil { completion in
            self.client.perform(request) { (_: EmptyResponse) in completion() }
        }

        expect(proofIdentifiers.value).to(haveCount(2))
        expect(proofIdentifiers.value).toNot(contain(""))
        expect(Set(proofIdentifiers.value)).to(haveCount(2))
    }

}
