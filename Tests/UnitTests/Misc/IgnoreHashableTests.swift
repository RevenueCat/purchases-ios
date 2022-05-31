//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IgnoreHashableTests.swift
//
//  Created by Nacho Soto on 5/24/22.

import Nimble
import XCTest

@testable import RevenueCat

class IgnoreHashableTests: TestCase {

    func testEqualityIgnoresValue() throws {
        expect(Self.data1) == Self.data1
        expect(Self.data1) != Self.data2
        expect(Self.data1) == Self.data3
    }

    func testHashIgnoresValue() throws {
        expect(Self.data1.hashValue) == Self.data1.hashValue
        expect(Self.data1.hashValue) != Self.data2.hashValue
        expect(Self.data1.hashValue) == Self.data3.hashValue
    }

    func testValueIsEncoded() throws {
        let reEncodedData = try Self.data1.encodeAndDecode()

        expect(reEncodedData) == Self.data1
        expect(reEncodedData.string2) == Self.data1.string2
    }

}

private extension IgnoreHashableTests {

    struct Data: Codable, Hashable {
        var string1: String
        @IgnoreHashable var string2: String

        init(_ string1: String, _ string2: String) {
            self.string1 = string1
            self.string2 = string2
        }
    }

    static let data1: Data = .init("a", "1")
    static let data2: Data = .init("b", "2")
    static let data3: Data = .init("a", "3")

}
