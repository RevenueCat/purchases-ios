//
//  EqualityOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

final class EqualityOperatorsTests: XCTestCase {

    func testLooseEqBasic() throws {
        XCTAssertEqual(try evalEq(.array([.int(1), .int(1)])), .bool(true))
        XCTAssertEqual(try evalEq(.array([.int(1), .int(2)])), .bool(false))
    }

    func testLooseEqDoesTypeCoercion() throws {
        // "1" == 1
        XCTAssertEqual(try evalEq(.array([.string("1"), .int(1)])), .bool(true))
        // true == 1
        XCTAssertEqual(try evalEq(.array([.bool(true), .int(1)])), .bool(true))
    }

    func testStrictEqDoesNotCoerce() throws {
        // "1" !== 1
        XCTAssertEqual(try evalStrictEq(.array([.string("1"), .int(1)])), .bool(false))
        // 1 === 1
        XCTAssertEqual(try evalStrictEq(.array([.int(1), .int(1)])), .bool(true))
        // 1 === 1.0 (int/float bridge as one number type)
        XCTAssertEqual(try evalStrictEq(.array([.int(1), .float(1.0)])), .bool(true))
    }

    func testLooseNeIsNegationOfLooseEq() throws {
        XCTAssertEqual(try evalNe(.array([.int(1), .int(1)])), .bool(false))
        XCTAssertEqual(try evalNe(.array([.int(1), .int(2)])), .bool(true))
    }

    func testStrictNeIsNegationOfStrictEq() throws {
        XCTAssertEqual(try evalStrictNe(.array([.int(1), .int(1)])), .bool(false))
        XCTAssertEqual(try evalStrictNe(.array([.string("1"), .int(1)])), .bool(true))
    }

    func testArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try EqualityOperators.opLooseEq(args: .array([.int(1)]), vars: .null)
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected RuleError.typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func evalEq(_ args: Value) throws -> Value {
        try EqualityOperators.opLooseEq(args: args, vars: .null)
    }
    private func evalNe(_ args: Value) throws -> Value {
        try EqualityOperators.opLooseNe(args: args, vars: .null)
    }
    private func evalStrictEq(_ args: Value) throws -> Value {
        try EqualityOperators.opStrictEq(args: args, vars: .null)
    }
    private func evalStrictNe(_ args: Value) throws -> Value {
        try EqualityOperators.opStrictNe(args: args, vars: .null)
    }
}
