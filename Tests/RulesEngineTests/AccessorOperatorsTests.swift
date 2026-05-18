//
//  AccessorOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@_spi(Internal) @testable import RulesEngine

final class AccessorOperatorsTests: XCTestCase {

    private var logger: CapturingLogger!

    override func setUp() {
        super.setUp()
        logger = CapturingLogger()
        Rules.logger = logger
    }

    override func tearDown() {
        logger = nil
        super.tearDown()
    }

    // MARK: - var

    func testVarResolvesTopLevelKey() throws {
        let vars = Value.object(["name": .string("ada")])
        let out = try AccessorOperators.opVar(args: .string("name"), vars: vars)
        XCTAssertEqual(out, .string("ada"))
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testVarResolvesDotPathIntoNestedObject() throws {
        // {"subscriber": {"last_seen_country": "US"}}
        let vars = Value.object([
            "subscriber": .object(["last_seen_country": .string("US")])
        ])
        let out = try AccessorOperators.opVar(
            args: .string("subscriber.last_seen_country"),
            vars: vars
        )
        XCTAssertEqual(out, .string("US"))
    }

    func testVarIndexesIntoArraysViaNumericSegments() throws {
        let vars = Value.object([
            "items": .array([.string("first"), .string("second"), .string("third")])
        ])
        let out = try AccessorOperators.opVar(args: .string("items.1"), vars: vars)
        XCTAssertEqual(out, .string("second"))
    }

    func testVarMissingKeyReturnsNullAndWarns() throws {
        let vars = Value.object(["a": .int(1)])
        let out = try AccessorOperators.opVar(args: .string("missing_key"), vars: vars)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(logger.warnings.count, 1)
        XCTAssertTrue(logger.warnings[0].contains("missing_key"))
    }

    func testVarMissingDotPathReturnsNullAndWarns() throws {
        let vars = Value.object(["a": .object(["b": .int(1)])])
        let out = try AccessorOperators.opVar(args: .string("a.c"), vars: vars)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(logger.warnings.count, 1)
        XCTAssertTrue(logger.warnings[0].contains("a.c"))
    }

    func testVarMissingWithDefaultReturnsDefaultAndDoesNotWarn() throws {
        let vars = Value.object(["a": .int(1)])
        let result = try AccessorOperators.opVar(
            args: .array([.string("missing"), .string("fallback")]),
            vars: vars
        )
        XCTAssertEqual(result, .string("fallback"))
        XCTAssertTrue(logger.warnings.isEmpty)
    }

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

    func testVarWithOversizedFloatPathDoesNotCrash() throws {
        // `1e19` is a finite whole-number Double whose magnitude exceeds
        // Int64.max (~9.22e18). A naive `Int64(value)` traps; the path
        // formatter must round-trip safely so the lookup just misses.
        let oversized = Value.float(1.0e19)
        let out = try AccessorOperators.opVar(args: oversized, vars: .null)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(logger.warnings.count, 1)
    }

    func testVarDoesNotApplyFlatKeyFallback() throws {
        // The literal key "a.b" exists in the flat map, but our spec-strict
        // lookup walks "a" then "b" and finds nothing. Documents the
        // deferred fallback behavior.
        let vars = Value.object(["a.b": .int(42)])
        let out = try AccessorOperators.opVar(args: .string("a.b"), vars: vars)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(logger.warnings.count, 1)
    }

    func testVarExtraArgsAreIgnoredWithWarning() throws {
        // Reference impls silently ignore extras; we surface a warning so it
        // doesn't become a silent bug. Path + default still resolve normally.
        let vars = Value.object(["a": .int(1)])
        let out = try AccessorOperators.opVar(
            args: .array([
                .string("missing_key"),
                .string("fallback"),
                .string("ignored1"),
                .string("ignored2")
            ]),
            vars: vars
        )
        // Default kicks in (path is missing) — extras don't change the result.
        XCTAssertEqual(out, .string("fallback"))
        // One warning for the extras; no missing-variable warning since the
        // default short-circuited the lookup.
        XCTAssertEqual(logger.warnings.count, 1)
        XCTAssertTrue(logger.warnings[0].contains("ignoring 2 extra"))
    }

    // MARK: - missing

    func testMissingReturnsKeysNotPresent() throws {
        let vars = Value.object(["a": .int(1), "b": .int(2)])
        let result = try AccessorOperators.opMissing(
            args: .array([.string("a"), .string("b"), .string("c")]),
            vars: vars
        )
        XCTAssertEqual(result, .array([.string("c")]))
        // `missing` itself does not warn (it's a check, not a read).
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testMissingReturnsEmptyArrayWhenAllPresent() throws {
        let vars = Value.object(["a": .int(1)])
        let result = try AccessorOperators.opMissing(
            args: .array([.string("a")]),
            vars: vars
        )
        XCTAssertEqual(result, .array([]))
    }

    func testMissingSupportsDotPathKeys() throws {
        let vars = Value.object(["user": .object(["name": .string("ada")])])
        let result = try AccessorOperators.opMissing(
            args: .array([.string("user.name"), .string("user.email")]),
            vars: vars
        )
        XCTAssertEqual(result, .array([.string("user.email")]))
    }

    func testMissingSingletonShorthandIsSupported() throws {
        let vars = Value.object([:])
        let result = try AccessorOperators.opMissing(args: .string("a"), vars: vars)
        XCTAssertEqual(result, .array([.string("a")]))
    }
}
