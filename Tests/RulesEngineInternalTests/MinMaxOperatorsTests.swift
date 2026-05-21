//
//  MinMaxOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class MinMaxOperatorsTests: XCTestCase {

    // MARK: - max

    func testMaxReturnsLargestOfManyArgs() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMax, args: arr(.int(1), .int(2), .int(3))),
            .float(3.0)
        )
    }

    func testMaxSingleArgReturnsThatValueAsFloat() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMax, args: arr(.int(7))),
            .float(7.0)
        )
    }

    func testMaxMixesIntsAndFloats() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMax, args: arr(.int(1), .float(2.5), .int(2))),
            .float(2.5)
        )
    }

    func testMaxWorksWithNegatives() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMax, args: arr(.int(-5), .int(-10), .int(-1))),
            .float(-1.0)
        )
    }

    func testMaxCoercesNumericStringsAndBools() throws {
        // {"max": ["3", "9", "5"]} → 9
        XCTAssertEqual(
            try run(
                MinMaxOperators.opMax,
                args: arr(.string("3"), .string("9"), .string("5"))
            ),
            .float(9.0)
        )
        // {"max": [true, false, 0]} → 1 (true → 1)
        XCTAssertEqual(
            try run(
                MinMaxOperators.opMax,
                args: arr(.bool(true), .bool(false), .int(0))
            ),
            .float(1.0)
        )
    }

    func testMaxNullCoercesToZero() throws {
        // null → 0
        XCTAssertEqual(
            try run(MinMaxOperators.opMax, args: arr(.null, .int(-1))),
            .float(0.0)
        )
    }

    func testMaxNonNumericPropagatesNan() throws {
        // Object operand → NaN
        let withObject = try run(
            MinMaxOperators.opMax,
            args: arr(.int(1), .object([:]))
        )
        XCTAssertTrue(unwrapFloat(withObject).isNaN)

        // Array operand → NaN
        let withArray = try run(
            MinMaxOperators.opMax,
            args: arr(.int(1), .array([.int(2)]))
        )
        XCTAssertTrue(unwrapFloat(withArray).isNaN)

        // Unparseable string → NaN
        let withBadString = try run(
            MinMaxOperators.opMax,
            args: arr(.int(1), .string("abc"))
        )
        XCTAssertTrue(unwrapFloat(withBadString).isNaN)
    }

    func testMaxOfEmptyArgsIsNegativeInfinity() throws {
        // {"max": []} → -∞ (matches JS Math.max())
        let result = try run(MinMaxOperators.opMax, args: arr())
        let asDouble = unwrapFloat(result)
        XCTAssertTrue(asDouble.isInfinite && asDouble.sign == .minus)
    }

    // MARK: - min

    func testMinReturnsSmallestOfManyArgs() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMin, args: arr(.int(1), .int(2), .int(3))),
            .float(1.0)
        )
    }

    func testMinSingleArgReturnsThatValueAsFloat() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMin, args: arr(.int(7))),
            .float(7.0)
        )
    }

    func testMinMixesIntsAndFloats() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMin, args: arr(.float(1.5), .int(2), .int(3))),
            .float(1.5)
        )
    }

    func testMinWorksWithNegatives() throws {
        XCTAssertEqual(
            try run(MinMaxOperators.opMin, args: arr(.int(-5), .int(-10), .int(-1))),
            .float(-10.0)
        )
    }

    func testMinCoercesNumericStringsAndBools() throws {
        // {"min": ["3", "9", "5"]} → 3
        XCTAssertEqual(
            try run(
                MinMaxOperators.opMin,
                args: arr(.string("3"), .string("9"), .string("5"))
            ),
            .float(3.0)
        )
        // {"min": [true, false, 5]} → 0 (false → 0)
        XCTAssertEqual(
            try run(
                MinMaxOperators.opMin,
                args: arr(.bool(true), .bool(false), .int(5))
            ),
            .float(0.0)
        )
    }

    func testMinNullCoercesToZero() throws {
        // null → 0
        XCTAssertEqual(
            try run(MinMaxOperators.opMin, args: arr(.null, .int(1))),
            .float(0.0)
        )
    }

    func testMinNonNumericPropagatesNan() throws {
        let withObject = try run(
            MinMaxOperators.opMin,
            args: arr(.int(1), .object([:]))
        )
        XCTAssertTrue(unwrapFloat(withObject).isNaN)

        let withArray = try run(
            MinMaxOperators.opMin,
            args: arr(.int(1), .array([.int(2)]))
        )
        XCTAssertTrue(unwrapFloat(withArray).isNaN)

        let withBadString = try run(
            MinMaxOperators.opMin,
            args: arr(.int(1), .string("abc"))
        )
        XCTAssertTrue(unwrapFloat(withBadString).isNaN)
    }

    func testMinOfEmptyArgsIsPositiveInfinity() throws {
        // {"min": []} → +∞ (matches JS Math.min())
        let result = try run(MinMaxOperators.opMin, args: arr())
        let asDouble = unwrapFloat(result)
        XCTAssertTrue(asDouble.isInfinite && asDouble.sign == .plus)
    }

    // MARK: - Composition

    func testNanResultFailsClosedAgainstThreshold() throws {
        // A poisoned `max` should make `>= n` come out false, which is the
        // expected fail-closed behavior for malformed predicates.
        let poisoned = try run(
            MinMaxOperators.opMax,
            args: arr(.int(1), .object([:]))
        )
        let comparison = try ComparisonOperators.opGe(
            args: .array([poisoned, .int(0)]),
            vars: .null
        )
        XCTAssertEqual(comparison, .bool(false))
    }

    func testSingleNonListArgIsImplicitlyWrapped() throws {
        // {"max": 5} ≡ {"max": [5]} per Operators.argsAsList semantics.
        XCTAssertEqual(
            try run(MinMaxOperators.opMax, args: .int(5)),
            .float(5.0)
        )
        XCTAssertEqual(
            try run(MinMaxOperators.opMin, args: .int(5)),
            .float(5.0)
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

    private func unwrapFloat(_ value: Value) -> Double {
        guard case .float(let double) = value else {
            XCTFail("expected .float, got \(value)")
            return .nan
        }
        return double
    }
}
