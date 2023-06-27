//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntegerExtensionsTests.swift
//
//  Created by Nacho Soto on 6/26/23.

import Nimble
import XCTest

@testable import RevenueCat

class IntegerExtensionsTests: TestCase {

    func testParseUInt32Data() {
        expect(UInt32(littleEndian32Bits: Data([0x00, 0x00, 0x00, 0x00]))) == 0
        expect(UInt32(littleEndian32Bits: Data([0x01, 0x00, 0x00, 0x00]))) == 1
        expect(UInt32(littleEndian32Bits: Data([0xff, 0x00, 0x00, 0x00]))) == 255
        expect(UInt32(littleEndian32Bits: Data([0xff, 0xff, 0xff, 0xff]))) == UInt32(2 ^^ 32 - 1)
    }

    func testUInt32ToData() {
        expect(UInt32(0).littleEndianData) == Data([0x00, 0x00, 0x00, 0x00])
        expect(UInt32(1).littleEndianData) == Data([0x01, 0x00, 0x00, 0x00])
        expect(UInt32(255).littleEndianData) == Data([0xff, 0x00, 0x00, 0x00])
        expect(UInt32(2 ^^ 32 - 1).littleEndianData) == Data([0xff, 0xff, 0xff, 0xff])
    }

    func testUInt32BidirectionalConversion() {
        expect(UInt32(0).encodeAndDecode()) == 0
        expect(UInt32(1).encodeAndDecode()) == 1
        expect(UInt32(255).encodeAndDecode()) == 255
        expect(UInt32(2 ^^ 32 - 1).encodeAndDecode()) == UInt32(2 ^^ 32 - 1)
    }

}

private extension UInt32 {

    func encodeAndDecode() -> Self {
        return UInt32(littleEndian32Bits: self.littleEndianData)
    }

}

// MARK: -

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence

/// Returns `radis` raised to `power`.
private func ^^ (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}
