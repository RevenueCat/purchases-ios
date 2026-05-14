//
//  ArithmeticOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

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
        // {"+": [true]} → 1
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(.bool(true))),
            .float(1.0)
        )
    }

    func testAddCoercesStringsAndBools() throws {
        // "1" + 1 → 2
        XCTAssertEqual(
            try run(ArithmeticOperators.opAdd, args: arr(.string("1"), .int(1))),
            .float(2.0)
        )
        // true + 1 + 1 → 3
        XCTAssertEqual(
            try run(
                ArithmeticOperators.opAdd,
                args: arr(.bool(true), .int(1), .int(1))
            ),
            .float(3.0)
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

    func testDivByZeroReturnsNull() throws {
        // Both .int(0) and .float(0.0) divisors → .null
        XCTAssertEqual(
            try run(ArithmeticOperators.opDiv, args: arr(.int(1), .int(0))),
            .null
        )
        XCTAssertEqual(
            try run(ArithmeticOperators.opDiv, args: arr(.int(1), .float(0.0))),
            .null
        )
        // Even 0/0 returns .null (not NaN) — explicit short-circuit before
        // arithmetic.
        XCTAssertEqual(
            try run(ArithmeticOperators.opDiv, args: arr(.int(0), .int(0))),
            .null
        )
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

    func testModByZeroReturnsNull() throws {
        XCTAssertEqual(
            try run(ArithmeticOperators.opMod, args: arr(.int(7), .int(0))),
            .null
        )
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
}
