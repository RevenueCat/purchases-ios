//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyCodingKeyTests.swift
//
//  Created by RevenueCat on 8/12/26.

import Nimble
import XCTest

@testable import RevenueCat

class AnyCodingKeyTests: TestCase {

    func testInitWithStringValue() {
        let key = AnyCodingKey(stringValue: "someKey")

        expect(key.stringValue) == "someKey"
        expect(key.intValue).to(beNil())
    }

    func testInitWithStringValueThatIsNumericParsesIntValue() {
        let key = AnyCodingKey(stringValue: "42")

        expect(key.stringValue) == "42"
        expect(key.intValue) == 42
    }

    func testInitWithIntValue() {
        let key = AnyCodingKey(intValue: 7)

        expect(key.stringValue) == "7"
        expect(key.intValue) == 7
    }

    func testInitWithNegativeIntValue() {
        let key = AnyCodingKey(intValue: -3)

        expect(key.stringValue) == "-3"
        expect(key.intValue) == -3
    }

    func testInitFromOtherCodingKeyPreservesStringAndIntValues() throws {
        let other = OtherCodingKey(stringValue: "someKey")
        let key = try XCTUnwrap(AnyCodingKey(codingKey: other))

        expect(key.stringValue) == other.stringValue
        expect(key.intValue).to(beNil())
        expect(other.intValue).to(beNil())
    }

    func testCodingKeyPropertyReturnsSelf() {
        let key = AnyCodingKey(stringValue: "someKey")

        expect(key.codingKey.stringValue) == key.stringValue
    }

    func testExpressibleByStringLiteral() {
        let key: AnyCodingKey = "someKey"

        expect(key.stringValue) == "someKey"
    }

    func testExpressibleByIntegerLiteral() {
        let key: AnyCodingKey = 99

        expect(key.stringValue) == "99"
        expect(key.intValue) == 99
    }

}

private struct OtherCodingKey: CodingKey {

    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

}
