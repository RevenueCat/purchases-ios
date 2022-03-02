//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPStatusCodeTests.swift
//
//  Created by Nacho Soto on 2/28/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class HTTPStatusCodeTests: XCTestCase {

    func testCreatingAnUnknownCode() {
        let code = 205
        let status = HTTPStatusCode(rawValue: code)

        expect(status) == .other(code)
        expect(status.rawValue) == code
    }

    func testKnownCodeIsDetected() {
        let code = 404
        let status = HTTPStatusCode(rawValue: code)

        expect(status) == .notFoundError
        expect(status.rawValue) == code
    }

    func testIsValidResponse() {
        expect(HTTPStatusCode.success.isValidResponse) == true
        expect(HTTPStatusCode.createdSuccess.isValidResponse) == true
        expect(status(100).isServerError) == false
        expect(status(202).isValidResponse) == true
        expect(status(226).isValidResponse) == true
        expect(status(299).isValidResponse) == true
    }

    func testIsNotValidResponse() {
        expect(HTTPStatusCode.redirect.isValidResponse) == false
        expect(HTTPStatusCode.notModified.isValidResponse) == false
        expect(HTTPStatusCode.invalidRequest.isValidResponse) == false
        expect(HTTPStatusCode.notFoundError.isValidResponse) == false
        expect(HTTPStatusCode.internalServerError.isValidResponse) == false
        expect(HTTPStatusCode.networkConnectTimeoutError.isValidResponse) == false
        expect(status(418).isValidResponse) == false
    }

    func testIsServerError() {
        expect(HTTPStatusCode.internalServerError.isServerError) == true
        expect(HTTPStatusCode.networkConnectTimeoutError.isServerError) == true
    }

    func testIsNotServerError() {
        expect(HTTPStatusCode.success.isServerError) == false
        expect(HTTPStatusCode.createdSuccess.isServerError) == false
        expect(HTTPStatusCode.redirect.isServerError) == false
        expect(HTTPStatusCode.notModified.isServerError) == false
        expect(HTTPStatusCode.invalidRequest.isServerError) == false
        expect(HTTPStatusCode.notFoundError.isServerError) == false
        expect(status(100).isServerError) == false
        expect(status(202).isServerError) == false
        expect(status(226).isServerError) == false
        expect(status(299).isServerError) == false
    }

}

private func status(_ code: Int) -> HTTPStatusCode {
    return .init(rawValue: code)
}
