//
//  EvaluatorTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@_spi(Internal) @testable import RulesEngine

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

    func testDivideByZeroReturnsNullWhichIsFalsy() throws {
        // {"/": [10, 0]} → null → predicate is falsy
        let predicate = "{\"/\": [10, 0]}"
        XCTAssertFalse(try run(predicate))
    }

    // MARK: - Multi-key object treated as data, not operator

    func testMultiKeyObjectIsLiteralDataValue() throws {
        // An object literal with two keys isn't an operator.
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

    // MARK: - Helpers

    private func run(_ predicateJSON: String, vars: [String: Value] = [:]) throws -> Bool {
        let predicate = try Value.fromJSONString(predicateJSON)
        return try Evaluator.evaluate(predicate: predicate, variables: vars)
    }
}
