//
//  ComparisonOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

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

    func testLtWrongArityIsTypeError() {
        XCTAssertThrowsError(try run(ComparisonOperators.opLt, args: arr(.int(1)))) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
        XCTAssertThrowsError(
            try run(ComparisonOperators.opLt, args: arr(.int(1), .int(2), .int(3), .int(4)))
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
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

    func testGtThreeArgsIsTypeErrorNoBetweenForm() {
        // `>` doesn't support a 3-arg between form (matches JS reference).
        XCTAssertThrowsError(
            try run(ComparisonOperators.opGt, args: arr(.int(3), .int(2), .int(1)))
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    func testGtOneArgIsTypeError() {
        XCTAssertThrowsError(try run(ComparisonOperators.opGt, args: arr(.int(1)))) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
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

    func testGeThreeArgsIsTypeErrorNoBetweenForm() {
        XCTAssertThrowsError(
            try run(ComparisonOperators.opGe, args: arr(.int(3), .int(2), .int(1)))
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
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
