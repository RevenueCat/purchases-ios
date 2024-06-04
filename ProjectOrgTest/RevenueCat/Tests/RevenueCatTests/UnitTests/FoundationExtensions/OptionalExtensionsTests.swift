//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OptionalExtensionsTests.swift
//
//  Created by Nacho Soto on 1/10/23.

import Nimble
import XCTest

@testable import RevenueCat

class OptionalExtensionsTests: TestCase {

    func testNotEmptyStringWithValue() {
        expect("test".notEmpty) == "test"
        expect(" ".notEmpty) == " "
    }

    func testNotEmptyStringWithEmptyStringReturnsNil() {
        expect("".notEmpty).to(beNil())
    }

    func testOrThrowWithValue() throws {
        expect(try Optional("").orThrow(Error.error1)) == ""
    }

    func testOrThrowWithNoValue() throws {
        let value: String? = nil

        do {
            _ = try value.orThrow(Error.error1)
            fail("Expected error")
        } catch {
            expect(error).to(matchError(Error.error1))
        }
    }

}

private extension OptionalExtensionsTests {

    enum Error: Swift.Error {
        case error1
    }

}
