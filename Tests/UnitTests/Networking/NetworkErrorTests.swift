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

// swiftlint:disable multiline_parameters

import Nimble
@testable import RevenueCat
import XCTest

class NetworkErrorAsPurchasesErrorTests: BaseErrorTests {

    func testDecodingError() {
        let underlyingError = NSError(domain: "domain", code: 20)
        let error: NetworkError = .decoding(underlyingError, Data())

        verifyPurchasesError(error,
                             expectedCode: .unexpectedBackendResponseError,
                             underlyingError: underlyingError,
                             localizedDescription: error.localizedDescription)
    }

    func testNetworkError() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost)
        let error: NetworkError = .networkError(underlyingError)

        verifyPurchasesError(error,
                             expectedCode: .networkError,
                             underlyingError: underlyingError,
                             localizedDescription: underlyingError.localizedDescription)
    }

    func testDnsError() {
        let url = URL(string: "https://google.com")!
        let resolvedHost = "https://google.com"

        let error: NetworkError = .dnsError(failedURL: url,
                                            resolvedHost: resolvedHost)

        verifyPurchasesError(
            error,
            expectedCode: .apiEndpointBlockedError,
            underlyingError: error,
            localizedDescription: NetworkStrings.blocked_network(url: url, newHost: resolvedHost).description
        )
    }

    func testUnableToCreateRequest() {
        let path: HTTPRequest.Path = .getCustomerInfo(appUserID: "user ID")
        let error: NetworkError = .unableToCreateRequest(path)

        verifyPurchasesError(error,
                             expectedCode: .networkError,
                             userInfoKeys: ["request_path"],
                             localizedDescription: "Could not create request to \(path.relativePath)")
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
                             expectedCode: .offlineConnectionError,
                             userInfoKeys: [],
                             localizedDescription: ErrorCode.offlineConnectionError.description)
    }

    func testErrorResponse() throws {
        let errorResponse = ErrorResponse(code: .invalidSubscriberAttributes,
                                          originalCode: BackendErrorCode.invalidSubscriberAttributes.rawValue,
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
        expect(nsError.localizedDescription) == [
            errorResponse.code.toPurchasesErrorCode().description,
            errorResponse.attributeErrors.description

        ]
            .joined(separator: " ")
    }

    func testErrorResponseWithNoAttributeErrors() throws {
        let errorResponse = ErrorResponse(code: .invalidAPIKey,
                                          originalCode: BackendErrorCode.invalidAPIKey.rawValue,
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
        expect(nsError.localizedDescription) == [
            errorResponse.code.toPurchasesErrorCode().description,
            errorResponse.message!

        ]
            .joined(separator: " ")
    }

    func testErrorResponseWithUnknownCode() throws {
        let unknownCode = 1234

        let errorResponse = ErrorResponse(code: .unknownBackendError,
                                          originalCode: unknownCode,
                                          message: "This is a future unknown error")

        let error: NetworkError = .errorResponse(errorResponse, .invalidRequest)
        let underlyingError = errorResponse.code
            .addingUserInfo([
                NSLocalizedDescriptionKey: errorResponse.message ?? ""
            ])

        verifyPurchasesError(error,
                             expectedCode: .unknownBackendError,
                             underlyingError: underlyingError,
                             userInfoKeys: [.statusCode, .backendErrorCode])

        let nsError = error.asPurchasesError as NSError

        expect(
            nsError.userInfo[NSError.UserInfoKey.backendErrorCode as String] as? Int
        ) == unknownCode
        expect(nsError.subscriberAttributesErrors).to(beNil())
        expect(nsError.localizedDescription) == [
            errorResponse.code.toPurchasesErrorCode().description,
            errorResponse.message!,
            "(\(unknownCode))"

        ]
            .joined(separator: " ")
    }

    func testErrorResponseWithNoCode() throws {
        let statusCode: HTTPStatusCode = .unauthorized
        let errorResponse = ErrorResponse(code: .unknownError,
                                          originalCode: 0,
                                          message: nil)

        let error: NetworkError = .errorResponse(errorResponse, statusCode)
        let underlyingError = errorResponse.code

        verifyPurchasesError(error,
                             expectedCode: .unknownError,
                             underlyingError: underlyingError,
                             userInfoKeys: [.statusCode])

        let nsError = error.asPurchasesError as NSError

        expect(
            nsError.userInfo[NSError.UserInfoKey.backendErrorCode as String] as? Int
        ) == BackendErrorCode.unknownError.rawValue
        expect(nsError.subscriberAttributesErrors).to(beNil())
        expect(nsError.localizedDescription) == [
            errorResponse.code.toPurchasesErrorCode().description,
            NetworkStrings.api_request_failed_status_code(statusCode).description
        ]
            .joined(separator: " ")
    }

}

class NetworkErrorTests: TestCase {

    func testSuccessfullySyncedTrue() {
        let errors = [
            error(Self.responseError(.unauthorized)),
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
            error(Self.responseError(.internalServerError)),
            error(Self.signatureVerificationFailed)
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
            error(Self.responseError(.internalServerError)),
            error(Self.signatureVerificationFailed)
        ]

        for error in errors {
            check(error.0.finishable,
                  condition: beFalse(),
                  descrition: "Expected error to not be finishable",
                  file: error.1,
                  line: error.2)
        }
    }

    func testServerDownTrue() {
        let errors = [
            error(Self.responseError(.internalServerError)),
            error(Self.responseError(.networkConnectTimeoutError))
        ]

        for error in errors {
            check(error.0.isServerDown,
                  condition: beTrue(),
                  descrition: "Expected error to be server down",
                  file: error.1,
                  line: error.2)
        }
    }

    func testServerDownFalse() {
        let errors = [
            error(Self.decodingError),
            error(Self.offlineError),
            error(Self.networkError),
            error(Self.dnsError),
            error(Self.unableToCreateRequestError),
            error(Self.unexpectedResponseError),
            error(Self.responseError(.notFoundError)),
            error(Self.responseError(.invalidRequest)),
            error(Self.signatureVerificationFailed)
        ]

        for error in errors {
            check(error.0.isServerDown,
                  condition: beFalse(),
                  descrition: "Expected error to not be server down",
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
        _ value: T, condition: Nimble.Predicate<T>, descrition: String,
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
        HTTPRequest.Path.getCustomerInfo(appUserID: "user ID")
    )

    private static let unexpectedResponseError: NetworkError = .unexpectedResponse(nil)

    private static let signatureVerificationFailed: NetworkError = .signatureVerificationFailed(
        path: HTTPRequest.Path.health,
        code: .success
    )

    private static func responseError(_ statusCode: HTTPStatusCode) -> NetworkError {
        return .errorResponse(
            ErrorResponse(code: .invalidAPIKey,
                          originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                          message: nil),
            statusCode
        )
    }
}

extension NetworkError {

    static func serverDown(
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        return .errorResponse(
            .init(code: .internalServerError, originalCode: BackendErrorCode.internalServerError.rawValue),
            .internalServerError,
            file: file,
            function: function,
            line: line
        )
    }

}
