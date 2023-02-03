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

class HTTPStatusCodeTests: TestCase {

    func testInitializeFromInteger() {
        func method(_ status: HTTPStatusCode) {
            expect(status) == .internalServerError
        }

        method(500)
    }

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

    func testIsSuccessfulResponse() {
        expect(HTTPStatusCode.success.isSuccessfulResponse) == true
        expect(HTTPStatusCode.createdSuccess.isSuccessfulResponse) == true
        expect(status(202).isSuccessfulResponse) == true
        expect(status(226).isSuccessfulResponse) == true
        expect(status(299).isSuccessfulResponse) == true
    }

    func testIsNotValidResponse() {
        expect(HTTPStatusCode.redirect.isSuccessfulResponse) == false
        expect(HTTPStatusCode.notModified.isSuccessfulResponse) == false
        expect(HTTPStatusCode.invalidRequest.isSuccessfulResponse) == false
        expect(HTTPStatusCode.notFoundError.isSuccessfulResponse) == false
        expect(HTTPStatusCode.internalServerError.isSuccessfulResponse) == false
        expect(HTTPStatusCode.networkConnectTimeoutError.isSuccessfulResponse) == false
        expect(status(100).isSuccessfulResponse) == false
        expect(status(418).isSuccessfulResponse) == false
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
        expect(status(600).isServerError) == false
    }

    func testIsSuccessfullySynced() {
        expect(HTTPStatusCode.success.isSuccessfullySynced) == true
        expect(HTTPStatusCode.createdSuccess.isSuccessfullySynced) == true
        expect(HTTPStatusCode.redirect.isSuccessfullySynced) == true
        expect(HTTPStatusCode.notModified.isSuccessfullySynced) == true
        expect(HTTPStatusCode.invalidRequest.isSuccessfullySynced) == true
        expect(status(100).isSuccessfullySynced) == true
        expect(status(202).isSuccessfullySynced) == true
        expect(status(226).isSuccessfullySynced) == true
        expect(status(299).isSuccessfullySynced) == true
    }

    func testIsNotSuccessfullySynced() {
        expect(HTTPStatusCode.internalServerError.isSuccessfullySynced) == false
        expect(HTTPStatusCode.networkConnectTimeoutError.isSuccessfullySynced) == false
        expect(HTTPStatusCode.notFoundError.isSuccessfullySynced) == false
    }

}

private func status(_ code: Int) -> HTTPStatusCode {
    return .init(rawValue: code)
}
