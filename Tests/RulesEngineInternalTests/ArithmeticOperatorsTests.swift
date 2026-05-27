//
//  ArithmeticOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

// swiftlint:disable:next type_body_length
final class ArithmeticOperatorsTests: XCTestCase {

    // MARK: - +

    func testAddSumsTwoInts() throws {
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(.int(1), .int(2))),
            .float(3.0)
        )
    }

    func testAddIsVariadic() throws {
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opAdd,
                args: arr(.int(1), .int(2), .int(3), .int(4))
            ),
            .float(10.0)
        )
    }

    func testAddOneArgActsAsNumericCast() throws {
        // {"+": ["2.5"]} → 2.5
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(.string("2.5"))),
            .float(2.5)
        )
        // `{"+": [true]}` → NaN. JS uses `parseFloat(value)`, and
        // `parseFloat("true")` is `NaN` — bool coercion through arithmetic
        // is *not* the same as `Number(true) === 1`.
        let boolResult = try run(ArithmeticOperators.opAdd, args: arr(.bool(true)))
        XCTAssertTrue(unwrapFloat(boolResult).isNaN)
    }

    func testAddCoercesNumericStrings() throws {
        // "1" + 1 → 2 — `parseFloat("1")` is 1.
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(.string("1"), .int(1))),
            .float(2.0)
        )
        // "3.14abc" + 0 → 3.14 — `parseFloat` parses the longest numeric
        // prefix, so trailing junk doesn't poison the result. This is one
        // of the visible side-effects of `+` using `parseFloat` instead
        // of `Number()`.
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(.string("3.14abc"), .int(0))),
            .float(3.14)
        )
    }

    func testAddNonNumericPropagatesNan() throws {
        // Object + 1 → NaN (object can't coerce, propagates)
        let result = try run(
            ArithmeticOperators.opAdd,
            args: arr(.object([:]), .int(1))
        )
        XCTAssertTrue(unwrapFloat(result).isNaN)
    }

    func testAddZeroArgsIsTypeError() {
        XCTAssertThrowsError(try run(ArithmeticOperators.opAdd, args: arr())) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - *

    func testMulMultipliesArgs() throws {
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opMul,
                args: arr(.int(2), .int(3), .int(4))
            ),
            .float(24.0)
        )
    }

    func testMulOneArgReturnsValueAsFloat() throws {
        XCTAssertEqual(
            try run(ArithmeticOperators.opMul, args: arr(.int(5))),
            .float(5.0)
        )
    }

    func testMulCoercesOperands() throws {
        // "2" * "3" → 6
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opMul,
                args: arr(.string("2"), .string("3"))
            ),
            .float(6.0)
        )
    }

    func testMulZeroArgsIsTypeError() {
        XCTAssertThrowsError(try run(ArithmeticOperators.opMul, args: arr())) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - -

    func testSubUnaryNegates() throws {
        // {"-": [3]} → -3
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(.int(3))),
            .float(-3.0)
        )
        // Negating a string-encoded number still works
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(.string("2.5"))),
            .float(-2.5)
        )
    }

    func testSubBinarySubtracts() throws {
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opSub,
                args: arr(.int(10), .int(3))
            ),
            .float(7.0)
        )
    }

    func testSubThreeOrMoreArgsIsTypeError() {
        XCTAssertThrowsError(
            try run(ArithmeticOperators.opSub, args: arr(.int(1), .int(2), .int(3)))
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    func testSubZeroArgsIsTypeError() {
        XCTAssertThrowsError(try run(ArithmeticOperators.opSub, args: arr())) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - /

    func testDivBasic() throws {
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opDiv,
                args: arr(.int(10), .int(2))
            ),
            .float(5.0)
        )
    }

    func testDivCoercesOperands() throws {
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opDiv,
                args: arr(.string("9"), .string("3"))
            ),
            .float(3.0)
        )
    }

    /// `n / 0` follows IEEE 754: positive dividend → `+Infinity`, negative
    /// dividend → `-Infinity`, `0 / 0` → `NaN`. Matches `json-logic-js`,
    /// which delegates to native JS `/` (no short-circuit).
    func testDivByZeroFollowsIeee754() throws {
        // 1 / 0 → +Infinity (covers both .int(0) and .float(0.0) divisors).
        let posIntZero = unwrapFloat(
            try run(ArithmeticOperators.opDiv, args: arr(.int(1), .int(0)))
        )
        XCTAssertEqual(posIntZero, .infinity)
        let posFloatZero = unwrapFloat(
            try run(ArithmeticOperators.opDiv, args: arr(.int(1), .float(0.0)))
        )
        XCTAssertEqual(posFloatZero, .infinity)
        // -1 / 0 → -Infinity.
        let neg = unwrapFloat(
            try run(ArithmeticOperators.opDiv, args: arr(.int(-1), .int(0)))
        )
        XCTAssertEqual(neg, -.infinity)
        // 0 / 0 → NaN.
        assertNaN(try run(ArithmeticOperators.opDiv, args: arr(.int(0), .int(0))))
    }

    func testDivWrongArityIsTypeError() {
        XCTAssertThrowsError(try run(ArithmeticOperators.opDiv, args: arr(.int(1)))) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - %

    func testModBasic() throws {
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opMod,
                args: arr(.int(10), .int(3))
            ),
            .float(1.0)
        )
    }

    /// `n % 0` is always `NaN` per IEEE 754. Matches `json-logic-js`,
    /// which delegates to native JS `%` (no short-circuit).
    func testModByZeroIsNan() throws {
        assertNaN(try run(ArithmeticOperators.opMod, args: arr(.int(7), .int(0))))
        assertNaN(try run(ArithmeticOperators.opMod, args: arr(.int(0), .int(0))))
    }

    func testModWrongArityIsTypeError() {
        XCTAssertThrowsError(
            try run(ArithmeticOperators.opMod, args: arr(.int(1), .int(2), .int(3)))
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - Coercion semantics (`+`/`*` use parseFloat, others use Number)

    /// `+` and `*` coerce every operand through JS `parseFloat(value)`.
    /// `parseFloat` first calls `String(value)`, then parses the longest
    /// numeric prefix — so `null` becomes the string `"null"` (→ NaN),
    /// bools become `"true"` / `"false"` (→ NaN), the empty string
    /// becomes the empty string (→ NaN), and `[1,2]` becomes `"1,2"`
    /// (parses as `1`). This is asymmetric with `-` / `/` / `%`, which
    /// use `Number(value)` (see `testSubDivAndModUseToNumberPerSpec`).
    func testAddAndMulUseParseFloatPerSpec() throws {
        // null + 1 → NaN (parseFloat("null") is NaN)
        assertNaN(try run(ArithmeticOperators.opAdd, args: arr(.null, .int(1))))
        // null * 1 → NaN
        assertNaN(try run(ArithmeticOperators.opMul, args: arr(.null, .int(1))))

        // true + 1 → NaN, false + 1 → NaN. Bools never bridge through
        // `+` / `*` even though `Number(true) === 1`.
        assertNaN(try run(ArithmeticOperators.opAdd, args: arr(.bool(true), .int(1))))
        assertNaN(try run(ArithmeticOperators.opAdd, args: arr(.bool(false), .int(1))))

        // "" + 1 → NaN (parseFloat("") is NaN, unlike Number("") === 0).
        assertNaN(try run(ArithmeticOperators.opAdd, args: arr(.string(""), .int(1))))

        // [1] + 1 → 2 — array stringifies to "1", parseFloat → 1.
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(arr(.int(1)), .int(1))),
            .float(2.0)
        )
        // [1, 2] + 0 → 1 — array stringifies to "1,2", parseFloat parses
        // the leading "1" prefix and stops at the comma.
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(arr(.int(1), .int(2)), .int(0))),
            .float(1.0)
        )
        // {} + 1 → NaN — objects stringify to "[object Object]".
        assertNaN(try run(ArithmeticOperators.opAdd, args: arr(.object([:]), .int(1))))
    }

    /// `-`, `/`, `%` delegate to native JS arithmetic, which calls
    /// `Number(value)` on each operand. `Number()` is stricter about
    /// numeric strings (`"3.14abc"` → NaN) but more permissive about
    /// `null` / bools / empty strings (all → 0 or 1) than `parseFloat`.
    /// Arrays / objects coerce via `ToPrimitive("number")` → `toString`
    /// → recurse, so `[]` → 0, `[1]` → 1, `[1,2]` → NaN.
    func testSubDivAndModUseToNumberPerSpec() throws {
        // null is 0 across all three ops.
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(.null, .int(1))),
            .float(-1.0)
        )
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(.null)),
            .float(0.0)  // unary; -0.0 == 0.0
        )
        XCTAssertEqual(
            try run(ArithmeticOperators.opDiv, args: arr(.null, .int(1))),
            .float(0.0)
        )
        XCTAssertEqual(
            try run(ArithmeticOperators.opMod, args: arr(.null, .int(1))),
            .float(0.0)
        )

        // 1 / null → divisor coerces to 0 → +Infinity (IEEE 754, see
        // testDivByZeroFollowsIeee754 for the broader pinning).
        XCTAssertEqual(
            unwrapFloat(try run(ArithmeticOperators.opDiv, args: arr(.int(1), .null))),
            .infinity
        )
        // 1 % null → divisor coerces to 0 → NaN.
        assertNaN(try run(ArithmeticOperators.opMod, args: arr(.int(1), .null)))

        // Bools coerce to 0 / 1 (Number(true) === 1, Number(false) === 0).
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(.bool(true), .bool(false))),
            .float(1.0)
        )

        // Empty string coerces to 0.
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(.string(""), .int(1))),
            .float(-1.0)
        )

        // [] - 1 → -1 (toString → "" → 0).
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(arr(), .int(1))),
            .float(-1.0)
        )
        // [1] - 1 → 0 (toString → "1" → 1).
        XCTAssertEqual(
            try run(ArithmeticOperators.opSub, args: arr(arr(.int(1)), .int(1))),
            .float(0.0)
        )
        // [1, 2] - 0 → NaN (toString → "1,2" → NaN: whole-string parse
        // fails because of the comma).
        assertNaN(try run(ArithmeticOperators.opSub, args: arr(arr(.int(1), .int(2)), .int(0))))
        // {} - 0 → NaN (toString → "[object Object]" → NaN).
        assertNaN(try run(ArithmeticOperators.opSub, args: arr(.object([:]), .int(0))))
    }

    // MARK: - Helpers

    private typealias Operation = (Value, Value) throws -> Value

    private func run(_ operation: Operation, args: Value) throws -> Value {
        try operation(args, .null)
    }

    private func arr(_ items: Value...) -> Value {
        .array(items)
    }

    private func unwrapFloat(_ value: Value) -> Double {
        guard case .float(let double) = value else {
            XCTFail("expected .float, got \(value)")
            return .nan
        }
        return double
    }

    private func assertNaN(
        _ expression: @autoclosure () throws -> Value,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let value = try expression()
            guard case .float(let double) = value else {
                return XCTFail("expected .float(NaN), got \(value)", file: file, line: line)
            }
            XCTAssertTrue(double.isNaN, "expected NaN, got \(double)", file: file, line: line)
        } catch {
            XCTFail("threw \(error)", file: file, line: line)
        }
    }
}
