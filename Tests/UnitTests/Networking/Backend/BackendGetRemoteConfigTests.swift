//
//  BackendGetRemoteConfigTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class BackendGetRemoteConfigTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    // MARK: - Basic request

    func testGetRemoteConfigCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success, response: Self.fullResponse)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testGetRemoteConfigUsesCorrectPath() {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success, response: Self.fullResponse)
        )

        waitUntil { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in completed() }
        }

        expect(self.httpClient.calls.map { $0.request.path as? HTTPRequest.Path }) == [.getRemoteConfig]
    }

    // MARK: - Jitterable delay

    func testGetRemoteConfigUsesDefaultJitterableDelayWhenBackgrounded() {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success, response: Self.fullResponse)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: true, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.default
    }

    func testGetRemoteConfigUsesNoDelayWhenNotBackgrounded() {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success, response: Self.fullResponse)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    // MARK: - Request coalescing

    func testGetRemoteConfigCoalescesSimultaneousRequests() {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success,
                            response: Self.fullResponse,
                            delay: .milliseconds(10))
        )

        let responses: Atomic<Int> = .init(0)

        self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in responses.value += 1 }
        self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in responses.value += 1 }

        expect(responses.value).toEventually(equal(2))
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testCoalescedRequestsLogDebugMessage() {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success,
                            response: Self.fullResponse,
                            delay: .milliseconds(10))
        )

        self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in }
        self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(GetRemoteConfigOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    // MARK: - Response parsing

    func testGetRemoteConfigParsesFullResponse() throws {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success, response: Self.fullResponse)
        )

        let result: Result<RemoteConfigResponse, BackendError>? = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.apiSources).to(haveCount(1))
        expect(response.apiSources[0].id) == "primary"
        expect(response.blobSources).to(haveCount(1))
        expect(response.blobSources[0].id) == "cloudfront-primary"

        let pem = response.manifest.topics[.productEntitlementMapping]
        expect(pem?["DEFAULT"]?.blobRef) == "6a4d0f53d9f6b8e2f4dca0fd1c7c4f5e3e1b1ef0"
    }

    func testGetRemoteConfigParsesEmptyResponse() throws {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(statusCode: .success, response: [:] as [String: Any])
        )

        let result: Result<RemoteConfigResponse, BackendError>? = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.apiSources).to(beEmpty())
        expect(response.blobSources).to(beEmpty())
        expect(response.manifest.topics).to(beEmpty())
    }

    // MARK: - Error handling

    func testGetRemoteConfigFailSendsError() {
        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beFailure())
    }

    func testGetRemoteConfigNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getRemoteConfig,
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

}

private extension BackendGetRemoteConfigTests {

    static let fullResponse: [String: Any] = [
        "api_sources": [
            [
                "id": "primary",
                "url": "https://api.revenuecat.com/",
                "priority": 0,
                "weight": 100
            ] as [String: Any]
        ],
        "blob_sources": [
            [
                "id": "cloudfront-primary",
                "url_format": "https://assets.revenuecat.com/rc_app_1234/{blob_ref}",
                "priority": 0,
                "weight": 100
            ] as [String: Any]
        ],
        "manifest": [
            "topics": [
                "product_entitlement_mapping": [
                    "DEFAULT": [
                        "blob_ref": "6a4d0f53d9f6b8e2f4dca0fd1c7c4f5e3e1b1ef0"
                    ]
                ]
            ]
        ] as [String: Any]
    ]

}
