//
//  ValueTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

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

    func testLooseEqArrayVsArrayIsAlwaysFalse() {
        // JS abstract equality uses reference identity for arrays —
        // `[1] == [1]` is `false`. Without reference identity, two
        // distinct array operands always compare unequal.
        XCTAssertFalse(
            looseEq(
                .array([.int(1), .int(2)]),
                .array([.int(1), .int(2)])
            )
        )
        XCTAssertFalse(looseEq(.array([]), .array([])))
    }

    func testLooseEqObjectVsObjectIsAlwaysFalse() {
        // Same reference-equality rule as arrays — `{a:1} == {a:1}` is
        // `false` in JS, regardless of structure.
        XCTAssertFalse(
            looseEq(
                .object(["a": .int(1), "b": .string("x")]),
                .object(["a": .int(1), "b": .string("x")])
            )
        )
        XCTAssertFalse(looseEq(.object([:]), .object([:])))
    }

    // MARK: - Loose equality: JS array/object stringify coercion

    func testLooseEqArrayCoercesToJSStringAgainstString() {
        // JS abstract equality: `Array.prototype.toString()` is invoked,
        // then the comparison falls through to string-vs-string.
        // Reference: `[1] == "1"` → true, `[1, 2] == "1,2"` → true.
        XCTAssertTrue(looseEq(.array([.int(1)]), .string("1")))
        XCTAssertTrue(looseEq(.string("1"), .array([.int(1)])))
        XCTAssertTrue(looseEq(.array([.int(1), .int(2)]), .string("1,2")))
        XCTAssertTrue(looseEq(.array([.string("a"), .string("b")]), .string("a,b")))
        XCTAssertTrue(looseEq(.array([]), .string("")))
        // Non-matching content still compares unequal.
        XCTAssertFalse(looseEq(.array([.int(1)]), .string("2")))
    }

    func testLooseEqArrayElementsRenderJSNullAsEmptyString() {
        // `[null].toString()` is `""` (not `"null"`), and
        // `[null, 1].toString()` is `",1"`. The element-stringify rule
        // is JS-specific; pin it directly.
        XCTAssertTrue(looseEq(.array([.null]), .string("")))
        XCTAssertTrue(looseEq(.array([.null, .int(1)]), .string(",1")))
        XCTAssertTrue(looseEq(.array([.null, .null]), .string(",")))
    }

    func testLooseEqArrayRecursesIntoNestedArrays() {
        // `[[1, 2], 3].toString()` flattens to `"1,2,3"` — children
        // recurse through the same join.
        XCTAssertTrue(
            looseEq(
                .array([.array([.int(1), .int(2)]), .int(3)]),
                .string("1,2,3")
            )
        )
    }

    func testLooseEqArrayCoercesThroughNumericFallback() {
        // After ToPrimitive, the recursion may hit the
        // string-vs-number numeric fallback. Reference:
        // `[1] == 1` → true, `[] == 0` → true, `[0] == false` → true.
        XCTAssertTrue(looseEq(.array([.int(1)]), .int(1)))
        XCTAssertTrue(looseEq(.array([]), .int(0)))
        XCTAssertTrue(looseEq(.array([.int(0)]), .bool(false)))
        XCTAssertTrue(looseEq(.array([.float(1.5)]), .float(1.5)))
        // No spurious matches when the stringified array isn't numeric.
        XCTAssertFalse(looseEq(.array([.string("hello")]), .int(0)))
    }

    func testLooseEqArrayRendersJSSpecificFloatsCorrectly() {
        // `String(1.0)` is `"1"` (no decimal), `String(NaN)` is `"NaN"`,
        // `String(Infinity)` is `"Infinity"`. These show up only via the
        // array stringify path — `==` against a bare `Double.nan` would
        // still be `false` because NaN isn't equal to itself.
        XCTAssertTrue(looseEq(.array([.float(1.0)]), .string("1")))
        XCTAssertTrue(looseEq(.array([.float(.nan)]), .string("NaN")))
        XCTAssertTrue(looseEq(.array([.float(.infinity)]), .string("Infinity")))
        XCTAssertTrue(looseEq(.array([.float(-.infinity)]), .string("-Infinity")))
    }

    func testLooseEqObjectCoercesToObjectObjectString() {
        // JS `Object.prototype.toString.call({a: 1})` is
        // `"[object Object]"`, so any object compared against that
        // exact string is loosely equal.
        XCTAssertTrue(
            looseEq(.object(["a": .int(1), "b": .int(2)]), .string("[object Object]"))
        )
        XCTAssertTrue(
            looseEq(.string("[object Object]"), .object([:]))
        )
        XCTAssertFalse(
            looseEq(.object(["a": .int(1), "b": .int(2)]), .string("{a:1,b:2}"))
        )
    }

    func testLooseEqArrayVsObjectIsAlwaysFalse() {
        // Two compound operands of different shape: JS uses reference
        // identity (false). Both ToPrimitive results are strings that
        // can't ever match (`"1,2"` vs `"[object Object]"`).
        XCTAssertFalse(
            looseEq(
                .array([.int(1), .int(2)]),
                .object(["a": .int(1), "b": .int(2)])
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

    func testStrictEqArraysAndObjectsAlwaysFalse() {
        // JS `===` for arrays/objects is reference identity — same
        // rationale as `looseEq`. Without references, distinct operands
        // always compare unequal.
        XCTAssertFalse(strictEq(.array([.int(1)]), .array([.int(1)])))
        XCTAssertFalse(strictEq(.array([]), .array([])))
        XCTAssertFalse(strictEq(.object(["a": .int(1)]), .object(["a": .int(1)])))
        XCTAssertFalse(strictEq(.object([:]), .object([:])))
    }

    // MARK: - NaN / Infinity edge cases

    func testNaNIsFalsyAndNeverEqualsItself() {
        // IEEE 754: any comparison involving NaN is false, including NaN==NaN.
        // We piggy-back on `==` (rather than reimplementing it), so callers
        // that introduce NaN through float coercion get the standard "NaN
        // poisons the comparison" behavior.
        XCTAssertFalse(Value.float(.nan).isTruthy)
        XCTAssertFalse(looseEq(.float(.nan), .float(.nan)))
        XCTAssertFalse(strictEq(.float(.nan), .float(.nan)))
        XCTAssertFalse(looseEq(.float(.nan), .int(0)))
        XCTAssertFalse(looseEq(.float(.nan), .float(0.0)))
    }

    func testInfinityIsTruthyAndComparesByIEEE754() {
        XCTAssertTrue(Value.float(.infinity).isTruthy)
        XCTAssertTrue(Value.float(-.infinity).isTruthy)

        XCTAssertTrue(looseEq(.float(.infinity), .float(.infinity)))
        XCTAssertTrue(strictEq(.float(.infinity), .float(.infinity)))
        XCTAssertFalse(looseEq(.float(.infinity), .float(-.infinity)))

        // Cross-type: +Infinity never numerically equals a finite int.
        XCTAssertFalse(looseEq(.float(.infinity), .int(.max)))
    }

    func testJsNumberStringFallsThroughToSwiftDoubleStringForOutOfInt64Range() {
        // Last whole number that still round-trips through Int64 — fast path,
        // matches JS (`String(1e18) === "1000000000000000000"`).
        XCTAssertEqual(jsString(.float(1e18)), "1000000000000000000")

        // Spec-divergence pin: see KDoc on jsNumberString. JS renders `1e19`
        // as `"10000000000000000000"`; Swift uses `"1e+19"`.
        XCTAssertEqual(jsString(.float(1e19)), "1e+19")
    }
}
