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

import Nimble
import XCTest

@testable import RevenueCat

class ErrorResponseTests: XCTestCase {

    func testNormalErrorResponse() throws {
        let result = try self.decode(Self.withoutAttributeErrors)
        expect(result.code) == .invalidAuthToken
        expect(result.message) == "Invalid auth token."
        expect(result.attributeErrors).to(beEmpty())
    }

    func testNormalErrorResponseCreatesBackendError() throws {
        let error = try self.decode(Self.withoutAttributeErrors)
            .asBackendError(withStatusCode: .internalServerError) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.invalidCredentialsError.rawValue
        expect(error.userInfo[ErrorDetails.finishableKey as String] as? Bool) == false
        expect(error.userInfo[Backend.RCAttributeErrorsKey] as? [String: String]).to(beEmpty())

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

    func testErrorWithAttributeErrorsCreatesBackendError() throws {
        let error = try self.decode(Self.withAttributeErrors)
            .asBackendError(withStatusCode: .invalidRequest) as NSError

        expect(error.domain) == ErrorCode.errorDomain
        expect(error.code) == ErrorCode.invalidSubscriberAttributesError.rawValue
        expect(error.userInfo[ErrorDetails.finishableKey as String] as? Bool) == true
        expect(error.userInfo[Backend.RCAttributeErrorsKey] as? [String: String]) == [
            "$email": "Email address is not a valid email."
        ]

        let underlyingError = try XCTUnwrap(error.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.BackendErrorCode"
        expect(underlyingError.code) == BackendErrorCode.invalidSubscriberAttributes.rawValue

    }

    func testErrorResponseWithUnknownErrorCode() throws {
        let result = try self.decode(Self.unknownError)

        expect(result.code) == .unknownBackendError
        expect(result.message) == "This is a future unknown errors."
        expect(result.attributeErrors).to(beEmpty())
    }

}

private extension ErrorResponseTests {
    static let withAttributeErrors = """
        {
        "attribute_errors": [
        {
            "key_name": "$email",
            "message": "Email address is not a valid email."
        }
        ],
        "code": 7263,
        "message": "Some subscriber attributes keys were unable to be saved."
        }
        """

    static let withoutAttributeErrors = """
        {
        "code": 7224,
        "message": "Invalid auth token."
        }
        """
    static let unknownError = """
        {
        "code": 7301,
        "message": "This is a future unknown errors."
        }
        """
}

private extension ErrorResponseTests {

    enum Error: Swift.Error {

        case unableToEncodeString

    }

    func decode(_ response: String) throws -> ErrorResponse {
        guard let data = response.data(using: .utf8) else {
            throw Error.unableToEncodeString
        }

        return try HTTPClient.jsonDecoder.decode(ErrorResponse.self, from: data)
    }

}
