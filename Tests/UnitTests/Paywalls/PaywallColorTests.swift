//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallColorTests.swift
//
//  Created by Nacho Soto on 7/14/23.

#if canImport(UIKit) && canImport(SwiftUI)

import Nimble
@testable import RevenueCat
import SwiftUI
import UIKit

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
final class PaywallColorTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()
    }

    func testCreateWithEmptyStringThrows() {
        expect(try PaywallColor(stringRepresentation: "")).to(throwError())
    }

    func testCreateWithInvalidStringsThrows() {
        expect(try PaywallColor(stringRepresentation: "#")).to(throwError())
        expect(try PaywallColor(stringRepresentation: "AAAAAA")).to(throwError())
        expect(try PaywallColor(stringRepresentation: "#FFFF")).to(throwError())
        expect(try PaywallColor(stringRepresentation: "FFFFFFFF")).to(throwError())
    }

    func testCreateWithRGB() throws {
        try PaywallColor(stringRepresentation: "#FF0000")
            .verifyComponents(255, 0, 0, 255)

        try PaywallColor(stringRepresentation: "#AABBCC")
            .verifyComponents(170, 187, 204, 255)
    }

    func testCreateWithRGBA() throws {
        try PaywallColor(stringRepresentation: "#FF0000FF")
            .verifyComponents(255, 0, 0, 255)
        try PaywallColor(stringRepresentation: "#AABBCC22")
            .verifyComponents(170, 187, 204, 34)
    }

    func testCodable() throws {
        try PaywallColor(stringRepresentation: "#FF0000").verifyCodable()
        try PaywallColor(stringRepresentation: "#FF0000FF").verifyCodable()
        try PaywallColor(stringRepresentation: "#AABBCC22").verifyCodable()
    }

    func testDecodingParsesColor() throws {
        try JSONDecoder.default.decode(PaywallColor.self, jsonData: "\"#AABBCC22\"".asData)
            .verifyComponents(170, 187, 204, 34)
    }

    func testDecodingInvalidColorThrows() throws {
        expect(try JSONDecoder.default.decode(PaywallColor.self, jsonData: "\"ABBCC22\"".asData)).to(throwError())
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    func testOpaqueColorAsPaywallColor() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let color = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1).asPaywallColor
        let expected = try PaywallColor(stringRepresentation: "#FF0000")

        expect(color) == expected
        color.verifyComponents(255, 0, 0, 255)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    func testTranslucentColorAsPaywallColor() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let color = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 0.4).asPaywallColor
        let expected = try PaywallColor(stringRepresentation: "#FF000066")

        expect(color) == expected
        color.verifyComponents(255, 0, 0, 102)
    }

}

// MARK: -

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private extension PaywallColor {

    func verifyCodable(
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        expect(
            file: file,
            line: line,
            try self.encodeAndDecode()
        ) == self
    }

    func verifyComponents(
        _ red: Int,
        _ green: Int,
        _ blue: Int,
        _ alpha: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let components = self.underlyingColor.rgba

        expect(
            file: file,
            line: line,
            components
        ) == (red, green, blue, alpha)
    }

}

#endif
