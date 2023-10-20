//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPResponseTests.swift
//
//  Created by Nacho Soto on 3/9/22.

import CryptoKit
import Nimble
import XCTest

@testable import RevenueCat

class HTTPResponseTests: TestCase {

    private static let signing: Signing = .init(apiKey: "api_key")

    func testResponseVerificationNotRequestedWithNoPublicKey() {
        let request = HTTPRequest(method: .get, path: .health)
        let response = HTTPResponse<Data?>(
            httpStatusCode: .success,
            responseHeaders: [:],
            body: Data()
        )
        let verifiedResponse = response.verify(signing: Self.signing, request: request, publicKey: nil)

        expect(verifiedResponse.verificationResult) == .notRequested
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testResponseVerificationNotRequestedWithPublicKey() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let key = Curve25519.Signing.PrivateKey().publicKey

        let request = HTTPRequest(method: .get, path: .postOfferForSigning)
        let response = HTTPResponse<Data?>(
            httpStatusCode: .success,
            responseHeaders: [:],
            body: Data()
        )
        let verifiedResponse = response.verify(signing: Self.signing, request: request, publicKey: key)

        expect(verifiedResponse.verificationResult) == .notRequested
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func testResponseVerificationFailedIfMissingSignature() throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let key = Curve25519.Signing.PrivateKey().publicKey

        let request = HTTPRequest(method: .get, path: .getProductEntitlementMapping)
        let response = HTTPResponse<Data?>(
            httpStatusCode: .success,
            responseHeaders: [:],
            body: Data()
        )
        let verifiedResponse = response.verify(signing: Self.signing, request: request, publicKey: key)

        expect(verifiedResponse.verificationResult) == .failed
    }

    func testValueForHeaderFieldWithNonExistingField() {
        expect(HTTPResponse.create([:]).value(forHeaderField: HTTPClient.ResponseHeader.contentType)).to(beNil())
    }

    func testValueForHeaderFieldWithCaseSensitiveFieldName() {
        let header = HTTPClient.ResponseHeader.contentType
        expect(HTTPResponse.create([header.rawValue: "test"]).value(forHeaderField: header)) == "test"
    }

    func testValueForHeaderFieldIsCaseInsensitive() {
        let header = HTTPClient.ResponseHeader.contentType
        expect(HTTPResponse.create([header.rawValue.lowercased(): "test"]).value(forHeaderField: header)) == "test"
    }

    func testRequestDate() {
        let date = Date().addingTimeInterval(-100_000_000)
        let response = HTTPResponse.create([
            HTTPClient.ResponseHeader.requestDate.rawValue: String(date.millisecondsSince1970)
        ])

        expect(response.requestDate).to(beCloseTo(date, within: 0.01))
    }

    func testRequestDateParsedAsNilIfItsMissing() {
        let response = HTTPResponse.create([:])
        expect(response.requestDate).to(beNil())
    }

    func testRequestDateParsedAsNilIfItCantBeParsed() {
        let response = HTTPResponse.create([HTTPClient.ResponseHeader.requestDate.rawValue: "unknown"])
        expect(response.requestDate).to(beNil())
    }

    // MARK: -

    private static var sampleResponse: HTTPResponse<Data> {
        get throws {
            return .create(
                body: try CustomerInfo.emptyInfo.prettyPrintedData,
                headers: [
                    "X-Header": "true"
                ]
            )
        }
    }
    private static var sampleVerifiedResponse: VerifiedHTTPResponse<Data> {
        get throws {
            return .init(response: try Self.sampleResponse, verificationResult: .notRequested)
        }
    }

}

private extension HTTPResponse where Body == HTTPEmptyResponseBody {

    static func create(_ headers: HTTPResponse.Headers) -> Self {
        return .init(httpStatusCode: .success,
                     responseHeaders: headers,
                     body: .init())
    }

}

private extension HTTPResponse where Body == Data {

    static func create(body: Data, headers: HTTPResponse.Headers) -> Self {
        return .init(httpStatusCode: .success,
                     responseHeaders: headers,
                     body: body,
                     requestDate: Date())
    }

}

// MARK: - HTTPResponseBody

class HTTPResponseBodyTests: TestCase {

    func testCopyWithNewRequestDateDefaultsToSameData() {
        struct Body: Equatable, Codable, HTTPResponseBody {
            var data: String
        }

        let body = Body(data: "test")
        expect(body.copy(with: Date())) == body
    }

}

// MARK: - ErrorResponse

class ErrorResponseTests: TestCase {

    func testNormalErrorResponse() throws {
        let result = try self.decode(Self.withoutAttributeErrors)
        expect(result.code) == .invalidAuthToken
        expect(result.message) == "Invalid auth token."
        expect(result.attributeErrors).to(beEmpty())
    }

    func testNormalErrorResponseCreatesBackendError() throws {
        let error = try self.decode(Self.withoutAttributeErrors)
            .asBackendError(with: .internalServerError) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.invalidCredentialsError.rawValue
        expect(error.userInfo[ErrorDetails.attributeErrorsKey]).to(beNil())

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
        expect(underlyingError.code) == BackendErrorCode.invalidAuthToken.rawValue
    }

    func testErrorResponseWithAttributeErrors() throws {
        let result = try self.decode(Self.withAttributeErrors)
        expect(result.code) == .invalidSubscriberAttributes
        expect(result.message) == "Some subscriber attributes keys were unable to be saved."
        expect(result.attributeErrors) == [
            "$email": "Email address is not a valid email."
        ]
    }

