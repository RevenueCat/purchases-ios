//
//  ComparisonOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class ComparisonOperatorsTests: XCTestCase {

    // MARK: - <

    func testLtBasicTwoArgs() throws {
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(1), .int(2))),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(2), .int(2))),
            .bool(false)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(3), .int(2))),
            .bool(false)
        )
    }

    func testLtBetweenFormThreeArgs() throws {
        // 1 < 2 < 3 → true
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(1), .int(2), .int(3))),
            .bool(true)
        )
        // 1 < 1 < 3 → false (first inequality strict)
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(1), .int(1), .int(3))),
            .bool(false)
        )
        // 1 < 5 < 3 → false (second inequality fails)
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(1), .int(5), .int(3))),
            .bool(false)
        )
    }

    func testLtCoercesStringsAndBools() throws {
        // "1" < 2 → numeric → true
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.string("1"), .int(2))),
            .bool(true)
        )
        // false < true → 0 < 1 → true
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.bool(false), .bool(true))),
            .bool(true)
        )
        // null < 1 → 0 < 1 → true
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.null, .int(1))),
            .bool(true)
        )
    }

    func testLtComparesTwoStringsLexicographically() throws {
        // Per the JSON Logic spec (ECMAScript Abstract Relational
        // Comparison), two string operands compare lexicographically.
        // "10" < "9" → true because '1' (0x31) < '9' (0x39).
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.string("10"), .string("9"))),
            .bool(true)
        )
        // Plain alphabetic ordering also flows through.
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.string("apple"), .string("banana"))),
            .bool(true)
        )
        // Empty string is lex-less than any non-empty string.
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.string(""), .string("a"))),
            .bool(true)
        )
    }

    func testLtMixedStringAndNumberCoercesNumerically() throws {
        // Mixed types fall through to numeric coercion, NOT lex — `"10" < 9`
        // becomes `10 < 9` → false, while a pure-string compare would have
        // said true. This is the JS spec's "only lex when BOTH are strings"
        // branch.
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.string("10"), .int(9))),
            .bool(false)
        )
        // Non-numeric string coerces to NaN → comparison is false.
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.string("abc"), .int(9))),
            .bool(false)
        )
    }

    func testLtAgainstNonNumericIsFalseViaNan() throws {
        // Object can't coerce → NaN; any compare against NaN is false.
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.object([:]), .int(1))),
            .bool(false)
        )
    }

    func testNullOperandsCoerceToZero() throws {
        // `Number(null)` is 0; object/array operands still hit NaN.
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.null, .null)),
            .bool(false)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.null, .null)),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opGt, args: arr(.null, .null)),
            .bool(false)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opGe, args: arr(.null, .null)),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.null, .object([:]))),
            .bool(false)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.object([:]), .null)),
            .bool(false)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.null, .array([]))),
            .bool(false)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.int(0), .null, .int(1))),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(0), .null, .int(1))),
            .bool(false)
        )
    }

    /// `json-logic-js` declares `<` as `function(a, b, c)` so missing
    /// operands resolve to `undefined`, which coerces to `NaN`; any
    /// comparison against `NaN` is `false`.
    func testLtMissingOperandsCompareAgainstNaN() throws {
        XCTAssertEqual(try run(ComparisonOperators.opLt, args: arr(.int(1))), .bool(false))
        XCTAssertEqual(try run(ComparisonOperators.opLt, args: arr()), .bool(false))
    }

    /// `json-logic-js`'s `<` ignores arguments past the third (JS
    /// silently drops named parameters' overflow).
    func testLtIgnoresArgsBeyondThird() throws {
        XCTAssertEqual(
            try run(ComparisonOperators.opLt, args: arr(.int(1), .int(2), .int(3), .int(0))),
            .bool(true)
        )
    }

    // MARK: - <=

    func testLeBasicTwoArgs() throws {
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.int(1), .int(2))),
            .bool(true)
        )
        // Equal counts as "less than or equal", unlike `<`.
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.int(2), .int(2))),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.int(3), .int(2))),
            .bool(false)
        )
    }

    func testLeComparesTwoStringsLexicographicallyInclusive() throws {
        // Lex compare under `<=` — equal strings qualify, ordered strings
        // resolve by spec.
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.string("abc"), .string("abc"))),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.string("9"), .string("10"))),
            .bool(false)
        )
    }

    func testLeBetweenFormInclusive() throws {
        // 1 <= 2 <= 3 → true
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.int(1), .int(2), .int(3))),
            .bool(true)
        )
        // 1 <= 1 <= 3 → true (boundary inclusive, distinguishes from `<`)
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.int(1), .int(1), .int(3))),
            .bool(true)
        )
        // 1 <= 0 <= 3 → false
        XCTAssertEqual(
            try run(ComparisonOperators.opLe, args: arr(.int(1), .int(0), .int(3))),
            .bool(false)
        )
    }

    // MARK: - >

    func testGtBasicTwoArgs() throws {
        XCTAssertEqual(
            try run(ComparisonOperators.opGt, args: arr(.int(2), .int(1))),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opGt, args: arr(.int(2), .int(2))),
            .bool(false)
        )
    }

    func testGtComparesTwoStringsLexicographically() throws {
        // "9" > "10" → true (lex, '9' > '1'). Mirrors the `<` case in
        // reverse and confirms the lex/numeric dispatch covers `>` too.
        XCTAssertEqual(
            try run(ComparisonOperators.opGt, args: arr(.string("9"), .string("10"))),
            .bool(true)
        )
    }

    /// `>` is `function(a, b)` in `json-logic-js`, so extras are
    /// silently discarded — there is no 3-arg between form.
    func testGtIgnoresArgsBeyondSecond() throws {
        XCTAssertEqual(
            try run(ComparisonOperators.opGt, args: arr(.int(3), .int(2), .int(1))),
            .bool(true)
        )
    }

    /// Missing second operand resolves to `undefined`, coerces to
    /// `NaN`, and any comparison against `NaN` is `false`.
    func testGtMissingOperandsCompareAgainstNaN() throws {
        XCTAssertEqual(try run(ComparisonOperators.opGt, args: arr(.int(1))), .bool(false))
        XCTAssertEqual(try run(ComparisonOperators.opGt, args: arr()), .bool(false))
    }

    // MARK: - >=

    func testGeBasicTwoArgs() throws {
        XCTAssertEqual(
            try run(ComparisonOperators.opGe, args: arr(.int(2), .int(1))),
            .bool(true)
        )
        // Equal qualifies, unlike `>`.
        XCTAssertEqual(
            try run(ComparisonOperators.opGe, args: arr(.int(2), .int(2))),
            .bool(true)
        )
        XCTAssertEqual(
            try run(ComparisonOperators.opGe, args: arr(.int(1), .int(2))),
            .bool(false)
        )
    }

    /// `>=` is `function(a, b)` in `json-logic-js`, so extras are
    /// silently discarded — there is no 3-arg between form.
    func testGeIgnoresArgsBeyondSecond() throws {
        XCTAssertEqual(
            try run(ComparisonOperators.opGe, args: arr(.int(3), .int(2), .int(1))),
            .bool(true)
        )
    }

    // MARK: - Helpers

    private typealias Operation = (Value, Value) throws -> Value

    private func run(_ operation: Operation, args: Value) throws -> Value {
        try operation(args, .null)
    }

    private func arr(_ items: Value...) -> Value {
        .array(items)
    }
}
