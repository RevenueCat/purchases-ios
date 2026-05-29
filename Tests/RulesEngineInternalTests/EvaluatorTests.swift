//
//  EvaluatorTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class EvaluatorTests: XCTestCase {

    // MARK: - Literal predicates

    func testLiteralTrueIsTruthy() throws {
        XCTAssertTrue(try run("true"))
        XCTAssertTrue(try run("1"))
        XCTAssertTrue(try run("\"hello\""))
    }

    func testLiteralFalseIsFalsy() throws {
        XCTAssertFalse(try run("false"))
        XCTAssertFalse(try run("0"))
        XCTAssertFalse(try run("\"\""))
        XCTAssertFalse(try run("null"))
    }

    // MARK: - Composite predicate integration

    func testCompositePredicateEvaluatesCorrectly() throws {
        let predicate = """
            {
                "and": [
                    {"==": [{"var": "subscriber.last_seen_country"}, "US"]},
                    {"==": [{"var": "session.app_launch_count"}, 3]}
                ]
            }
            """
        let vars = [
            "subscriber": Value.object(["last_seen_country": .string("US")]),
            "session": Value.object(["app_launch_count": .int(3)])
        ]
        XCTAssertTrue(try run(predicate, vars: vars))
    }

    func testCompositePredicateEvaluatesToFalseWhenCountryDiffers() throws {
        let predicate = """
            {
                "and": [
                    {"==": [{"var": "subscriber.last_seen_country"}, "US"]},
                    {"==": [{"var": "session.app_launch_count"}, 3]}
                ]
            }
            """
        let vars = [
            "subscriber": Value.object(["last_seen_country": .string("CA")]),
            "session": Value.object(["app_launch_count": .int(3)])
        ]
        XCTAssertFalse(try run(predicate, vars: vars))
    }

    // MARK: - Nested expressions

    func testNestedOrWithinAnd() throws {
        // (country in {"US","CA"}) AND (count == 3)
        // Without an `in` operator yet, model as:
        // (country == "US" OR country == "CA") AND ...
        let predicate = """
            {
                "and": [
                    {"or": [
                        {"==": [{"var": "country"}, "US"]},
                        {"==": [{"var": "country"}, "CA"]}
                    ]},
                    {"==": [{"var": "count"}, 3]}
                ]
            }
            """
        XCTAssertTrue(
            try run(predicate, vars: ["country": .string("CA"), "count": .int(3)])
        )
        XCTAssertFalse(
            try run(predicate, vars: ["country": .string("MX"), "count": .int(3)])
        )
    }

    func testIfChoosesBranchBasedOnVar() throws {
        // `true` / `false` literal branches so the assertion can distinguish
        // which branch was taken (string branches would both be truthy).
        let predicate = """
            {
                "if": [
                    {"==": [{"var": "tier"}, "premium"]},
                    true,
                    false
                ]
            }
            """
        XCTAssertTrue(try run(predicate, vars: ["tier": .string("premium")]))
        XCTAssertFalse(try run(predicate, vars: ["tier": .string("free")]))
    }

    func testAndReturnsLastTruthyValueNotBooleanSoOrderMatters() throws {
        // `{"and": [a, b, c]}` returns the last truthy value, not a coerced
        // bool. A regression that started bool-coercing would make the
        // strict-eq comparison flip and we'd catch it here.
        let predicate = """
            {"===": [
                {"and": ["premium", 5, true]},
                {"and": [true, 5, "premium"]}
            ]}
            """
        // Left AND returns `true` (last); right AND returns `"premium"`.
        // `true === "premium"` is false.
        XCTAssertFalse(try run(predicate))
    }

    func testIfBranchValueFlowsIntoOuterPredicate() throws {
        // The inner `if` returns the string "premium" or "free", which the
        // outer `==` compares. If the engine were coercing the `if` result
        // to a bool too eagerly, both branches would equal `true` and the
        // comparison would never distinguish them.
        let predicate = """
            {
                "and": [
                    {"==": [{"var": "active"}, true]},
                    {"==": [
                        {"if": [{"var": "is_paid"}, "premium", "free"]},
                        "premium"
                    ]}
                ]
            }
            """
        XCTAssertTrue(
            try run(
                predicate,
                vars: ["active": .bool(true), "is_paid": .bool(true)]
            )
        )
        // is_paid=false → if returns "free" → "free" != "premium" → AND is false
        XCTAssertFalse(
            try run(
                predicate,
                vars: ["active": .bool(true), "is_paid": .bool(false)]
            )
        )
    }

    // MARK: - Missing-variable behavior

    func testMissingVariableResolvesToNullAndWarns() throws {
        // {"==": [{"var": "missing"}, null]} should be true when the var is
        // missing, since missing → null and null == null.
        let predicate = "{\"==\": [{\"var\": \"missing\"}, null]}"
        let logger = CapturingLogger()
        let previousLogger = RulesEngine.logger
        RulesEngine.setLogger(logger)
        defer { RulesEngine.setLogger(previousLogger) }

        let result = try Evaluator.evaluate(
            predicate: try Value.fromJSONString(predicate),
            variables: [:]
        )
        XCTAssertTrue(result)
        XCTAssertEqual(logger.warnings.count, 1)
        XCTAssertTrue(logger.warnings[0].contains("missing"))
    }

    // MARK: - Error paths

    func testUnsupportedOperatorSurfacesError() throws {
        let predicate = try Value.fromJSONString("{\"someUnknownOp\": [1, 2]}")
        XCTAssertThrowsError(
            try Evaluator.evaluate(predicate: predicate, variables: [:])
        ) { error in
            guard case RuleError.unsupportedOperator = error else {
                return XCTFail("expected RuleError.unsupportedOperator, got \(error)")
            }
        }
    }

    func testMalformedJSONSurfacesParseError() {
        // Parse errors now surface from the test-only JSON helper (production
        // callers parse on the native side and never hand `evaluate` a
        // malformed tree). The error case is still `RuleError.parse`.
        XCTAssertThrowsError(try Value.fromJSONString("{not json")) { error in
            guard case RuleError.parse = error else {
                return XCTFail("expected RuleError.parse, got \(error)")
            }
        }
    }

    /// `json-logic-js` declares binary operators (`==`, `===`, `!=`,
    /// `!==`, `in`, etc.) as `function(a, b)`, so a missing second
    /// operand stands in for JS `undefined`. The loose-equality path
    /// then matches our `null` ↔ `undefined` behavior and returns
    /// `false` for `1 == undefined`.
    func testBinaryOperatorMissingOperandComparesAgainstNull() throws {
        let predicate = try Value.fromJSONString("{\"==\": [1]}")
        let result = try Evaluator.evaluate(predicate: predicate, variables: [:])
        XCTAssertEqual(result, false)
    }

    // MARK: - Arithmetic dispatched through evaluator

    func testArithmeticPredicateWithVarOperand() throws {
        // session.app_launch_count * 2 == 6 → true when count is 3
        let predicate = """
            {"==": [
                {"*": [{"var": "session.app_launch_count"}, 2]},
                6
            ]}
            """
        let vars = ["session": Value.object(["app_launch_count": .int(3)])]
        XCTAssertTrue(try run(predicate, vars: vars))
    }

    /// `n / 0` follows IEEE 754 (matches `json-logic-js`, no
    /// short-circuit). `{"/": [10, 0]}` → `+Infinity` → truthy;
    /// `{"/": [0, 0]}` → `NaN` → falsy.
    func testDivideByZeroProducesIeee754ValuesThatFlowThroughTruthiness() throws {
        XCTAssertTrue(try run("{\"/\": [10, 0]}"))
        XCTAssertFalse(try run("{\"/\": [0, 0]}"))
    }

    // MARK: - Multi-key object treated as data, not operator

    func testMultiKeyObjectIsLiteralDataValue() throws {
        // Mirrors json-logic-js's `is_logic`, which only treats an object
        // as an operator when `Object.keys(logic).length === 1`. A two-key
        // object falls back to `apply`'s "not logic, return as-is" branch
        // and reaches `==` as a literal data value. JS abstract equality
        // then uses reference identity for the two objects → `false`.
        let predicateEq = """
            {"==": [
                {"a": 1, "b": 2},
                {"a": 1, "b": 2}
            ]}
            """
        XCTAssertFalse(try run(predicateEq))

        // Symmetric `!=`: distinct object references are unequal, so
        // the inequality holds.
        let predicateNe = """
            {"!=": [
                {"a": 1, "b": 2},
                {"a": 1, "b": 2}
            ]}
            """
        XCTAssertTrue(try run(predicateNe))
    }

    func testSingleKeyObjectOperandIsDispatchedAsOperator() throws {
        // Pins the contrast with `testMultiKeyObjectIsLiteralDataValue`:
        // single-key objects flow through `Evaluator.evaluateValue` like
        // any other expression and get dispatched as operators (the
        // `is_logic` → `apply` path in json-logic-js). An unknown op name
        // surfaces as `RuleError.unsupportedOperator`, mirroring the JS
        // reference's `Unrecognized operation a` throw.
        let predicate = #"{"==": [{"a": 1}, {"a": 1}]}"#
        XCTAssertThrowsError(try run(predicate)) { error in
            guard case RuleError.unsupportedOperator(let name) = error else {
                return XCTFail("expected RuleError.unsupportedOperator, got \(error)")
            }
            XCTAssertEqual(name, "a")
        }
    }

    // MARK: - Equality with JS-style array/object coercion

    func testLooseEqualityCoercesArrayToJSStringEndToEnd() throws {
        // Pins the spec-aligned coercion path (Array.prototype.toString)
        // through the full evaluator, not just the looseEq helper:
        // `{"==": [[1, 2], "1,2"]}` → true, mirroring json-logic-js.
        XCTAssertTrue(try run(#"{"==": [[1, 2], "1,2"]}"#))
        // Numeric fallback after ToPrimitive: `[1] == 1`.
        XCTAssertTrue(try run(#"{"==": [[1], 1]}"#))
        // Empty array stringifies to "" which numerically coerces to 0.
        XCTAssertTrue(try run(#"{"==": [[], 0]}"#))
    }

    func testLooseEqualityCoercesObjectToJSStringEndToEnd() throws {
        // A multi-key object (so it isn't dispatched as an operator)
        // coerces to "[object Object]" against a string operand. Pins
        // the rare-but-real case where a payload field gets accidentally
        // serialized through `String(value)` upstream.
        let predicate = """
            {"==": [
                {"a": 1, "b": 2},
                "[object Object]"
            ]}
            """
        XCTAssertTrue(try run(predicate))
    }

    // MARK: - Literal predicate truthiness

    func testLiteralEmptyArrayPredicateIsFalsy() throws {
        XCTAssertFalse(try run("[]"))
    }

    func testLiteralNonEmptyArrayPredicateIsTruthyEvenWithFalsyElements() throws {
        // Per http://jsonlogic.com/truthy — non-empty arrays are truthy
        // regardless of element values.
        XCTAssertTrue(try run("[false]"))
        XCTAssertTrue(try run("[0]"))
    }

    func testLiteralObjectPredicateIsTruthyEvenWithFalsyValues() throws {
        // Multi-key objects are literal data (not operator dispatch) and
        // objects are always truthy in JSON Logic.
        XCTAssertTrue(try run(#"{"a": false, "b": 0}"#))
    }

    // MARK: - Helpers

    private func run(_ predicateJSON: String, vars: [String: Value] = [:]) throws -> Bool {
        let predicate = try Value.fromJSONString(predicateJSON)
        return try Evaluator.evaluate(predicate: predicate, variables: vars)
    }
}
