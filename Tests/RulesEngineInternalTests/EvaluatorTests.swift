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
        let result = try Rules.withLogger(logger) {
            try Evaluator.evaluate(
                predicate: try Value.fromJSONString(predicate),
                variables: [:]
            )
        }
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

    func testArityErrorOnBinaryOperatorSurfacesTypeMismatch() throws {
        let predicate = try Value.fromJSONString("{\"==\": [1]}")
        XCTAssertThrowsError(
            try Evaluator.evaluate(predicate: predicate, variables: [:])
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected RuleError.typeMismatch, got \(error)")
            }
        }
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
    /// `{"/": [0, 0]}` → `NaN` → falsy (NaN is the one float that
    /// `isTruthy` reports as `false`).
    func testDivideByZeroProducesIeee754ValuesThatFlowThroughTruthiness() throws {
        XCTAssertTrue(try run("{\"/\": [10, 0]}"))
        XCTAssertFalse(try run("{\"/\": [0, 0]}"))
    }

    // MARK: - Comparison dispatched through evaluator

    func testComparisonPredicateWithVarOperand() throws {
        // session.app_launch_count >= 3 → true when count is 3
        let predicate = "{\">=\": [{\"var\": \"session.app_launch_count\"}, 3]}"
        let vars = ["session": Value.object(["app_launch_count": .int(3)])]
        XCTAssertTrue(try run(predicate, vars: vars))
    }

    func testBetweenFormWithVarOperand() throws {
        // 1 <= session.app_launch_count <= 10 → true when count is 5
        let predicate = "{\"<=\": [1, {\"var\": \"session.app_launch_count\"}, 10]}"
        let vars = ["session": Value.object(["app_launch_count": .int(5)])]
        XCTAssertTrue(try run(predicate, vars: vars))
    }

    // MARK: - String + array operators (integration through dispatch)

    func testInOperatorAgainstArrayWithVarNeedle() throws {
        // {"in": [{"var": "country"}, ["US", "CA", "MX"]]}
        let predicate = """
            {"in": [
                {"var": "country"},
                ["US", "CA", "MX"]
            ]}
            """
        XCTAssertTrue(try run(predicate, vars: ["country": .string("CA")]))
        XCTAssertFalse(try run(predicate, vars: ["country": .string("FR")]))
    }

    func testMissingSomeInsideIfGatesRequiredData() throws {
        // Pattern: "the rule needs at least 2 of these 3 fields populated".
        // We use it as a guard: if the data is insufficient, fall back to a
        // literal `false`; otherwise the inner check runs.
        let predicate = """
            {
                "if": [
                    {"!!": {"missing_some": [2, ["a", "b", "c"]]}},
                    false,
                    {"==": [{"var": "a"}, 1]}
                ]
            }
            """
        // Two of three fields → data sufficient → inner check runs (a == 1 → true).
        XCTAssertTrue(try run(predicate, vars: ["a": .int(1), "b": .int(2)]))
        // Only one field → data insufficient → falls back to false.
        XCTAssertFalse(try run(predicate, vars: ["a": .int(1)]))
    }

    // MARK: - Multi-key object treated as data, not operator

    func testMultiKeyObjectIsLiteralDataValue() throws {
        // Mirrors json-logic-js's `is_logic`, which only treats an object
        // as an operator when `Object.keys(logic).length === 1`. A two-key
        // object falls back to `apply`'s "not logic, return as-is" branch,
        // i.e. literal data — so two structurally-equal multi-key objects
        // compare equal under our structural `looseEq`.
        let predicateEq = """
            {"==": [
                {"a": 1, "b": 2},
                {"a": 1, "b": 2}
            ]}
            """
        XCTAssertTrue(try run(predicateEq))

        // Same two literals through `!=` should evaluate to false (they are
        // equal as data, so the inequality is unsatisfied). Confirms the
        // literal-vs-operator handling is symmetric across operators.
        let predicateNe = """
            {"!=": [
                {"a": 1, "b": 2},
                {"a": 1, "b": 2}
            ]}
            """
        XCTAssertFalse(try run(predicateNe))
    }

    func testSingleKeyObjectOperandIsDispatchedAsOperator() throws {
        // Pins the contrast with `testMultiKeyObjectIsLiteralDataValue`:
        // single-key objects flow through `Evaluator.evaluateValue` like
        // any other expression and get dispatched as operators (the
        // `is_logic` → `apply` path in json-logic-js). An unknown op name
        // surfaces as `RuleError.unsupportedOperator`, mirroring the JS
        // reference's `Unrecognized operation a` throw — so even though
        // the multi-key case `{a:1,b:2} == {a:1,b:2}` returns `true` in
        // our engine and `false` in JS (deliberate structural-vs-reference
        // divergence), the literal `{a:1} == {a:1}` does NOT diverge: both
        // engines fail to evaluate it.
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

    // MARK: - Helpers

    private func run(_ predicateJSON: String, vars: [String: Value] = [:]) throws -> Bool {
        let predicate = try Value.fromJSONString(predicateJSON)
        return try Evaluator.evaluate(predicate: predicate, variables: vars)
    }
}
