//
//  AccessorOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class AccessorOperatorsTests: XCTestCase {

    private var logger: CapturingLogger!

    override func setUp() {
        super.setUp()
        logger = CapturingLogger()
        RulesEngine.setLogger(logger)
    }

    override func tearDown() {
        logger = nil
        super.tearDown()
    }

    // MARK: - var
    //
    // The remaining `var` cases below are kept as Swift tests because they
    // cannot be expressed as JSON predicate fixtures:
    //  - The fixture scope is always a JSON object (`Evaluator.evaluate`
    //    takes `[String: Value]`), but these exercise a top-level *array*
    //    scope.
    //  - `var` with an empty path returns the entire data object, and this
    //    engine's `===` is always false for objects, so no predicate can
    //    assert the result.

    func testVarEmptyPathReturnsEntireData() throws {
        let vars = Value.object(["x": .int(1)])
        let out = try AccessorOperators.opVar(args: .string(""), vars: vars)
        XCTAssertEqual(out, vars)
    }

    func testVarWithNumericPathArgIsCoercedToString() throws {
        // {"var": 0} on array data
        let vars = Value.array([.string("zero"), .string("one")])
        let out = try AccessorOperators.opVar(args: .int(0), vars: vars)
        XCTAssertEqual(out, .string("zero"))
    }

    func testVarWithIntegerValuedFloatPathLooksUpIntegerIndex() throws {
        // {"var": 1.0} on array data must render as "1" (not "1.0") so the
        // path resolves to array index 1 — same lookup as `{"var": 1}`.
        let vars = Value.array([.string("zero"), .string("one"), .string("two")])
        let out = try AccessorOperators.opVar(args: .float(1.0), vars: vars)
        XCTAssertEqual(out, .string("one"))
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testVarWithFractionalFloatPathDoesNotMatchAdjacentIndices() throws {
        // {"var": 1.5} must not silently collapse to "1" or "2" — its
        // rendered path is "1.5", which doesn't resolve, so the lookup
        // misses and warns. Guards against an over-eager rounding fix to
        // `formatNumber`.
        let vars = Value.array([.string("zero"), .string("one"), .string("two")])
        let out = try AccessorOperators.opVar(args: .float(1.5), vars: vars)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(logger.warnings.count, 1)
        XCTAssertTrue(logger.warnings[0].contains("1.5"))
    }
}
