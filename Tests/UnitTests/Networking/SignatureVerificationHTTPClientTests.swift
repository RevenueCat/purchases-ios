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
class BaseSignatureVerificationHTTPClientTests: BaseHTTPClientTests<ETagManager> {

    private var userDefaultsSuiteName: String!
    fileprivate var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        // Note: these tests use the real `ETagManager`
        self.userDefaultsSuiteName = UUID().uuidString
        self.userDefaults = .init(suiteName: self.userDefaultsSuiteName)!
        self.eTagManager = ETagManager(userDefaults: self.userDefaults)

        try super.setUpWithError()
    }

    override func tearDown() {
        // Clean up to avoid leaving leftover data in the simulator
        if let defaults = self.userDefaults, let suiteName = self.userDefaultsSuiteName {
            defaults.removePersistentDomain(forName: suiteName)
        }

        super.tearDown()
    }

    fileprivate static let path: HTTPRequest.Path = .mockPath
    fileprivate static let eTag = "etag"
    fileprivate static let sampleSignature = "signature"
    fileprivate static let date1 = Date().addingTimeInterval(-30000000)
    fileprivate static let date2 = Date().addingTimeInterval(-1000000)

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class SignatureVerificationHTTPClientTests: BaseSignatureVerificationHTTPClientTests {

    func testAutomaticallyAddsNonceIfRequired() {
        self.changeClient(.informational)

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

    func testFailedVerificationIfResponseContainsNoSignature() {
        self.changeClient(.informational)
        self.mockResponse()

        self.signing.stubbedVerificationResult = true

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)
        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
        expect(self.signing.requests).to(beEmpty())

        self.logger.verifyMessageWasLogged(
            Strings.signing.signature_was_requested_but_not_provided(request),
            level: .warn
        )
    }

    func testFailedVerificationIfResponseContainsNoSignatureForEndpointWithStaticSignature() {
        // This test relies on a path with static signatures
        let path: HTTPRequest.Path = .getProductEntitlementMapping
        expect(path.supportsSignatureVerification) == true
        expect(path.needsNonceForSigning) == false

        self.changeClient(.informational)
        self.mockResponse(path: path,
                          signature: nil,
                          requestDate: nil)

        self.signing.stubbedVerificationResult = true

        let request: HTTPRequest = .init(method: .get, path: path)
        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
        expect(self.signing.requests).to(beEmpty())

        self.logger.verifyMessageWasLogged(
            Strings.signing.signature_was_requested_but_not_provided(request),
            level: .warn
        )
    }

    func testHeadersAreCaseInsensitive() {
        self.changeClient(.informational)

        stub(condition: isPath(Self.path)) { _ in
            return .init(data: Data(),
                         statusCode: .success,
                         headers: [
                            "x-signature": "signature",
                            "x-revenuecat-request-time": String(Date().millisecondsSince1970)
                         ])
        }

        self.signing.stubbedVerificationResult = true

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified
    }

    func testSignatureNotRequested() {
        self.changeClient(.disabled)
        self.mockResponse()

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .notRequested

        expect(self.signing.requests).to(beEmpty())
    }

    func testVerifiedCachedResponseWithNotRequestedVerificationResponse() throws {
        self.changeClient(.disabled)

        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        self.mockPath(
            statusCode: .notModified,
            requestDate: Self.date2,
            eTagResponse: .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: try cachedResponse.jsonEncodedData,
                validationTime: Self.date1,
                verificationResult: .verified
            )
        )

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(self.signing.requests).to(beEmpty())

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseToDate(Self.date2))
        expect(response?.value?.verificationResult) == .notRequested
    }

    func testPostRequestWithPostParametersHeader() throws {
        self.changeClient(.informational)

        let body = BodyWithSignature(key1: "a", key2: "b")

        let request = HTTPRequest(method: .post(body), path: .mockPath)

        let headers: [String: String]? = waitUntilValue { completion in
            stub(condition: isPath(request.path)) { request in
                completion(request.allHTTPHeaderFields)
                return .emptySuccessResponse()
            }

            self.client.perform(request) { (_: EmptyResponse) in }
        }

        let header = try XCTUnwrap(headers?[HTTPClient.RequestHeader.postParameters.rawValue] as? String)
        expect(header) == "key1,key2:sha256:59b271ae1bbcb1d31d41929817f4b16fb439eb4f31520b5ad1d5ce98920a7138"
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class InformationalSignatureVerificationHTTPClientTests: BaseSignatureVerificationHTTPClientTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.changeClient(.informational)
    }

    func testValidSignature() throws {
        let body = "body".asData

        self.mockResponse(signature: Self.sampleSignature,
                          requestDate: Self.date2,
                          body: body)
        self.signing.stubbedVerificationResult = true

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified

        expect(self.signing.requests).to(haveCount(1))
        let signingRequest = try XCTUnwrap(self.signing.requests.onlyElement)

        expect(signingRequest.parameters.message) == body
        expect(signingRequest.parameters.nonce) == request.nonce
        expect(signingRequest.parameters.requestDate) == Self.date2.millisecondsSince1970
        expect(signingRequest.signature) == Self.sampleSignature
        expect(signingRequest.publicKey).toNot(beNil())
    }

    func testPerformRequestOverridesVerificationMode() throws {
        self.mockPath(statusCode: .success, requestDate: Self.date1)

        self.signing.stubbedVerificationResult = false

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: .logIn),
                                with: Signing.verificationMode(with: .informational),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
    }

    func testValidSignatureWithETagResponse() throws {
        let body = "body".asData

        self.mockPath(
            statusCode: .notModified,
            requestDate: Self.date1,
            eTagResponse: .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: body,
                verificationResult: .verified
            )
        )

        self.signing.stubbedVerificationResult = true

        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified
        expect(response?.value?.body) == body

        expect(self.signing.requests).to(haveCount(1))
        let signingRequest = try XCTUnwrap(self.signing.requests.onlyElement)

        expect(signingRequest.parameters.message).to(beNil())
        expect(signingRequest.parameters.nonce) == request.nonce
        expect(signingRequest.parameters.requestDate) == Self.date1.millisecondsSince1970
        expect(signingRequest.signature) == Self.sampleSignature
        expect(signingRequest.publicKey).toNot(beNil())
    }

    func testIncorrectSignatureReturnsResponse() throws {
        self.mockPath(statusCode: .success, requestDate: Self.date1)

        self.signing.stubbedVerificationResult = false

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
        expect(self.signing.requests).to(haveCount(1))
    }

    func testIncorrectSignatureLogsError() throws {
        let request: HTTPRequest = .createWithResponseVerification(method: .get, path: Self.path)
        self.mockPath(request.path, statusCode: .success, requestDate: Self.date1)
        self.signing.stubbedVerificationResult = false

        let _: DataResponse? = waitUntilValue { completion in
            self.client.perform(request, completionHandler: completion)
        }

        self.logger.verifyMessageWasLogged(
            Strings.signing.request_failed_verification(request),
            level: .error,
            expectedCount: 1
        )
    }

    func testIgnoresResponseFromETagManagerIfItHadNotBeenVerified() throws {
        self.signing.stubbedVerificationResult = true

        self.mockPath(
            statusCode: .success,
            requestDate: Self.date1,
            signature: Self.sampleSignature,
            eTagResponse: .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: .init(),
                verificationResult: .notRequested
            )
        )

        let response: VerifiedHTTPResponse<Data>.Result? = waitUntilValue { completion in
            self.client.perform(
                .createWithResponseVerification(method: .get, path: Self.path),
                completionHandler: completion
            )
        }

        expect(response).toNot(beNil())
        expect(response?.value?.statusCode) == .success
        expect(response?.value?.verificationResult) == .verified
    }

    func testCachedResponseDoesNotUpdateRequestDateIfNewResponseVerificationFails() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        self.mockPath(
            statusCode: .notModified,
            requestDate: Self.date2,
            eTagResponse: try .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: cachedResponse,
                verificationResult: .verified
            )
        )
        self.signing.stubbedVerificationResult = false

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseToDate(cachedResponse.requestDate))
        expect(response?.value?.verificationResult) == .failed
    }

    func testCachedResponseWithVerifiedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        self.mockPath(
            statusCode: .notModified,
            requestDate: Self.date2,
            eTagResponse: try .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: cachedResponse,
                validationTime: Self.date1,
                verificationResult: .verified
            )
        )

        self.signing.stubbedVerificationResult = true

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseToDate(Self.date2))
        expect(response?.value?.verificationResult) == .verified
    }

    func testNotModifiedResponseFailedVerification() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        self.mockPath(
            statusCode: .notModified,
            requestDate: Self.date2,
            eTagResponse: try .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: cachedResponse,
                validationTime: Self.date1,
                verificationResult: .verified
            )
        )

        self.signing.stubbedVerificationResult = false

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.data) == cachedResponse.data
        expect(response?.value?.body.requestDate).to(beCloseToDate(cachedResponse.requestDate))
        expect(response?.value?.verificationResult) == .failed
    }

    func testCachedResponseUpdatesRequestDateIfNewResponseIsVerified() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        self.signing.stubbedVerificationResult = true

        self.mockPath(
            statusCode: .notModified,
            requestDate: Self.date2,
            eTagResponse: try .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: cachedResponse,
                validationTime: Self.date1,
                verificationResult: .verified
            )
        )

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseToDate(Self.date2))
        expect(response?.value?.verificationResult) == .verified
    }

    func testCachedResponseWithFailedVerificationAndFailedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        self.mockPath(
            statusCode: .notModified,
            requestDate: Self.date2,
            eTagResponse: try .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: cachedResponse,
                validationTime: Self.date1,
                verificationResult: .failed
            )
        )

        self.signing.stubbedVerificationResult = false

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(self.signing.requests).to(haveCount(1))
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseToDate(Self.date1))
        expect(response?.value?.verificationResult) == .failed
    }

    func testNoCachedResponseAndNotVerifiedResponse() throws {
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: "user")

        self.mockPath(path, statusCode: .success, requestDate: Self.date2, signature: nil)

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: path),
                                completionHandler: completion)
        }

        expect(self.signing.requests).to(beEmpty())
        expect(response).to(beSuccess())
        expect(response?.value?.requestDate).to(beCloseToDate(Self.date2))
        expect(response?.value?.verificationResult) == .failed
    }

    func testNoCachedResponseAndVerifiedResponse() throws {
        self.mockPath(statusCode: .success, requestDate: Self.date2)
        self.signing.stubbedVerificationResult = true

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(self.signing.requests).to(haveCount(1))
        expect(response).to(beSuccess())
        expect(response?.value?.requestDate).to(beCloseToDate(Self.date2))
        expect(response?.value?.verificationResult) == .verified
    }

    func testIgnoredCachedResponseWithFailedVerificationAndFailedResponse() throws {
        let cachedResponse = BodyWithDate(data: "test", requestDate: Self.date1)

        self.mockResponse(
            path: Self.path,
            signature: Self.sampleSignature,
            requestDate: Self.date2,
            body: try cachedResponse.jsonEncodedData,
            statusCode: .success,
            eTagResponse: try .init(
                eTag: Self.eTag,
                statusCode: .success,
                data: cachedResponse,
                validationTime: Self.date1,
                verificationResult: .verified
            )
        )

        self.signing.stubbedVerificationResult = false

        let response: BodyWithDateResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(self.signing.requests).to(haveCount(1))
        expect(response).to(beSuccess())
        expect(response?.value?.body.requestDate).to(beCloseToDate(Self.date1))
        expect(response?.value?.verificationResult) == .failed
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class EnforcedSignatureVerificationHTTPClientTests: BaseSignatureVerificationHTTPClientTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.changeClientToEnforced()
    }

    func testValidSignature() {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        self.signing.stubbedVerificationResult = true

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .verified
        expect(self.signing.requests).to(haveCount(1))
    }

    func testIncorrectSignatureReturnsError() {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        self.signing.stubbedVerificationResult = false

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                completionHandler: completion)
        }

        expect(response).to(beFailure())
        expect(response?.error)
            .to(matchError(NetworkError.signatureVerificationFailed(path: Self.path, code: .success)))
    }

    func testPerformRequestOverridesIt() {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        self.signing.stubbedVerificationResult = false

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: .logIn),
                                with: Signing.enforcedVerificationMode(),
                                completionHandler: completion)
        }

        expect(response).to(beFailure())
        expect(response?.error)
            .to(matchError(NetworkError.signatureVerificationFailed(path: Self.path, code: .success)))
    }

    func testPerformRequestWithDisabledModeOverridesIt() {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)

        self.signing.stubbedVerificationResult = false

        let response: DataResponse? = waitUntilValue { completion in
            self.client.perform(.createWithResponseVerification(method: .get, path: Self.path),
                                with: .disabled,
                                completionHandler: completion)
        }

        expect(response).to(beSuccess())
    }

    func testFakeSignatureFailuresInEnforcedMode() {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)
        self.signing.stubbedVerificationResult = true

        self.changeClientToEnforced(forceSignatureFailures: true)

        let response: EmptyResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path), completionHandler: completion)
        }

        expect(response).to(beFailure())
        expect(response?.error) == NetworkError.signatureVerificationFailed(path: Self.path, code: .success)
    }

    func testFakeSignatureFailuresInInformationalMode() {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)
        self.signing.stubbedVerificationResult = true

        self.changeClient(.informational, forceSignatureFailures: true)

        let response: EmptyResponse? = waitUntilValue { completion in
            self.client.perform(.init(method: .get, path: Self.path), completionHandler: completion)
        }

        expect(response).to(beSuccess())
        expect(response?.value?.verificationResult) == .failed
    }

    func testFakeSignatureFailuresWithDisabledVerification() {
        self.mockResponse(signature: Self.sampleSignature, requestDate: Self.date1)
        self.signing.stubbedVerificationResult = true

        self.changeClient(.disabled, forceSignatureFailures: true)

        let response: EmptyResponse? = waitUntilValue { completion in
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
    ) {
        self.createClient(Signing.verificationMode(with: verificationMode),
                          forceSignatureFailures: forceSignatureFailures)
    }

    final func changeClientToEnforced(forceSignatureFailures: Bool = false) {
        self.createClient(Signing.enforcedVerificationMode(),
                          forceSignatureFailures: forceSignatureFailures)
    }

    private final func createClient(
        _ mode: Signing.ResponseVerificationMode,
        forceSignatureFailures: Bool = false
    ) {
        self.systemInfo = MockSystemInfo(
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
        path: HTTPRequestPath = BaseSignatureVerificationHTTPClientTests.path,
        signature: String?,
        requestDate: Date?,
        eTag: String? = nil,
        body: Data = .init(),
        statusCode: HTTPStatusCode = .success,
        eTagResponse: ETagManager.Response? = nil
    ) {
        stub(condition: isPath(path)) { [weak self] request in
            let headers: [String: String?] = [
                HTTPClient.ResponseHeader.signature.rawValue: signature,
                HTTPClient.ResponseHeader.eTag.rawValue: eTag,
                HTTPClient.ResponseHeader.requestDate.rawValue: requestDate.map { String($0.millisecondsSince1970) }
            ]

            if let eTagResponse = eTagResponse {
                // swiftlint:disable:next force_try
                try! self?.setETagCache(eTagResponse, for: request)
            }

            return .init(data: body,
                         statusCode: statusCode,
                         headers: headers.compactMapValues { $0 })
        }
    }

    final func mockPath(
        _ path: HTTPRequestPath = BaseSignatureVerificationHTTPClientTests.path,
        statusCode: HTTPStatusCode,
        requestDate: Date,
        signature: String? = BaseSignatureVerificationHTTPClientTests.sampleSignature,
        eTagResponse: ETagManager.Response? = nil
    ) {
        self.mockResponse(
            path: path,
            signature: signature,
            requestDate: requestDate,
            eTag: Self.eTag,
            body: .init(),
            statusCode: statusCode,
            eTagResponse: eTagResponse
        )
    }

    private func setETagCache(_ response: ETagManager.Response, for request: URLRequest) throws {
        self.userDefaults.set(try response.jsonEncodedData,
                              forKey: try XCTUnwrap(ETagManager.cacheKey(for: request)))
    }

}

private extension ETagManager.Response {

    init(
        eTag: String,
        statusCode: HTTPStatusCode,
        data: Encodable,
        validationTime: Date? = nil,
        verificationResult: VerificationResult
    ) throws {
        self.init(eTag: eTag,
                  statusCode: statusCode,
                  data: try data.jsonEncodedData,
                  validationTime: validationTime,
                  verificationResult: verificationResult
        )
    }

}
