//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWebViewValueTests.swift

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallWebViewValueTests: TestCase {

    // MARK: - JSON-object conversion

    func testValueConvertsJSONTypes() {
        XCTAssertEqual(PaywallWebViewValue(jsonObject: "hi"), .string("hi"))
        XCTAssertEqual(PaywallWebViewValue(jsonObject: 42 as NSNumber)?.numberValue, 42)
        XCTAssertEqual(PaywallWebViewValue(jsonObject: true as NSNumber), .bool(true))
        XCTAssertEqual(PaywallWebViewValue(jsonObject: NSNull()), .null)
        XCTAssertEqual(
            PaywallWebViewValue(jsonObject: ["a", "b"]),
            .array([.string("a"), .string("b")])
        )
        XCTAssertEqual(
            PaywallWebViewValue(jsonObject: ["k": "v"]),
            .object(["k": .string("v")])
        )
    }

    func testValueDisambiguatesBoolFromNumber() {
        let boolValue = PaywallWebViewValue(jsonObject: true as NSNumber)
        XCTAssertEqual(boolValue?.boolValue, true)
        XCTAssertNil(boolValue?.numberValue)

        let numberValue = PaywallWebViewValue(jsonObject: 1 as NSNumber)
        XCTAssertEqual(numberValue?.numberValue, 1)
        XCTAssertNil(numberValue?.boolValue)
    }

    func testValueRejectsNonJSON() {
        XCTAssertNil(PaywallWebViewValue(jsonObject: Date()))
        XCTAssertNil(PaywallWebViewValue(jsonObject: ["ok", Date()]))
    }

    // MARK: - Accessors, round-trip, depth, hashing

    func testValueAccessorsReturnNilForMismatchedTypes() {
        XCTAssertNil(PaywallWebViewValue.string("x").numberValue)
        XCTAssertNil(PaywallWebViewValue.string("x").boolValue)
        XCTAssertNil(PaywallWebViewValue.number(1).stringValue)
        XCTAssertNil(PaywallWebViewValue.bool(true).numberValue)
        XCTAssertNil(PaywallWebViewValue.string("x").arrayValue)
        XCTAssertNil(PaywallWebViewValue.string("x").objectValue)
        XCTAssertFalse(PaywallWebViewValue.string("x").isNull)
        XCTAssertTrue(PaywallWebViewValue.null.isNull)
    }

    func testValueNullBridgesToNSNull() {
        XCTAssertTrue(PaywallWebViewValue.null.jsonObject is NSNull)
    }

    func testValueRoundTripsThroughJSONSerialization() throws {
        let original: PaywallWebViewValue = .object([
            "s": .string("hello"),
            "n": .number(42),
            "b": .bool(true),
            "null": .null,
            "arr": .array([.number(1), .object(["deep": .string("v")])])
        ])

        let data = try JSONSerialization.data(withJSONObject: original.jsonObject)
        let decoded = try XCTUnwrap(PaywallWebViewValue(jsonObject: JSONSerialization.jsonObject(with: data)))

        XCTAssertEqual(decoded, original)
    }

    func testValueConvertsNestedContainers() {
        let value = PaywallWebViewValue(jsonObject: [
            "list": [["k": 1], ["k": 2]]
        ])

        XCTAssertEqual(value, .object([
            "list": .array([.object(["k": .number(1)]), .object(["k": .number(2)])])
        ]))
    }

    func testValueConvertsAtMaxDepth() {
        XCTAssertNotNil(PaywallWebViewValue(jsonObject: Self.nested(depth: PaywallWebViewValue.maxDepth)))
    }

    func testValueRejectsBeyondMaxDepth() {
        XCTAssertNil(PaywallWebViewValue(jsonObject: Self.nested(depth: PaywallWebViewValue.maxDepth + 1)))
    }

    func testValueIsHashableAndEquatable() {
        let lhs: PaywallWebViewValue = .object(["a": .array([.number(1), .null])])
        let rhs: PaywallWebViewValue = .object(["a": .array([.number(1), .null])])
        let other: PaywallWebViewValue = .object(["a": .array([.number(2), .null])])

        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual(lhs.hashValue, rhs.hashValue)
        XCTAssertNotEqual(lhs, other)
        XCTAssertEqual(Set([lhs, rhs, other]).count, 2)
    }

    // MARK: - Helpers

    /// Builds an `Any` JSON value made of `depth` nested arrays around a leaf string. The leaf is
    /// processed at recursion depth `depth`, exercising ``PaywallWebViewValue/maxDepth``.
    private static func nested(depth: Int) -> Any {
        var value: Any = "leaf"
        for _ in 0..<depth {
            value = [value]
        }
        return value
    }

}

#endif