    func testErrorResponseWithAttributeErrorsInInvalidFormat() throws {
        let result = try self.decode(Self.withAttributeErrorsInInvalidFormat)
        expect(result.code) == .invalidSubscriberAttributes
        expect(result.message) == "Some subscriber attributes keys were unable to be saved."
        expect(result.attributeErrors).to(beEmpty())
    }

    func testErrorResponseWithAttributeErrorsInContainerKey() throws {
        let result = try self.decodeSupportingContainer(Self.attributeErrorsWithContainerKey)
        expect(result.code) == .invalidSubscriberAttributes
        expect(result.message) == "Some subscriber attributes keys were unable to be saved."
        expect(result.attributeErrors) == [
            "$email": "Email address is not a valid email."
        ]
    }

    func testUnknownErrorCreatesBackendError() throws {
        let error = try self.decode(Self.unknownError)
            .asBackendError(with: .internalServerError) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.unknownBackendError.rawValue
        expect(error.userInfo[ErrorDetails.attributeErrorsKey]).to(beNil())

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
        expect(underlyingError.code) == BackendErrorCode.unknownBackendError.rawValue
    }

    func testErrorWithOnlyMessageCreatesBackendError() throws {
        let error = try self.decode(Self.onlyMessageError)
            .asBackendError(with: .notFoundError) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.unknownBackendError.rawValue
        expect(error.userInfo[ErrorDetails.attributeErrorsKey]).to(beNil())

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
        expect(underlyingError.code) == BackendErrorCode.unknownBackendError.rawValue
    }

    func testErrorWithAttributeErrorsCreatesBackendError() throws {
        let error = try self.decode(Self.withAttributeErrors)
            .asBackendError(with: .invalidRequest) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.invalidSubscriberAttributesError.rawValue
        expect(error.userInfo[ErrorDetails.attributeErrorsKey] as? [String: String]) == [
            "$email": "Email address is not a valid email."
        ]

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
        expect(underlyingError.code) == BackendErrorCode.invalidSubscriberAttributes.rawValue
    }

    func testErrorWithAttributeErrorsInContainerKeyCreatesBackendError() throws {
        let error = try self.decodeSupportingContainer(Self.attributeErrorsWithContainerKey)
            .asBackendError(with: .invalidRequest) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.invalidSubscriberAttributesError.rawValue
        expect(error.userInfo[ErrorDetails.attributeErrorsKey] as? [String: String]) == [
            "$email": "Email address is not a valid email."
        ]

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
        expect(underlyingError.code) == BackendErrorCode.invalidSubscriberAttributes.rawValue
    }

    func testUnknownResponseCreatesDefaultError() throws {
        let result = try self.decode(Self.unknownResponse)
        expect(result.code) == .unknownBackendError
        expect(result.message).to(beNil())
        expect(result.attributeErrors).to(beEmpty())

        let error = result
            .asBackendError(with: .invalidRequest) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.unknownBackendError.rawValue
        expect(error.userInfo[ErrorDetails.attributeErrorsKey]).to(beNil())

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
        expect(underlyingError.code) == BackendErrorCode.unknownBackendError.rawValue
    }

    func testErrorResponseWithOnlyMessage() throws {
        let result = try self.decode(Self.onlyMessageError)
        expect(result.code) == .unknownBackendError
        expect(result.message) == "Something is wrong but we don't know what."
        expect(result.attributeErrors).to(beEmpty())
    }

    func testErrorResponseWithUnknownErrorCode() throws {
        let result = try self.decode(Self.unknownError)

        expect(result.code) == .unknownBackendError
        expect(result.message) == "This is a future unknown error."
        expect(result.attributeErrors).to(beEmpty())
    }

    func testErrorResponseWithIntegerErrorCode() throws {
        let result = try self.decode(Self.integerCode)

        expect(result.code) == .invalidAuthToken
        expect(result.message) == "Invalid auth token."
        expect(result.attributeErrors).to(beEmpty())
    }

}

private extension ErrorResponseTests {

    static let unknownResponse = """
        {
        "This is": "A different response format"
        }
        """

    static let onlyMessageError = """
        {
        "message": "Something is wrong but we don't know what."
        }
        """

    static let withAttributeErrors = """
        {
        "attribute_errors": [
            {
                "key_name": "$email",
                "message": "Email address is not a valid email."
            }
        ],
        "code": "7263",
        "message": "Some subscriber attributes keys were unable to be saved."
        }
        """

    static let withAttributeErrorsInInvalidFormat = """
        {
        "attribute_errors": [
            {
            "invalid": "format"
            }
        ],
        "code": "7263",
        "message": "Some subscriber attributes keys were unable to be saved."
        }
        """

    static let attributeErrorsWithContainerKey = """
        {
        "attributes_error_response": {
            "attribute_errors": [
                {
                    "key_name": "$email",
                    "message": "Email address is not a valid email."
                }
            ],
            "code": "7263",
            "message": "Some subscriber attributes keys were unable to be saved."
            }
        }
        """

    static let withoutAttributeErrors = """
        {
        "code": "7224",
        "message": "Invalid auth token."
        }
        """
    static let unknownError = """
        {
        "code": "7301",
        "message": "This is a future unknown error."
        }
        """
    static let integerCode = """
        {
        "code": 7224,
        "message": "Invalid auth token."
        }
        """

}

private extension ErrorResponseTests {

    func decode(_ response: String) throws -> ErrorResponse {
        return try JSONDecoder.default.decode(ErrorResponse.self, from: response.asData)
    }

    func decodeSupportingContainer(_ response: String) throws -> ErrorResponse {
        return ErrorResponse.from(
            try JSONSerialization.jsonObject(with: response.asData) as? [String: Any] ?? [:]
        )
    }

}
