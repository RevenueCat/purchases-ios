//
//  AccessorOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

final class AccessorOperatorsTests: XCTestCase {

    // MARK: - var

    func testVarResolvesTopLevelKey() throws {
        let vars = Value.object(["name": .string("ada")])
        let (out, warnings) = try runVar(.string("name"), vars: vars)
        XCTAssertEqual(out, .string("ada"))
        XCTAssertTrue(warnings.isEmpty)
    }

    func testVarResolvesDotPathIntoNestedObject() throws {
        // {"subscriber": {"last_seen_country": "US"}}
        let vars = Value.object([
            "subscriber": .object(["last_seen_country": .string("US")])
        ])
        let (out, _) = try runVar(.string("subscriber.last_seen_country"), vars: vars)
        XCTAssertEqual(out, .string("US"))
    }

    func testVarIndexesIntoArraysViaNumericSegments() throws {
        let vars = Value.object([
            "items": .array([.string("first"), .string("second"), .string("third")])
        ])
        let (out, _) = try runVar(.string("items.1"), vars: vars)
        XCTAssertEqual(out, .string("second"))
    }

    func testVarMissingKeyReturnsNullAndWarns() throws {
        let vars = Value.object(["a": .int(1)])
        let (out, warnings) = try runVar(.string("missing_key"), vars: vars)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(warnings.count, 1)
        XCTAssertTrue(warnings[0].contains("missing_key"))
    }

    func testVarMissingDotPathReturnsNullAndWarns() throws {
        let vars = Value.object(["a": .object(["b": .int(1)])])
        let (out, warnings) = try runVar(.string("a.c"), vars: vars)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(warnings.count, 1)
        XCTAssertTrue(warnings[0].contains("a.c"))
    }

    func testVarMissingWithDefaultReturnsDefaultAndDoesNotWarn() throws {
        let vars = Value.object(["a": .int(1)])
        let logger = CapturingLogger()
        let result = try AccessorOperators.opVar(
            args: .array([.string("missing"), .string("fallback")]),
            vars: vars,
            logger: logger
        )
        XCTAssertEqual(result, .string("fallback"))
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testVarEmptyPathReturnsEntireData() throws {
        let vars = Value.object(["x": .int(1)])
        let (out, _) = try runVar(.string(""), vars: vars)
        XCTAssertEqual(out, vars)
    }

    func testVarWithNumericPathArgIsCoercedToString() throws {
        // {"var": 0} on array data
        let vars = Value.array([.string("zero"), .string("one")])
        let (out, _) = try runVar(.int(0), vars: vars)
        XCTAssertEqual(out, .string("zero"))
    }

    func testVarDoesNotApplyFlatKeyFallback() throws {
        // The literal key "a.b" exists in the flat map, but our spec-strict
        // lookup walks "a" then "b" and finds nothing. Documents the
        // deferred fallback behavior.
        let vars = Value.object(["a.b": .int(42)])
        let (out, warnings) = try runVar(.string("a.b"), vars: vars)
        XCTAssertEqual(out, .null)
        XCTAssertEqual(warnings.count, 1)
    }

    func testVarExtraArgsAreIgnoredWithWarning() throws {
        // Reference impls silently ignore extras; we surface a warning so it
        // doesn't become a silent bug. Path + default still resolve normally.
        let vars = Value.object(["a": .int(1)])
        let (out, warnings) = try runVar(
            .array([
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
        XCTAssertEqual(warnings.count, 1)
        XCTAssertTrue(warnings[0].contains("ignoring 2 extra"))
    }

    // MARK: - missing

    func testMissingReturnsKeysNotPresent() throws {
        let vars = Value.object(["a": .int(1), "b": .int(2)])
        let logger = CapturingLogger()
        let result = try AccessorOperators.opMissing(
            args: .array([.string("a"), .string("b"), .string("c")]),
            vars: vars,
            logger: logger
        )
        XCTAssertEqual(result, .array([.string("c")]))
        // `missing` itself does not warn (it's a check, not a read).
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testMissingReturnsEmptyArrayWhenAllPresent() throws {
        let vars = Value.object(["a": .int(1)])
        let logger = CapturingLogger()
        let result = try AccessorOperators.opMissing(
            args: .array([.string("a")]),
            vars: vars,
            logger: logger
        )
        XCTAssertEqual(result, .array([]))
    }

    func testMissingSupportsDotPathKeys() throws {
        let vars = Value.object(["user": .object(["name": .string("ada")])])
        let logger = CapturingLogger()
        let result = try AccessorOperators.opMissing(
            args: .array([.string("user.name"), .string("user.email")]),
            vars: vars,
            logger: logger
        )
        XCTAssertEqual(result, .array([.string("user.email")]))
    }

    func testMissingSingletonShorthandIsSupported() throws {
        let vars = Value.object([:])
        let logger = CapturingLogger()
        let result = try AccessorOperators.opMissing(
            args: .string("a"),
            vars: vars,
            logger: logger
        )
        XCTAssertEqual(result, .array([.string("a")]))
    }

    // MARK: - Helpers

    private func runVar(_ pathArg: Value, vars: Value) throws -> (Value, [String]) {
        let logger = CapturingLogger()
        let result = try AccessorOperators.opVar(args: pathArg, vars: vars, logger: logger)
        return (result, logger.warnings)
    }
}
