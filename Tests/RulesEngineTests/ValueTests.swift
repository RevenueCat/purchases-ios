//
//  ValueTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

final class ValueTests: XCTestCase {

    // MARK: - JSON parsing (test helper)

    func testParsesPrimitives() throws {
        XCTAssertEqual(try Value.fromJSONString("null"), .null)
        XCTAssertEqual(try Value.fromJSONString("true"), .bool(true))
        XCTAssertEqual(try Value.fromJSONString("false"), .bool(false))
        XCTAssertEqual(try Value.fromJSONString("42"), .int(42))
        XCTAssertEqual(try Value.fromJSONString("-7"), .int(-7))
        XCTAssertEqual(try Value.fromJSONString("2.5"), .float(2.5))
        XCTAssertEqual(try Value.fromJSONString("\"hello\""), .string("hello"))
    }

    func testParsesArrayAndObject() throws {
        let array = try Value.fromJSONString("[1, \"two\", true, null]")
        XCTAssertEqual(
            array,
            .array([.int(1), .string("two"), .bool(true), .null])
        )

        let object = try Value.fromJSONString("{\"a\": 1, \"b\": \"two\"}")
        guard case .object(let map) = object else {
            return XCTFail("expected object")
        }
        XCTAssertEqual(map["a"], .int(1))
        XCTAssertEqual(map["b"], .string("two"))
    }

    func testParseErrorForMalformedJSON() {
        XCTAssertThrowsError(try Value.fromJSONString("{not json")) { error in
            guard case RuleError.parse = error else {
                return XCTFail("expected RuleError.parse, got \(error)")
            }
        }
    }

    func testIntegerLookingNumbersAreIntNotFloat() throws {
        XCTAssertEqual(try Value.fromJSONString("0"), .int(0))
        XCTAssertEqual(try Value.fromJSONString("100"), .int(100))
        XCTAssertEqual(try Value.fromJSONString("100.0"), .float(100.0))
    }

    // MARK: - Truthiness

    func testTruthinessTable() {
        XCTAssertFalse(Value.null.isTruthy)
        XCTAssertFalse(Value.bool(false).isTruthy)
        XCTAssertTrue(Value.bool(true).isTruthy)
        XCTAssertFalse(Value.int(0).isTruthy)
        XCTAssertTrue(Value.int(1).isTruthy)
        XCTAssertTrue(Value.int(-1).isTruthy)
        XCTAssertFalse(Value.float(0.0).isTruthy)
        XCTAssertFalse(Value.float(.nan).isTruthy)
        XCTAssertTrue(Value.float(0.5).isTruthy)
        XCTAssertFalse(Value.string("").isTruthy)
        XCTAssertTrue(Value.string("0").isTruthy) // non-empty string is truthy
        XCTAssertFalse(Value.array([]).isTruthy)
        XCTAssertTrue(Value.array([.bool(false)]).isTruthy) // non-empty array
        XCTAssertTrue(Value.object([:]).isTruthy) // objects always truthy
    }

    // MARK: - Loose equality

    func testLooseEqSameType() {
        XCTAssertTrue(looseEq(.int(1), .int(1)))
        XCTAssertFalse(looseEq(.int(1), .int(2)))
        XCTAssertTrue(looseEq(.string("abc"), .string("abc")))
        XCTAssertTrue(looseEq(.bool(true), .bool(true)))
    }

    func testLooseEqIntVsFloat() {
        XCTAssertTrue(looseEq(.int(1), .float(1.0)))
        XCTAssertFalse(looseEq(.int(1), .float(1.5)))
    }

    func testLooseEqBoolVsNumber() {
        XCTAssertTrue(looseEq(.bool(true), .int(1)))
        XCTAssertTrue(looseEq(.bool(false), .int(0)))
        XCTAssertTrue(looseEq(.bool(true), .float(1.0)))
        XCTAssertFalse(looseEq(.bool(true), .int(2)))
    }

    func testLooseEqStringVsNumber() {
        XCTAssertTrue(looseEq(.string("1"), .int(1)))
        XCTAssertTrue(looseEq(.string("1.5"), .float(1.5)))
        XCTAssertFalse(looseEq(.string("hello"), .int(0)))
    }

    func testLooseEqNullOnlyEqualsNull() {
        XCTAssertTrue(looseEq(.null, .null))
        XCTAssertFalse(looseEq(.null, .int(0)))
        XCTAssertFalse(looseEq(.null, .bool(false)))
        XCTAssertFalse(looseEq(.null, .string("")))
    }

    func testLooseEqArraysStructural() {
        XCTAssertTrue(
            looseEq(
                .array([.int(1), .int(2)]),
                .array([.int(1), .float(2.0)])
            )
        )
        XCTAssertFalse(
            looseEq(
                .array([.int(1)]),
                .array([.int(1), .int(2)])
            )
        )
    }

    // MARK: - Strict equality

    func testStrictEqRequiresSameValueOrCompatibleNumeric() {
        XCTAssertTrue(strictEq(.int(1), .int(1)))
        XCTAssertTrue(strictEq(.int(1), .float(1.0))) // int/float bridge as one number type
        XCTAssertFalse(strictEq(.int(1), .string("1")))
        XCTAssertFalse(strictEq(.bool(true), .int(1)))
        XCTAssertFalse(strictEq(.null, .bool(false)))
    }
}
