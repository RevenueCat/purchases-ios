//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NetworkErrorTest.swift
//
//  Created by Nacho Soto on 4/7/22.

// swiftlint:disable multiline_parameters large_tuple

import Nimble
@testable import RevenueCat
import XCTest

class NetworkErrorAsPurchasesErrorTests: BaseErrorTests {

    func testDecodingError() {
        let underlyingError = NSError(domain: "domain", code: 20)
        let error: NetworkError = .decoding(underlyingError, Data())

        verifyPurchasesError(error,
                             expectedCode: .unexpectedBackendResponseError,
                             underlyingError: underlyingError)
    }

    func testNetworkError() {
        let underlyingError = NSError(domain: "domain", code: 20)
        let error: NetworkError = .networkError(underlyingError)

        verifyPurchasesError(error,
                             expectedCode: .networkError,
                             underlyingError: underlyingError)
    }

    func testDnsError() {
        let error: NetworkError = .dnsError(failedURL: URL(string: "https://google.com")!,
                                            resolvedHost: "https://google.com")

        verifyPurchasesError(error,
                             expectedCode: .apiEndpointBlockedError,
                             underlyingError: error)
    }

    func testUnableToCreateRequest() {
        let error: NetworkError = .unableToCreateRequest(.getCustomerInfo(appUserID: "user ID"))

        verifyPurchasesError(error,
                             expectedCode: .networkError,
                             userInfoKeys: ["request_url"])
    }

    func testUnexpectedResponse() {
        let error: NetworkError = .unexpectedResponse(nil)

        verifyPurchasesError(error,
                             expectedCode: .unexpectedBackendResponseError,
                             userInfoKeys: ["response"])
    }

    func testOfflineConnection() {
        let error: NetworkError = .offlineConnection()

        verifyPurchasesError(error,
                             expectedCode: .offlineConnectionError)
    }

    func testErrorResponse() throws {
        let errorResponse = ErrorResponse(code: .invalidSubscriberAttributes,
                                          message: "Invalid Attributes",
                                          attributeErrors: [
                                            "$email": "invalid"
                                          ])

        let error: NetworkError = .errorResponse(errorResponse, .invalidRequest)
        let underlyingError = errorResponse.code
            .addingUserInfo([
                NSLocalizedDescriptionKey: errorResponse.message ?? ""
            ])

        verifyPurchasesError(error,
                             expectedCode: .invalidSubscriberAttributesError,
                             underlyingError: underlyingError,
                             userInfoKeys: [.attributeErrors,
                                            .statusCode])

        let nsError = error.asPurchasesError as NSError

        expect(nsError.subscriberAttributesErrors) == errorResponse.attributeErrors
        expect(nsError.localizedDescription) == errorResponse.attributeErrors.description
    }

    func testErrorResponseWithNoAttributeErrors() throws {
        let errorResponse = ErrorResponse(code: .invalidAPIKey,
                                          message: "Invalid API key",
                                          attributeErrors: [:])

        let error: NetworkError = .errorResponse(errorResponse, .invalidRequest)
        let underlyingError = errorResponse.code
            .addingUserInfo([
                NSLocalizedDescriptionKey: errorResponse.message ?? ""
            ])

        verifyPurchasesError(error,
                             expectedCode: .invalidCredentialsError,
                             underlyingError: underlyingError,
                             userInfoKeys: [.statusCode])

        let nsError = error.asPurchasesError as NSError

        expect(nsError.subscriberAttributesErrors).to(beNil())
        expect(nsError.localizedDescription) == errorResponse.code.toPurchasesErrorCode().description
    }

}

class NetworkErrorTests: TestCase {

    func testSuccessfullySyncedTrue() {
        let errors = [
            error(Self.responseError(.invalidRequest)),
            error(Self.responseError(.notModified)),
            error(Self.responseError(.success))
        ]

        for error in errors {
            check(error.0.successfullySynced,
                  condition: beTrue(),
                  descrition: "Expected error to be successfully synced",
                  file: error.1,
                  line: error.2)
        }
    }

    func testSuccessfullySyncedFalse() {
        let errors = [
            error(Self.decodingError),
            error(Self.offlineError),
            error(Self.networkError),
            error(Self.dnsError),
            error(Self.unableToCreateRequestError),
            error(Self.unexpectedResponseError),
            error(Self.responseError(.notFoundError)),
            error(Self.responseError(.internalServerError))
        ]

        for error in errors {
            check(error.0.successfullySynced,
                  condition: beFalse(),
                  descrition: "Expected error to be not successfully synced",
                  file: error.1,
                  line: error.2)
        }
    }

    func testFinishableTrue() {
        let errors = [
            error(Self.responseError(.invalidRequest)),
            error(Self.responseError(.notFoundError)),
            error(Self.responseError(.notModified)),
            error(Self.responseError(.success))
        ]

        for error in errors {
            check(error.0.finishable,
                  condition: beTrue(),
                  descrition: "Expected error to be finishable",
                  file: error.1,
                  line: error.2)
        }
    }

    func testFinishableFalse() {
        let errors = [
            error(Self.decodingError),
            error(Self.offlineError),
            error(Self.networkError),
            error(Self.dnsError),
            error(Self.unableToCreateRequestError),
            error(Self.unexpectedResponseError),
            error(Self.responseError(.internalServerError))
        ]

        for error in errors {
            check(error.0.finishable,
                  condition: beFalse(),
                  descrition: "Expected error to not be finishable",
                  file: error.1,
                  line: error.2)
        }
    }

    // MARK: - Helpers

    /// Stores the file/line information so expectation failures can point to the line creating the error.
    private func error(
        _ error: NetworkError,
        file: FileString = #file, line: UInt = #line
    ) -> (NetworkError, FileString, UInt) {
        return (error, file, line)
    }

    private func check<T>(
        _ value: T, condition: Predicate<T>, descrition: String,
        file: FileString = #file, line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            value
        ).to(
            condition,
            description: descrition
        )
    }

    private static let offlineError: NetworkError = .offlineConnection()
    private static let decodingError: NetworkError = .decoding(NSError(domain: "domain", code: 20), Data())
    private static let networkError: NetworkError = .networkError(NSError(domain: "domain", code: 30))
    private static let dnsError: NetworkError = .dnsError(failedURL: URL(string: "https://google.com")!,
                                                          resolvedHost: "https://google.com")
    private static let unableToCreateRequestError: NetworkError = .unableToCreateRequest(
        .getCustomerInfo(appUserID: "user ID")
    )

    private static let unexpectedResponseError: NetworkError = .unexpectedResponse(nil)

    private static func responseError(_ statusCode: HTTPStatusCode) -> NetworkError {
        return .errorResponse(
            ErrorResponse(code: .invalidAPIKey,
                          message: nil),
            statusCode
        )
    }
}
