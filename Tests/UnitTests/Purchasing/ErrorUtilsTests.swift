//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorUtilsTests.swift
//
//  Created by Nacho Soto on 7/28/22.

import Nimble
import XCTest

@testable import RevenueCat

import StoreKit

class ErrorUtilsTests: TestCase {

    private var originalLogHandler: VerboseLogHandler!
    private var loggedMessages: [(level: LogLevel, message: String)] = []

    override func setUp() {
        super.setUp()

        self.originalLogHandler = Logger.logHandler
        Logger.logHandler = { [weak self] level, message, _, _, _ in
            self?.loggedMessages.append((level, message))
        }
    }

    override func tearDown() {
        Logger.logHandler = self.originalLogHandler

        super.tearDown()
    }

    func testPurchaseErrorsAreLoggedAsApppleErrors() {
        let underlyingError = NSError(domain: SKErrorDomain, code: SKError.Code.paymentInvalid.rawValue)
        let error = ErrorUtils.purchaseNotAllowedError(error: underlyingError)

        self.expectLoggedError(error, .appleError)
    }

    func testNetworkErrorsAreLogged() {
        let error = ErrorUtils.networkError(message: Strings.network.could_not_find_cached_response.description)

        self.expectLoggedError(error, .rcError, .networkError)
    }

    func testLoggedErrorsWithNoMessage() throws {
        let error = ErrorUtils.customerInfoError()

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == "\(LogIntent.rcError.prefix) \(error.localizedDescription)"
    }

    func testLoggedErrorsWithMessageIncludeErrorDescriptionAndMessage() throws {
        let message = Strings.customerInfo.no_cached_customerinfo.description
        _ = ErrorUtils.customerInfoError(withMessage: message)

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == [
            LogIntent.rcError.prefix,
            ErrorCode.customerInfoError.description,
            message
        ].joined(separator: " ")
    }

    func testLoggedErrorsDontDuplicateMessageIfEqualToErrorDescription() throws {
        _ = ErrorUtils.customerInfoError(withMessage: ErrorCode.customerInfoError.description)

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == [
            LogIntent.rcError.prefix,
            ErrorCode.customerInfoError.description
        ].joined(separator: " ")
    }

    func testLoggedErrorResponseWithAttributeErrors() throws {
        let errorResponse = ErrorResponse(code: .invalidSubscriberAttributes,
                                          message: "Invalid Attributes",
                                          attributeErrors: [
                                            "$email": "invalid"
                                          ])

        let error: NetworkError = .errorResponse(errorResponse, .invalidRequest)
        _ = error.asPurchasesError

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == [
            LogIntent.rcError.prefix,
            errorResponse.code.toPurchasesErrorCode().description,
            errorResponse.attributeErrors.description
        ]
            .joined(separator: " ")
    }

    func testLoggedErrorResponseWithNoAttributeErrors() throws {
        let errorResponse = ErrorResponse(code: .invalidAPIKey,
                                          message: "Invalid API key",
                                          attributeErrors: [:])

        let error: NetworkError = .errorResponse(errorResponse, .invalidRequest)
        _ = error.asPurchasesError

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == [
            LogIntent.rcError.prefix,
            errorResponse.code.toPurchasesErrorCode().description
        ]
            .joined(separator: " ")
    }

    // MARK: -

    private func expectLoggedError(
        _ error: Error,
        _ intent: LogIntent,
        _ code: ErrorCode? = nil,
        file: FileString = #fileID,
        line: UInt = #line
    ) {
        let expectedMessage = [
            intent.prefix,
            code?.description,
            error.localizedDescription
        ]
            .compactMap { $0 }
            .joined(separator: " ")

        expect(
            file: file,
            line: line,
            self.loggedMessages
        ).to(
            containElementSatisfying { level, message in
                level == .error && message == expectedMessage
            },
            description: "Error '\(expectedMessage)' not found. Logged messages: \(self.loggedMessages)"
        )
    }

}
