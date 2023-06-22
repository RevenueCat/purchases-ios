//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SignatureVerificationHTTPClientTests.swift
//
//  Created by Nacho Soto on 3/13/23.

import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import RevenueCat

// swiftlint:disable type_name

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class BaseSignatureVerificationHTTPClientTests: BaseHTTPClientTests {

    override func setUpWithError() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        try super.setUpWithError()
    }

    fileprivate static let path: HTTPRequest.Path = .mockPath
    fileprivate static let eTag = "etag"
    fileprivate static let sampleSignature = "signature"
    fileprivate static let date1 = Date().addingTimeInterval(-30000000)
    fileprivate static let date2 = Date().addingTimeInterval(-1000000)

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class SignatureVerificationHTTPClientTests: BaseSignatureVerificationHTTPClientTests {

    func testAutomaticallyAddsNonceIfRequired() throws {
        try self.changeClient(.informational)

        let request = HTTPRequest(method: .get, path: .getCustomerInfo(appUserID: "user"))

        let headers: [String: String]? = waitUntilValue { completion in
            stub(condition: isPath(request.path)) { request in
                completion(request.allHTTPHeaderFields)
                return .emptySuccessResponse()
            }

            self.client.perform(request) { (_: EmptyResponse) in }
        }

        expect(headers).toNot(beEmpty())
        expect(headers?.keys).to(contain(HTTPClient.RequestHeader.nonce.rawValue))
        expect(headers?[HTTPClient.RequestHeader.nonce.rawValue]).toNot(beNil())
    }

    func testRequestIncludesRandomNonce() throws {
        let request = HTTPRequest.createWithResponseVerification(method: .get, path: Self.path)

        let headers: [String: String]? = waitUntilValue { completion in
            stub(condition: isPath(request.path)) { request in
                completion(request.allHTTPHeaderFields)
                return .emptySuccessResponse()
            }

            self.client.perform(request) { (_: EmptyResponse) in }
        }

        expect(headers).toNot(beEmpty())
        expect(headers?.keys).to(contain(HTTPClient.RequestHeader.nonce.rawValue))
        expect(headers?[HTTPClient.RequestHeader.nonce.rawValue]) == request.nonce?.base64EncodedString()
    }

    func testFailedVerificationIfResponseContainsNoSignature() throws {
        let logger = TestLogHandler()

        try self.changeClient(.informational)
        self.mockResponse()

        MockSigning.stubbedVerificationResult = true

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)
        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
        expect(MockSigning.requests).to(beEmpty())

        logger.verifyMessageWasLogged(
            Strings.signing.signature_was_requested_but_not_provided(request),
            level: .warn
        )
    }

    func testHeadersAreCaseInsensitive() throws {
        try self.changeClient(.informational)

        stub(condition: isPath(Self.path)) { _ in
            return .init(data: Data(),
                         statusCode: .success,
                         headers: [
                            "x-signature": "signature",
                            "x-revenuecat-request-time": String(Date().millisecondsSince1970)
                         ])
        }

        MockSigning.stubbedVerificationResult = true

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified
    }

    func testSignatureNotRequested() throws {
        try self.changeClient(.disabled)
        self.mockResponse()

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .notRequested

        expect(MockSigning.requests).to(beEmpty())
    }

    func testVerifiedCachedResponseWithNotRequestedVerificationResponse() throws {
        try self.changeClient(.disabled)

        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(
            response: cachedResponse,
            requestDate: Self.date1,
            verificationResult: .verified
        )
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(MockSigning.requests).to(beEmpty())

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date1, within: 1))
        expect(response?.value?.verificationResult) == .notRequested
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class InformationalSignatureVerificationHTTPClientTests: BaseSignatureVerificationHTTPClientTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try self.changeClient(.informational)
    }

    func testValidSignature() throws {
        let body = "body".asData

        self.mockResponse(signature: Self.sampleSignature,
                          requestDate: Self.date2,
                          body: body)
        MockSigning.stubbedVerificationResult = true

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified

        expect(MockSigning.requests).to(haveCount(1))
        let signingRequest = try XCTUnwrap(MockSigning.requests.onlyElement)

        expect(signingRequest.parameters.message) == body
        expect(signingRequest.parameters.nonce) == request.nonce
        expect(signingRequest.parameters.requestDate) == Self.date2.millisecondsSince1970
        expect(signingRequest.signature) == Self.sampleSignature
        expect(signingRequest.publicKey).toNot(beNil())
    }

    func testPerformRequestOverridesVerificationMode() throws {
        self.mockPath(statusCode: .success, requestDate: Self.date1)

        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: .logIn),
                                with: Signing.verificationMode(with: .informational),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
    }

    func testValidSignatureWithETagResponse() throws {
        XCTExpectFailure("Not yet implemented")

        let body = "body".asData

        self.mockPath(statusCode: .notModified, requestDate: Self.date1)
        MockSigning.stubbedVerificationResult = true

        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = .init(
            statusCode: .success,
            responseHeaders: [:],
            body: body,
            verificationResult: .verified
        )

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified
        expect(response?.value?.body) == body

        expect(MockSigning.requests).to(haveCount(1))
        let signingRequest = try XCTUnwrap(MockSigning.requests.onlyElement)

        expect(signingRequest.parameters.message) == body
        expect(signingRequest.parameters.nonce) == request.nonce
        expect(signingRequest.parameters.requestDate) == Self.date1.millisecondsSince1970
        expect(signingRequest.signature) == Self.sampleSignature
        expect(signingRequest.publicKey).toNot(beNil())
    }

    func testIncorrectSignatureReturnsResponse() throws {
        self.mockPath(statusCode: .success, requestDate: Self.date1)

        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
        expect(MockSigning.requests).to(haveCount(1))
    }

    func testIgnoresResponseFromETagManagerIfItHadNotBeenVerified() throws {
        MockSigning.stubbedVerificationResult = true

        stub(condition: isPath(Self.path)) { request in
            expect(request.allHTTPHeaderFields?.keys).toNot(contain(ETagManager.eTagResponseHeaderName))

            return .init(data: Data(),
                         statusCode: .success,
                         headers: [
                            HTTPClient.ResponseHeader.signature.rawValue: Self.sampleSignature,
                            HTTPClient.ResponseHeader.requestDate.rawValue: String(Self.date1.millisecondsSince1970)
                         ])
        }

        self.eTagManager.shouldReturnResultFromBackend = true

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(
                .createWithResponseVerification(method: .get, path: Self.path)
            ) { (result: HTTPResponse<Data>.Result) in
                completion(result)
            }
        }

        expect(self.eTagManager.invokedETagHeaderParametersList).to(haveCount(1))
        expect(self.eTagManager.invokedETagHeaderParameters?.withSignatureVerification) == true
        expect(self.eTagManager.invokedETagHeaderParameters?.refreshETag) == false

        expect(response).toNot(beNil())
        expect(response?.value?.statusCode) == .success
        expect(response?.value?.verificationResult) == .verified
    }

    func testCachedResponseDoesNotUpdateRequestDateIfNewResponseVerificationFails() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date1,
                               verificationResult: .notRequested)
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)
        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseTo(cachedResponse.requestDate, within: 1))
        expect(response?.value?.verificationResult) == .failed
    }

    func testCachedResponseWithoutVerificationAndVerifiedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .notRequested)
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)
        MockSigning.stubbedVerificationResult = true

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date2, within: 1))
        expect(response?.value?.verificationResult) == .verified
    }

    func testNotModifiedResponseFailedVerification() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .verified)
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)

        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseTo(cachedResponse.requestDate, within: 1))
        expect(response?.value?.verificationResult) == .failed
    }

    func testCachedResponseUpdatesRequestDateIfNewResponseIsVerified() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        MockSigning.stubbedVerificationResult = true
        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .verified)
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date2, within: 1))
        expect(response?.value?.verificationResult) == .verified
    }

    func testCachedResponseWithFailedVerificationAndNotRequestedVerification() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .failed)
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: .getOfferings(appUserID: "user")),
                                completionHandler: completion)
        }

        expect(MockSigning.requests).to(beEmpty())
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date2, within: 1))
        expect(response?.value?.verificationResult) == .notRequested
    }

    func testCachedResponseWithFailedVerificationAndVerifiedResponse() throws {
        // This won't happen in practice because the ETag won't be used if its verification failed.

        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date1,
                               verificationResult: .failed)
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)
        MockSigning.stubbedVerificationResult = true

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(MockSigning.requests).to(haveCount(1))
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date1, within: 1))
        expect(response?.value?.verificationResult) == .verified
    }

    func testCachedResponseWithFailedVerificationAndFailedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .failed)
        self.mockPath(statusCode: .notModified, requestDate: Self.date2)
        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(MockSigning.requests).to(haveCount(1))
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date1, within: 1))
        expect(response?.value?.verificationResult) == .failed
    }

    func testIgnoredCachedResponseAndNotVerifiedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .failed)
        self.mockPath(statusCode: .success, requestDate: Self.date2)

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: .getOfferings(appUserID: "user")),
                                completionHandler: completion)
        }

        expect(MockSigning.requests).to(beEmpty())
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date2, within: 1))
        expect(response?.value?.verificationResult) == .notRequested
    }

    func testIgnoredCachedResponseAndVerifiedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .failed)
        self.mockPath(statusCode: .success, requestDate: Self.date2)
        MockSigning.stubbedVerificationResult = true

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(MockSigning.requests).to(haveCount(1))
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date2, within: 1))
        expect(response?.value?.verificationResult) == .verified
    }

    func testIgnoredCachedResponseWithFailedVerificationAndFailedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        try self.mockETagCache(response: cachedResponse,
                               requestDate: Self.date2,
                               verificationResult: .failed)
        self.mockPath(statusCode: .success, requestDate: Self.date2)
        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<BodyWithDate>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(MockSigning.requests).to(haveCount(1))
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseTo(Self.date1, within: 1))
        expect(response?.value?.verificationResult) == .failed
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class EnforcedSignatureVerificationHTTPClientTests: BaseSignatureVerificationHTTPClientTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try self.changeClientToEnforced()
    }

    func testValidSignature() throws {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        MockSigning.stubbedVerificationResult = true

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified
        expect(MockSigning.requests).to(haveCount(1))
    }

    func testIncorrectSignatureReturnsError() throws {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beFailure())
        expect(response?.error)
            .to(matchError(NetworkError.signatureVerificationFailed(path: Self.path, code: .success)))
    }

    func testPerformRequestOverridesIt() throws {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: .logIn),
                                with: Signing.enforcedVerificationMode(),
                                completionHandler: completion)
        }

        expect(response).to(beFailure())
        expect(response?.error)
            .to(matchError(NetworkError.signatureVerificationFailed(path: Self.path, code: .success)))
    }

    func testPerformRequestWithDisabledModeOverridesIt() throws {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        MockSigning.stubbedVerificationResult = false

        let response: HTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                with: .disabled,
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
    }

    func testFakeSignatureFailuresInEnforcedMode() throws {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)
        MockSigning.stubbedVerificationResult = true

        try self.changeClientToEnforced(forceSignatureFailures: true)

        let response: HTTPResponse<HTTPEmptyResponseBody>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path), completionHandler: completion)
        }

        expect(response).to(beFailure())
        expect(response?.error) == NetworkError.signatureVerificationFailed(path: Self.path, code: .success)
    }

    func testFakeSignatureFailuresInInformationalMode() throws {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)
        MockSigning.stubbedVerificationResult = true

        try self.changeClient(.informational, forceSignatureFailures: true)

        let response: HTTPResponse<HTTPEmptyResponseBody>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
    }

    func testFakeSignatureFailuresWithDisabledVerification() throws {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)
        MockSigning.stubbedVerificationResult = true

        try self.changeClient(.disabled, forceSignatureFailures: true)

        let response: HTTPResponse<HTTPEmptyResponseBody>.Result? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .notRequested
    }

}

