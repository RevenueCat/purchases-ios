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

    func testReceiptErrorWithNoURL() {
        let error = ErrorUtils.missingReceiptFileError(nil)
        expect(error).to(matchError(ErrorCode.missingReceiptFileError))
        expect(error.userInfo["rc_receipt_url"] as? String) == "<null>"
        expect(error.userInfo["rc_receipt_file_exists"] as? Bool) == false
    }

    func testReceiptErrorWithMissingReceipt() {
        let url = URL(string: "file://does_not_exist")!

        let error = ErrorUtils.missingReceiptFileError(url)
        expect(error).to(matchError(ErrorCode.missingReceiptFileError))
        expect(error.userInfo["rc_receipt_url"] as? String) == url.absoluteString
        expect(error.userInfo["rc_receipt_file_exists"] as? Bool) == false
    }

    func testReceiptErrorWithEmptyReceipt() {
        let url = Self.createEmptyFile()

        let error = ErrorUtils.missingReceiptFileError(url)
        expect(error).to(matchError(ErrorCode.missingReceiptFileError))
        expect(error.userInfo["rc_receipt_url"] as? String) == url.absoluteString
        expect(error.userInfo["rc_receipt_file_exists"] as? Bool) == true
    }

    func testPublicErrorsCanBeConvertedToErrorCode() throws {
        let error = ErrorUtils.customerInfoError().asPublicError
        let errorCode = try XCTUnwrap(error as? ErrorCode, "Error couldn't be converted to ErrorCode")

        expect(errorCode).to(matchError(error as Error))
    }

    func testPublicErrorsCanBeCaughtAsErrorCode() throws {
        func throwing() throws {
            throw ErrorUtils.customerInfoError().asPublicError
        }

        do {
            try throwing()
            fail("Expected error")
        } catch let error as ErrorCode {
            expect(error).to(matchError(ErrorCode.customerInfoError))
        } catch let error {
            fail("Invalid error: \(error)")
        }
    }

    func testPublicErrorsContainUnderlyingError() throws {
        let underlyingError = ErrorUtils.offlineConnectionError().asPublicError

        func throwing() throws {
            throw ErrorUtils.customerInfoError(error: underlyingError).asPublicError
        }

        do {
            try throwing()
            fail("Expected error")
        } catch let error as NSError {
            expect(error).to(matchError(ErrorCode.customerInfoError))
            expect(error.userInfo[NSUnderlyingErrorKey] as? NSError) == underlyingError
        }
    }

    func testPurchasesErrorWithUntypedErrorCode() throws {
        let error: ErrorCode = .apiEndpointBlockedError

        expect(ErrorUtils.purchasesError(withUntypedError: error)).to(matchError(error))
    }

    func testPurchasesErrorWithUntypedPublicError() throws {
        let error: PublicError = ErrorUtils.configurationError().asPublicError
        let purchasesError = ErrorUtils.purchasesError(withUntypedError: error)
        let userInfo = try XCTUnwrap(purchasesError.userInfo as? [String: String])

        expect(error).to(matchError(purchasesError))
        expect(userInfo) == error.userInfo as? [String: String]
    }

    func testPurchasesErrorWithUntypedPurchasesError() throws {
        let error = ErrorUtils.offlineConnectionError()

        expect(ErrorUtils.purchasesError(withUntypedError: error)).to(matchError(error))
    }

    func testPurchasesErrorWithUntypedBackendError() throws {
        let error: BackendError = .missingAppUserID()
        let expected = error.asPurchasesError

        expect(ErrorUtils.purchasesError(withUntypedError: error)).to(matchError(expected))
    }

    func testPublicErrorFromUntypedBackendError() throws {
        let error: BackendError = .missingAppUserID()
        let expected = error.asPublicError

        expect(ErrorUtils.purchasesError(withUntypedError: error).asPublicError)
            .to(matchError(expected))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchasesErrorWithPurchasesErrorStoreKitError() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let error = BackendError.missingAppUserID().asPurchasesError

        expect(ErrorUtils.purchasesError(withStoreKitError: error))
            .to(matchError(error))
    }

    func testPurchasesErrorWithPurchasesErrorSKError() {
        let error = BackendError.missingAppUserID().asPurchasesError

        expect(ErrorUtils.purchasesError(withSKError: error))
            .to(matchError(error))
    }

    func testPurchasesErrorWithNetworkErrorAsSKError() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let expectedError = ErrorUtils.offlineConnectionError()

        expect(ErrorUtils.purchasesError(withSKError: error))
            .to(matchError(expectedError))
    }

    func testPurchaseErrorsAreLoggedAsApppleErrors() {
        let underlyingError = NSError(domain: SKErrorDomain, code: SKError.Code.paymentInvalid.rawValue)
        let error = ErrorUtils.purchaseNotAllowedError(error: underlyingError)

        self.expectLoggedError(error, .appleError)
    }

    func testNetworkErrorsAreLogged() {
        let error = ErrorUtils.networkError(message: Strings.network.json_data_received(dataString: "test").description)

        self.expectLoggedError(error, .rcError)
    }

    func testNetworkErrorsLogUnderlyingError() throws {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorDNSLookupFailed)
        let networkError = ErrorUtils.networkError(withUnderlyingError: underlyingError)

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == [
            LogIntent.rcError.prefix,
            networkError.error.description,
            underlyingError.localizedDescription
        ]
            .joined(separator: " ")
    }

    func testLoggedErrorsWithNoMessage() throws {
        let error = ErrorUtils.customerInfoError()

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == "\(LogIntent.rcError.prefix) \(error.localizedDescription)"
    }

    func testNetworkErrorsAreLoggedWithUnderlyingError() throws {
        let originalErrorCode = 6000

        let response = ErrorResponse(code: .unknownBackendError,
                                     originalCode: originalErrorCode,
                                     message: "Page not found",
                                     attributeErrors: [:])
        let purchasesError = response.asBackendError(with: .notFoundError)

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == [
            LogIntent.rcError.prefix,
            purchasesError.error.description,
            response.message!,
            "(\(originalErrorCode))"
        ].joined(separator: " ")
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
                                          originalCode: BackendErrorCode.invalidSubscriberAttributes.rawValue,
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
                                          originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                                          message: "Invalid API key",
                                          attributeErrors: [:])

        let error: NetworkError = .errorResponse(errorResponse, .invalidRequest)
        _ = error.asPurchasesError

        let loggedMessage = try XCTUnwrap(self.loggedMessages.onlyElement)

        expect(loggedMessage.level) == .error
        expect(loggedMessage.message) == [
            LogIntent.rcError.prefix,
            errorResponse.code.toPurchasesErrorCode().description,
            errorResponse.message!
        ]
            .joined(separator: " ")
    }

    // MARK: -

    private var loggedMessages: [TestLogHandler.MessageData] {
        return self.logger.messages
    }

    private func expectLoggedError(
        _ error: Error,
        _ intent: LogIntent,
        file: FileString = #fileID,
        line: UInt = #line
    ) {
        let expectedMessage = [
            intent.prefix,
            error.localizedDescription
        ]
            .compactMap { $0 }
            .joined(separator: " ")

        let messages = self.loggedMessages

        expect(
            file: file,
            line: line,
            messages
        ).to(
            containElementSatisfying { level, message in
                level == .error && message == expectedMessage
            },
            description: "Error '\(expectedMessage)' not found. Logged messages: \(messages)"
        )
    }

}

private extension ErrorUtilsTests {

    static func createEmptyFile() -> URL {
        let fileManager = FileManager.default
        let url = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        expect(fileManager.createFile(atPath: url.path, contents: nil, attributes: nil))
            .to(
                beTrue(),
                description: "Failed creating file"
            )

        return url
    }

}
