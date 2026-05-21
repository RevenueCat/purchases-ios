//
//  LogicOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class LogicOperatorsTests: XCTestCase {

    // MARK: - !

    func testNotNegatesTruthyToFalse() throws {
        XCTAssertEqual(try LogicOperators.opNot(args: .bool(true), vars: .null), .bool(false))
        XCTAssertEqual(try LogicOperators.opNot(args: .int(5), vars: .null), .bool(false))
    }

    func testNotNegatesFalsyToTrue() throws {
        XCTAssertEqual(try LogicOperators.opNot(args: .bool(false), vars: .null), .bool(true))
        XCTAssertEqual(try LogicOperators.opNot(args: .int(0), vars: .null), .bool(true))
        XCTAssertEqual(try LogicOperators.opNot(args: .null, vars: .null), .bool(true))
    }

    func testNotUnwrapsSingletonArray() throws {
        XCTAssertEqual(
            try LogicOperators.opNot(args: .array([.bool(true)]), vars: .null),
            .bool(false)
        )
    }

    // MARK: - !!

    func testNotNotCastsToBool() throws {
        XCTAssertEqual(try LogicOperators.opNotNot(args: .int(5), vars: .null), .bool(true))
        XCTAssertEqual(try LogicOperators.opNotNot(args: .string(""), vars: .null), .bool(false))
    }

    // MARK: - and

    func testAndReturnsFirstFalsyValue() throws {
        let args = Value.array([.int(1), .int(0), .int(2)])
        XCTAssertEqual(try LogicOperators.opAnd(args: args, vars: .null), .int(0)) // first falsy
    }

    func testAndReturnsLastValueWhenAllTruthy() throws {
        let args = Value.array([.int(1), .int(2), .int(3)])
        XCTAssertEqual(try LogicOperators.opAnd(args: args, vars: .null), .int(3))
    }

    func testAndShortCircuitsOnFirstFalsy() throws {
        // Second arg is falsy; third would error if evaluated (unsupported op).
        let args = Value.array([
            .int(1),
            .bool(false),
            .object(["definitelyNotAnOp": .array([.int(1)])])
        ])
        XCTAssertEqual(try LogicOperators.opAnd(args: args, vars: .null), .bool(false))
    }

    func testAndEmptyReturnsNull() throws {
        // Spec parity: json-logic-js returns `undefined` for `{"and": []}`,
        // which we map to `.null`. Both are falsy, so an outer `if` will
        // take its `else` branch.
        XCTAssertEqual(try LogicOperators.opAnd(args: .array([]), vars: .null), .null)
    }

    func testEmptyAndInsideIfTakesElseBranch() throws {
        // Reaches into the `if`/`and` interaction the spec parity is meant
        // to preserve. With `{"and": []}` → `.null` (falsy), the surrounding
        // `if` selects the `else` branch — the previous behavior of
        // returning `.bool(true)` for vacuous truth would have flipped this.
        let args = Value.array([
            .object(["and": .array([])]),
            .string("yes"),
            .string("no")
        ])
        XCTAssertEqual(try LogicOperators.opIf(args: args, vars: .null), .string("no"))
    }

    // MARK: - or

    func testOrReturnsFirstTruthyValue() throws {
        let args = Value.array([.int(0), .int(7), .int(2)])
        XCTAssertEqual(try LogicOperators.opOr(args: args, vars: .null), .int(7))
    }

    func testOrReturnsLastValueWhenAllFalsy() throws {
        let args = Value.array([.int(0), .bool(false), .null])
        XCTAssertEqual(try LogicOperators.opOr(args: args, vars: .null), .null)
    }

    func testOrEmptyReturnsNull() throws {
        // Spec parity: json-logic-js returns `undefined` for `{"or": []}`,
        // which we map to `.null` (rather than `.bool(false)`). Falsy, so
        // outer truthiness checks behave identically to the old return.
        XCTAssertEqual(try LogicOperators.opOr(args: .array([]), vars: .null), .null)
    }

    // MARK: - if

    func testIfThreeArgForm() throws {
        let yesNoTrue = Value.array([.bool(true), .string("yes"), .string("no")])
        XCTAssertEqual(try LogicOperators.opIf(args: yesNoTrue, vars: .null), .string("yes"))

        let yesNoFalse = Value.array([.bool(false), .string("yes"), .string("no")])
        XCTAssertEqual(try LogicOperators.opIf(args: yesNoFalse, vars: .null), .string("no"))
    }

    func testIfChainedElseIf() throws {
        // if (false) "a" else if (true) "b" else "c"  →  "b"
        let args = Value.array([
            .bool(false),
            .string("a"),
            .bool(true),
            .string("b"),
            .string("c")
        ])
        XCTAssertEqual(try LogicOperators.opIf(args: args, vars: .null), .string("b"))
    }

    func testIfNoTruthyNoElseReturnsNull() throws {
        // Even-arity, no else, no truthy condition.
        let args = Value.array([
            .bool(false),
            .string("a"),
            .bool(false),
            .string("b")
        ])
        XCTAssertEqual(try LogicOperators.opIf(args: args, vars: .null), .null)
    }

    func testIfEmptyReturnsNull() throws {
        XCTAssertEqual(try LogicOperators.opIf(args: .array([]), vars: .null), .null)
    }

    func testIfSingleArgReturnsItUnchanged() throws {
        // `{"if": [expr]}` — degenerate form: no condition pair and no
        // explicit else slot, so the lone argument falls through to the
        // trailing "else" branch and is returned as-is.
        XCTAssertEqual(
            try LogicOperators.opIf(args: .array([.string("only")]), vars: .null),
            .string("only")
        )
        XCTAssertEqual(
            try LogicOperators.opIf(args: .array([.bool(false)]), vars: .null),
            .bool(false)
        )
    }

    func testIfTwoArgFormReturnsThenOrNull() throws {
        // `{"if": [cond, then]}` — no else clause. Returns `then` when the
        // condition is truthy, `null` otherwise (rather than the falsy
        // condition value).
        let truthy = Value.array([.bool(true), .string("yes")])
        XCTAssertEqual(try LogicOperators.opIf(args: truthy, vars: .null), .string("yes"))

        let falsy = Value.array([.bool(false), .string("yes")])
        XCTAssertEqual(try LogicOperators.opIf(args: falsy, vars: .null), .null)

        let falsyInt = Value.array([.int(0), .string("yes")])
        XCTAssertEqual(try LogicOperators.opIf(args: falsyInt, vars: .null), .null)
    }
}
