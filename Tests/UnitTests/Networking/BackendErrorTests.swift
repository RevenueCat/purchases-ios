//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendErrorTests.swift
//
//  Created by Nacho Soto on 4/7/22.

import Nimble
@testable import RevenueCat
import XCTest

class BackendErrorTests: BaseErrorTests {

    func testMissingAppUserID() {
        let error: BackendError = .missingAppUserID()

        verifyPurchasesError(error, expectedCode: .invalidAppUserIdError)
    }

    func testEmptySubscriberAttributes() {
        let error: BackendError = .emptySubscriberAttributes()

        verifyPurchasesError(error, expectedCode: .emptySubscriberAttributes)
    }

    func testMissingReceiptFile() {
        let error: BackendError = .missingReceiptFile()

        verifyPurchasesError(error, expectedCode: .missingReceiptFileError)
    }

    func testMissingTransactionProductIdentifier() {
        let error: BackendError = .missingTransactionProductIdentifier()

        verifyPurchasesError(error, expectedCode: .unknownError)
    }

    func testUnexpectedBackendResponse() {
        let underlyingError: BackendError.UnexpectedBackendResponseError = .customerInfoNil
        let error: BackendError = .unexpectedBackendResponse(underlyingError,
                                                             extraContext: "context")

        verifyPurchasesError(error,
                             expectedCode: .unexpectedBackendResponseError,
                             underlyingError: underlyingError as NSError)
    }

}
