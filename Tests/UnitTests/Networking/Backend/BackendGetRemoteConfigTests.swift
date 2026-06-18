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

    override func setUpWithError() throws {
        try super.setUpWithError()

        // swiftlint:disable:next todo
        // TODO: Re-enable snapshots once the remote-config network stack is final.
        self.httpClient.disableSnapshotTesting()
    }

    // MARK: - Basic request

    func testGetRemoteConfigCallsHTTPMethod() {
        self.mockSuccessfulResponse()

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.httpClient.calls.first?.request.method.httpMethod) == "POST"
    }

    func testGetRemoteConfigUsesCorrectPath() {
        self.mockSuccessfulResponse()

        waitUntil { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in completed() }
        }

        expect(self.httpClient.calls.map { $0.request.path as? HTTPRequest.Path }) == [.remoteConfig]
        expect(self.httpClient.calls.first?.request.path.relativePath) == "/v2/config"
    }

    func testGetRemoteConfigEncodesDefaultRequestBody() throws {
        self.mockSuccessfulResponse()

        waitUntil { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in completed() }
        }

        let body = try XCTUnwrap(self.httpClient.calls.first?.request.requestBody?.asJSONDictionary())
        expect(body).to(beEmpty())
    }

    func testGetRemoteConfigRequestsRCContainerFormat() {
        self.mockSuccessfulResponse()

        waitUntil { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in completed() }
        }

        expect(self.httpClient.calls.first?.headers[HTTPClient.RequestHeader.accept.rawValue])
            == HTTPClient.rcContainerFormatAcceptHeaderValue
    }

    func testGetRemoteConfigDoesNotSendETagHeaders() {
        self.mockSuccessfulResponse()

        waitUntil { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in completed() }
        }

        expect(self.httpClient.calls.first?.headers[ETagManager.eTagRequestHeader.rawValue]).to(beNil())
        expect(self.httpClient.calls.first?.headers[ETagManager.eTagValidationTimeRequestHeader.rawValue]).to(beNil())
    }

    func testGetRemoteConfigDoesNotSendSignatureVerificationHeaders() {
        self.mockSuccessfulResponse()

        waitUntil { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in completed() }
        }

        let headers = self.httpClient.calls.first?.headers
        expect(headers?[HTTPClient.RequestHeader.nonce.rawValue]).to(beNil())
        expect(headers?[HTTPClient.RequestHeader.headerParametersForSignature.rawValue]).to(beNil())
        expect(headers?[HTTPClient.RequestHeader.postParameters.rawValue]).to(beNil())
    }

    // MARK: - Jitterable delay

    func testGetRemoteConfigUsesDefaultJitterableDelayWhenBackgrounded() {
        self.mockSuccessfulResponse()

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: true, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.default
    }

    func testGetRemoteConfigUsesNoDelayWhenNotBackgrounded() {
        self.mockSuccessfulResponse()

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    // MARK: - Request coalescing

    func testGetRemoteConfigCoalescesSimultaneousRequests() {
        self.mockSuccessfulResponse(delay: .milliseconds(10))

        let responses: Atomic<Int> = .init(0)

        self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in responses.value += 1 }
        self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false) { _ in responses.value += 1 }

        expect(responses.value).toEventually(equal(2))
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testCoalescedRequestsLogDebugMessage() {
        self.mockSuccessfulResponse(delay: .milliseconds(10))

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

    func testGetRemoteConfigParsesRCContainerResponse() throws {
        self.mockSuccessfulResponse()

        let result: Result<RCContainer?, BackendError>? = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        let container = try XCTUnwrap(try XCTUnwrap(result?.value))
        expect(RCContainerTestData.data(from: container.config)) == Self.config
        expect(container.contentElements).to(haveCount(1))
        expect(RCContainerTestData.data(
            from: try XCTUnwrap(container.contentElements[RCContainerTestData.blobRef(for: Self.content)])
        )) == Self.content
    }

    func testGetRemoteConfigNoContentResponseSucceedsWithNoContainer() throws {
        self.httpClient.mock(
            requestPath: .remoteConfig,
            response: .init(statusCode: .noContent, body: Data())
        )

        let result: Result<RCContainer?, BackendError>? = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beSuccess())
        expect(try XCTUnwrap(result?.value)).to(beNil())
    }

    // MARK: - Error handling

    func testGetRemoteConfigFailSendsError() {
        self.httpClient.mock(
            requestPath: .remoteConfig,
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
            requestPath: .remoteConfig,
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetRemoteConfigErrorResponseSendsErrorWithoutParsingRCContainer() {
        let errorResponse = ErrorResponse(code: .internalServerError, originalCode: 7110)
        let mockedError: NetworkError = .errorResponse(errorResponse, .internalServerError)

        self.httpClient.mock(
            requestPath: .remoteConfig,
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetRemoteConfigInvalidRCContainerSendsDecodingError() {
        self.httpClient.mock(
            requestPath: .remoteConfig,
            response: .init(statusCode: .success, body: "not an rc container".asData)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        guard case let .networkError(.decoding(error, _)) = result?.error else {
            fail("Expected decoding error, got \(String(describing: result?.error))")
            return
        }

        expect(error.domain) == String(reflecting: RCContainer.Parser.FormatError.self)
    }

    func testGetRemoteConfigSuccessfulJSONResponseSendsDecodingError() {
        self.httpClient.mock(
            requestPath: .remoteConfig,
            response: .init(statusCode: .success, body: #"{"api_sources":[]}"#.asData)
        )

        let result = waitUntilValue { completed in
            self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: false, completion: completed)
        }

        guard case let .networkError(.decoding(error, _)) = result?.error else {
            fail("Expected decoding error, got \(String(describing: result?.error))")
            return
        }

        expect(error.domain) == String(reflecting: RCContainer.Parser.FormatError.self)
    }

}

private extension BackendGetRemoteConfigTests {

    static let config = #"{"manifest":{}}"#.asData
    static let content = #"{"products":[]}"#.asData

    static var containerData: Data {
        return RCContainerTestData.container(config: Self.config, contentElements: [Self.content])
    }

    func mockSuccessfulResponse(delay: DispatchTimeInterval = .never) {
        self.httpClient.mock(
            requestPath: .remoteConfig,
            response: .init(
                statusCode: .success,
                body: Self.containerData,
                delay: delay
            )
        )
    }

}
