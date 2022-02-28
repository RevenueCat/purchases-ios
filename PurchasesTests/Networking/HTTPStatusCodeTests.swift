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

}