// MARK: - Private

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension BaseSignatureVerificationHTTPClientTests {

    final func changeClient(
        _ verificationMode: Configuration.EntitlementVerificationMode,
        forceSignatureFailures: Bool = false
    ) throws {
        try self.createClient(Signing.verificationMode(with: verificationMode),
                              forceSignatureFailures: forceSignatureFailures)
    }

    final func changeClientToEnforced(forceSignatureFailures: Bool = false) throws {
        try self.createClient(Signing.enforcedVerificationMode(),
                              forceSignatureFailures: forceSignatureFailures)
    }

    private final func createClient(
        _ mode: Signing.ResponseVerificationMode,
        forceSignatureFailures: Bool = false
    ) throws {
        self.systemInfo = try MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            responseVerificationMode: mode,
            dangerousSettings: .init(
                autoSyncPurchases: true,
                internalSettings: DangerousSettings.Internal(forceSignatureFailures: forceSignatureFailures)
            )
        )
        self.client = self.createClient()
    }

    final func mockResponse() {
        self.mockResponse(signature: nil, requestDate: nil)
    }

    final func mockResponse(
        signature: String?,
        requestDate: Date?,
        eTag: String? = nil,
        body: Data = .init(),
        statusCode: HTTPStatusCode = .success
    ) {
        stub(condition: isPath(Self.path)) { _ in
            if let signature = signature, let requestDate = requestDate {
                let headers: [String: String?] = [
                    HTTPClient.ResponseHeader.signature.rawValue: signature,
                    HTTPClient.ResponseHeader.eTag.rawValue: eTag,
                    HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate.millisecondsSince1970)
                ]

                return .init(data: body,
                             statusCode: statusCode,
                             headers: headers.compactMapValues { $0 })
            } else {
                return .emptySuccessResponse()
            }
        }
    }

    final func mockETagCache(response: BodyWithDate,
                             requestDate: Date,
                             verificationResult: VerificationResult) throws {
        self.eTagManager.stubResponseEtag(Self.eTag)
        self.eTagManager.shouldReturnResultFromBackend = false
        self.eTagManager.stubbedHTTPResultFromCacheOrBackendResult = .init(
            statusCode: .success,
            responseHeaders: [
                HTTPClient.ResponseHeader.requestDate.rawValue: String(requestDate.millisecondsSince1970)
            ],
            body: try response.jsonEncodedData,
            verificationResult: verificationResult
        )
    }

    func mockPath(statusCode: HTTPStatusCode, requestDate: Date) {
        self.mockResponse(
            signature: Self.sampleSignature,
            requestDate: requestDate,
            eTag: Self.eTag,
            body: .init(),
            statusCode: statusCode
        )
    }

}
