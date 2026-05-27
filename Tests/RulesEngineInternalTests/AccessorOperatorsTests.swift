//
//  AccessorOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

// swiftlint:disable type_body_length file_length

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

    /// Default applies only when lookup fails. A present key whose value is
    /// `null` is returned as-is — json-logic-js distinguishes `undefined`
    /// (missing) from an explicit `null` leaf.
    func testVarDefaultNotUsedWhenLeafIsNull() throws {
        let vars = Value.object(["key": .null])
        let out = try AccessorOperators.opVar(
            args: .array([.string("key"), .string("fallback")]),
            vars: vars
        )
        XCTAssertEqual(out, .null)
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    /// When descent hits a `null` parent, json-logic-js returns the default
    /// rather than attempting further segments.
    func testVarDefaultUsedWhenMidPathBreaksOnNull() throws {
        let vars = Value.object(["a": .null])
        let out = try AccessorOperators.opVar(
            args: .array([.string("a.b"), .string("fallback")]),
            vars: vars
        )
        XCTAssertEqual(out, .string("fallback"))
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testVarEmptyPathReturnsEntireData() throws {
        let vars = Value.object(["x": .int(1)])
        let out = try AccessorOperators.opVar(args: .string(""), vars: vars)
        XCTAssertEqual(out, vars)
    }

    /// json-logic-js treats `undefined`, `null`, and `""` as “return the
    /// whole data object”.
    func testVarNullPathReturnsEntireData() throws {
        let vars = Value.object(["x": .int(1)])
        let out = try AccessorOperators.opVar(args: .null, vars: vars)
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

    func testVarRecursivelyEvaluatesSingletonPathExpression() throws {
        // Per the JSON Logic spec, `{"var": <expr>}` recursively evaluates
        // <expr> and uses the result as the path. Here the inner `{"var":
        // "active_path_key"}` resolves to `"subscriber.country"`, which the
        // outer var then looks up.
        let vars = Value.object([
            "active_path_key": .string("subscriber.country"),
            "subscriber": .object(["country": .string("US")])
        ])
        let out = try AccessorOperators.opVar(
            args: .object(["var": .string("active_path_key")]),
            vars: vars
        )
        XCTAssertEqual(out, .string("US"))
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testVarRecursivelyEvaluatesArrayFormPathExpression() throws {
        // Array form: the path argument is itself an expression that
        // resolves dynamically. Mirrors the json-logic-js per-element
        // evaluation rule for array args.
        let vars = Value.object([
            "key_to_lookup": .string("nested.value"),
            "nested": .object(["value": .string("found")])
        ])
        let out = try AccessorOperators.opVar(
            args: .array([.object(["var": .string("key_to_lookup")])]),
            vars: vars
        )
        XCTAssertEqual(out, .string("found"))
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    func testVarRecursivelyEvaluatesArrayFormDefaultExpression() throws {
        // The default arg in the array form is also recursively evaluated,
        // so callers can express dynamic fallbacks like
        // `{"var": ["missing_key", {"var": "fallback_source"}]}`.
        let vars = Value.object(["fallback_source": .string("computed_default")])
        let out = try AccessorOperators.opVar(
            args: .array([
                .string("missing_key"),
                .object(["var": .string("fallback_source")])
            ]),
            vars: vars
        )
        XCTAssertEqual(out, .string("computed_default"))
        // No missing-variable warning: the default short-circuited the lookup.
        XCTAssertTrue(logger.warnings.isEmpty)
    }

    /// `json-logic-js` stringifies any non-primitive evaluated path
    /// via `String(value).split(".")`; for arrays that yields a
    /// comma-joined key (so `["x", "y"]` looks up the `"x,y"` field).
    /// The key isn't present here, so the lookup misses and `var`
    /// returns `.null`.
    func testVarSingletonExpressionResolvingToArrayStringifiesPath() throws {
        let out = try AccessorOperators.opVar(
            args: .object([
                "if": .array([
                    .bool(true),
                    .array([.string("x"), .string("y")]),
                    .string("z")
                ])
            ]),
            vars: .object(["x,y": .string("found")])
        )
        XCTAssertEqual(out, .string("found"))
    }

    /// Boolean paths follow the same `String(value).split(".")` rule,
    /// so `{"var": true}` looks up the `"true"` key.
    func testVarBooleanPathLooksUpStringifiedKey() throws {
        let out = try AccessorOperators.opVar(
            args: .bool(true),
            vars: .object(["true": .int(42)])
        )
        XCTAssertEqual(out, .int(42))
    }

    /// Object paths stringify to `"[object Object]"` and never match a
    /// real key, so `var` returns `.null` and warns.
    func testVarObjectPathStringifiesAndMisses() throws {
        let out = try AccessorOperators.opVar(
            args: .array([.object(["foo": .int(1), "bar": .int(2)])]),
            vars: .object(["x": .int(1)])
        )
        XCTAssertEqual(out, .null)
        XCTAssertEqual(logger.warnings.count, 1)
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

    func testMissingRecursivelyEvaluatesDynamicKeys() throws {
        // Per the JSON Logic spec, each key arg is recursively evaluated
        // before lookup. The inner `{"var": "key_name"}` resolves to
        // `"absent"`, which `missing` then checks against `vars`.
        let vars = Value.object([
            "key_name": .string("absent"),
            "present_only": .int(1)
        ])
        let result = try AccessorOperators.opMissing(
            args: .array([.object(["var": .string("key_name")])]),
            vars: vars
        )
        XCTAssertEqual(result, .array([.string("absent")]))
    }

    func testMissingUnpacksFirstArgWhenItResolvesToArray() throws {
        // Spec: if the first (possibly only) evaluated arg is itself an
        // array, treat its elements as the full key list. Here `if` returns
        // `["a", "c"]`, which `missing` unpacks before checking each key.
        let vars = Value.object(["a": .int(1)])
        let result = try AccessorOperators.opMissing(
            args: .object([
                "if": .array([
                    .bool(true),
                    .array([.string("a"), .string("c")]),
                    .array([])
                ])
            ]),
            vars: vars
        )
        XCTAssertEqual(result, .array([.string("c")]))
    }

    func testMissingReportsKeyWhoseLeafValueIsNull() throws {
        // json-logic-js routes `missing` through `var`, which returns the
        // actual `null` leaf value, then matches `value === null`. So a
        // present-but-null key is reported as missing — a backend payload
        // with explicitly cleared fields (`{"country": null}`) should still
        // hit the `{"missing": ["country"]}` branch.
        let vars = Value.object(["a": .null, "b": .int(1)])
        let result = try AccessorOperators.opMissing(
            args: .array([.string("a"), .string("b")]),
            vars: vars
        )
        XCTAssertEqual(result, .array([.string("a")]))
    }

    func testMissingReportsKeyWhoseLeafValueIsEmptyString() throws {
        // Spec parity: `value === ""` also counts as missing (mirrors how
        // form / API payloads treat empty fields as unset).
        let vars = Value.object([
            "a": .string(""),
            "b": .string("x")
        ])
        let result = try AccessorOperators.opMissing(
            args: .array([.string("a"), .string("b")]),
            vars: vars
        )
        XCTAssertEqual(result, .array([.string("a")]))
    }

    func testMissingDoesNotReportKeysWithFalsyNonEmptyValues() throws {
        // Pinning the negative side of the spec: only `null` and `""` qualify.
        // `0`, `false`, `[]`, `{}` are present-and-defined, hence not missing.
        let vars = Value.object([
            "zero": .int(0),
            "false_val": .bool(false),
            "empty_array": .array([]),
            "empty_object": .object([:]),
            "zero_string": .string("0")
        ])
        let result = try AccessorOperators.opMissing(
            args: .array([
                .string("zero"),
                .string("false_val"),
                .string("empty_array"),
                .string("empty_object"),
                .string("zero_string")
            ]),
            vars: vars
        )
        XCTAssertEqual(result, .array([]))
    }

    func testMissingReportsDotPathLeafThatIsNull() throws {
        // Same null-leaf rule applies through dot-paths: an existing
        // nested key whose leaf is null counts as missing.
        let vars = Value.object([
            "user": .object([
                "name": .null,
                "email": .string("a@b.com")
            ])
        ])
        let result = try AccessorOperators.opMissing(
            args: .array([.string("user.name"), .string("user.email")]),
            vars: vars
        )
        XCTAssertEqual(result, .array([.string("user.name")]))
    }
}
