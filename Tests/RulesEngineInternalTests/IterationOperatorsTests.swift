//
//  IterationOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

// swiftlint:disable type_body_length file_length
final class IterationOperatorsTests: XCTestCase {

    // MARK: - some

    func testSomeReturnsTrueWhenAtLeastOneItemMatches() throws {
        let out = try IterationOperators.opSome(
            args: arr(
                arr(.int(1), .int(2), .int(3)),
                gtZero
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testSomeReturnsFalseWhenNoItemMatches() throws {
        let out = try IterationOperators.opSome(
            args: arr(
                arr(.int(-1), .int(-2), .int(-3)),
                gtZero
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testSomeReturnsFalseForEmptyArray() throws {
        let out = try IterationOperators.opSome(
            args: arr(.array([]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testSomeReturnsFalseForNullSource() throws {
        let out = try IterationOperators.opSome(
            args: arr(.null, gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testSomeReturnsFalseForObjectSource() throws {
        // Multi-key objects are returned by the evaluator as literal data
        // (single-key objects would be dispatched as an operator, never
        // reaching the array check here).
        let out = try IterationOperators.opSome(
            args: arr(.object(["foo": .int(1), "bar": .int(2)]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testSomeReturnsFalseForStringSource() throws {
        let out = try IterationOperators.opSome(
            args: arr(.string("abc"), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testSomePredicateSeesCurrentItemViaEmptyVar() throws {
        // `{"var": ""}` resolves to the current item.
        let out = try IterationOperators.opSome(
            args: arr(
                arr(.bool(false), .bool(true), .bool(false)),
                .object(["var": .string("")])
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testSomePredicateAccessesItemFields() throws {
        // Item objects are routed through `vars` so the evaluator does
        // not try to dispatch their single key (`status`) as an operator.
        let out = try IterationOperators.opSome(
            args: arr(
                .object(["var": .string("items")]),
                statusEqualsActive
            ),
            vars: .object([
                "items": arr(
                    .object(["status": .string("expired")]),
                    .object(["status": .string("active")])
                )
            ])
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testSomeArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try IterationOperators.opSome(
                args: arr(.array([])),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                XCTFail("expected typeMismatch, got \(error)")
                return
            }
        }
    }

    // MARK: - all

    func testAllReturnsTrueWhenEveryItemMatches() throws {
        let out = try IterationOperators.opAll(
            args: arr(
                arr(.int(1), .int(2), .int(3)),
                gtZero
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testAllReturnsFalseOnFirstFailure() throws {
        let out = try IterationOperators.opAll(
            args: arr(
                arr(.int(1), .int(2), .int(-3)),
                gtZero
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    /// Pinned spec quirk: json-logic-js returns `false` (not vacuous
    /// truth) for `all` over an empty array. The Python `json-logic`
    /// library agrees. The RevenueCat backend (`khepri`) currently
    /// returns `true` for this case; see the doc comment on
    /// `IterationOperators` for why we follow the spec instead.
    func testAllReturnsFalseForEmptyArrayPerJsonLogicSpec() throws {
        let out = try IterationOperators.opAll(
            args: arr(.array([]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testAllReturnsFalseForNullSource() throws {
        let out = try IterationOperators.opAll(
            args: arr(.null, gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testAllReturnsFalseForObjectSource() throws {
        let out = try IterationOperators.opAll(
            args: arr(.object(["foo": .int(1), "bar": .int(2)]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testAllReturnsFalseForStringSource() throws {
        let out = try IterationOperators.opAll(
            args: arr(.string("abc"), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testAllPredicateSeesCurrentItemViaEmptyVar() throws {
        let out = try IterationOperators.opAll(
            args: arr(
                arr(.bool(true), .bool(true), .bool(true)),
                .object(["var": .string("")])
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testAllArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try IterationOperators.opAll(
                args: arr(.array([]), gtZero, .int(1)),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                XCTFail("expected typeMismatch, got \(error)")
                return
            }
        }
    }

    // MARK: - Scope semantics

    /// Inside the predicate, only the current item is visible — the
    /// outer scope is not reachable. Mirrors the JSON Logic JS reference,
    /// which replaces `data` wholesale when iterating.
    func testPredicateCannotReachParentScope() throws {
        // Outer scope has `x = "outer"`. Items don't have `x`, so
        // `{"var": "x"}` inside the predicate resolves to `.null` (not
        // `"outer"`). The equality check is false for every item, so
        // `some` returns false.
        let out = try IterationOperators.opSome(
            args: arr(
                arr(.object([:]), .object([:])),
                .object(["==": arr(.object(["var": .string("x")]), .string("outer"))])
            ),
            vars: .object(["x": .string("outer")])
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testNestedSomeInsideAllReboundsItemScope() throws {
        // For every customer, at least one of their products must be
        // active. Both customers satisfy → all true. Data lives in
        // `vars` so the evaluator does not dispatch the customers'
        // single keys (`products`) or the products' single key
        // (`status`) as operators.
        let predicate = Value.object([
            "some": arr(
                .object(["var": .string("products")]),
                statusEqualsActive
            )
        ])
        let out = try IterationOperators.opAll(
            args: arr(.object(["var": .string("customers")]), predicate),
            vars: .object([
                "customers": arr(
                    .object([
                        "products": arr(
                            .object(["status": .string("expired")]),
                            .object(["status": .string("active")])
                        )
                    ]),
                    .object([
                        "products": arr(
                            .object(["status": .string("active")])
                        )
                    ])
                )
            ])
        )
        XCTAssertEqual(out, .bool(true))
    }

    // MARK: - Khepri fixture mirrors

    /// Copied verbatim from `khepri/some_active_subscription/matching`
    /// in `predicate_conformance_v1.json`. Pins parity with the backend
    /// oracle on a spec-aligned case.
    func testKhepriSomeActiveSubscriptionMatching() throws {
        let predicate = Value.object([
            "some": arr(
                .object(["var": .string("subscriptions")]),
                statusEqualsActive
            )
        ])
        let vars = Value.object([
            "subscriptions": arr(
                .object(["status": .string("active")]),
                .object(["status": .string("active")]),
                .object(["status": .string("trialing")])
            )
        ])
        XCTAssertEqual(try Evaluator.evaluateValue(predicate, vars: vars), .bool(true))
    }

    /// Copied verbatim from `khepri/some_active_subscription/non_matching`.
    func testKhepriSomeActiveSubscriptionNonMatching() throws {
        let predicate = Value.object([
            "some": arr(
                .object(["var": .string("subscriptions")]),
                statusEqualsActive
            )
        ])
        let vars = Value.object([
            "subscriptions": arr(
                .object(["status": .string("expired")]),
                .object(["status": .string("expired")]),
                .object(["status": .string("expired")])
            )
        ])
        XCTAssertEqual(try Evaluator.evaluateValue(predicate, vars: vars), .bool(false))
    }

    /// Copied verbatim from `khepri/all_subscriptions_active/matching`.
    func testKhepriAllSubscriptionsActiveMatching() throws {
        let predicate = Value.object([
            "all": arr(
                .object(["var": .string("subscriptions")]),
                statusEqualsActive
            )
        ])
        let vars = Value.object([
            "subscriptions": arr(
                .object(["status": .string("active")]),
                .object(["status": .string("active")])
            )
        ])
        XCTAssertEqual(try Evaluator.evaluateValue(predicate, vars: vars), .bool(true))
    }

    /// Copied verbatim from `khepri/all_subscriptions_active/non_matching`.
    func testKhepriAllSubscriptionsActiveNonMatching() throws {
        let predicate = Value.object([
            "all": arr(
                .object(["var": .string("subscriptions")]),
                statusEqualsActive
            )
        ])
        let vars = Value.object([
            "subscriptions": arr(
                .object(["status": .string("active")]),
                .object(["status": .string("active")]),
                .object(["status": .string("trialing")])
            )
        ])
        XCTAssertEqual(try Evaluator.evaluateValue(predicate, vars: vars), .bool(false))
    }

    // MARK: - none

    func testNoneReturnsTrueWhenNoItemMatches() throws {
        let out = try IterationOperators.opNone(
            args: arr(arr(.int(-1), .int(-2), .int(-3)), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testNoneReturnsFalseOnFirstMatch() throws {
        let out = try IterationOperators.opNone(
            args: arr(arr(.int(-1), .int(2), .int(-3)), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testNoneReturnsTrueForEmptyArray() throws {
        let out = try IterationOperators.opNone(
            args: arr(.array([]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    /// Pinned spec quirk: `none` returns `true` for a non-array source,
    /// even though `some`/`all` return `false`. This is because the JS
    /// reference defines `none` in terms of `filter`, which itself yields
    /// `[]` for non-arrays — and `[].length === 0` is `true`.
    func testNoneReturnsTrueForNullSourcePerJsonLogicSpec() throws {
        let out = try IterationOperators.opNone(
            args: arr(.null, gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testNoneReturnsTrueForObjectSourcePerJsonLogicSpec() throws {
        let out = try IterationOperators.opNone(
            args: arr(.object(["foo": .int(1), "bar": .int(2)]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testNoneReturnsTrueForStringSourcePerJsonLogicSpec() throws {
        let out = try IterationOperators.opNone(
            args: arr(.string("abc"), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testNonePredicateSeesCurrentItemViaEmptyVar() throws {
        let out = try IterationOperators.opNone(
            args: arr(
                arr(.bool(false), .bool(false), .bool(false)),
                .object(["var": .string("")])
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testNoneArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try IterationOperators.opNone(
                args: arr(.array([])),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                XCTFail("expected typeMismatch, got \(error)")
                return
            }
        }
    }

    // MARK: - map

    func testMapAppliesPredicateToEachItem() throws {
        // {"map": [[1, 2, 3], {"*": [{"var": ""}, 2]}]} → [2, 4, 6]
        // Arithmetic widens to `.float` (mirrors ArithmeticOperators.opMul);
        // the test pins the values, not the integer/float split.
        let out = try IterationOperators.opMap(
            args: arr(
                arr(.int(1), .int(2), .int(3)),
                .object(["*": arr(.object(["var": .string("")]), .int(2))])
            ),
            vars: .null
        )
        XCTAssertEqual(out, .array([.float(2), .float(4), .float(6)]))
    }

    func testMapPreservesEmptyArray() throws {
        let out = try IterationOperators.opMap(
            args: arr(.array([]), .object(["var": .string("")])),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    func testMapReturnsEmptyArrayForNullSource() throws {
        let out = try IterationOperators.opMap(
            args: arr(.null, .object(["var": .string("")])),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    func testMapReturnsEmptyArrayForObjectSource() throws {
        let out = try IterationOperators.opMap(
            args: arr(.object(["foo": .int(1), "bar": .int(2)]), .object(["var": .string("")])),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    func testMapReturnsEmptyArrayForStringSource() throws {
        let out = try IterationOperators.opMap(
            args: arr(.string("abc"), .object(["var": .string("")])),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    /// `map` returns the raw predicate result, not a truthy-coerced bool.
    /// Pinned so a future regression can't accidentally collapse the
    /// result type. Item objects are routed through `vars` so the
    /// evaluator does not try to dispatch their single key (`x`) as an
    /// operator.
    func testMapReturnsRawNonBooleanResults() throws {
        let out = try IterationOperators.opMap(
            args: arr(
                .object(["var": .string("items")]),
                .object(["var": .string("x")])
            ),
            vars: .object([
                "items": arr(.object(["x": .int(10)]), .object(["x": .int(20)]))
            ])
        )
        XCTAssertEqual(out, .array([.int(10), .int(20)]))
    }

    func testMapArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try IterationOperators.opMap(
                args: arr(.array([])),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                XCTFail("expected typeMismatch, got \(error)")
                return
            }
        }
    }

    // MARK: - filter

    func testFilterRetainsItemsWherePredicateIsTruthy() throws {
        let out = try IterationOperators.opFilter(
            args: arr(arr(.int(-1), .int(2), .int(-3), .int(4)), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .array([.int(2), .int(4)]))
    }

    /// `filter` retains the *original* item, not the predicate result.
    /// Locks the spec contract — easy to accidentally regress to "return
    /// the predicate result if truthy". Item objects are routed through
    /// `vars` so the evaluator does not try to dispatch their single key
    /// (`x`) as an operator.
    func testFilterRetainsOriginalItemsNotPredicateResults() throws {
        let out = try IterationOperators.opFilter(
            args: arr(
                .object(["var": .string("items")]),
                .object(["var": .string("x")])
            ),
            vars: .object([
                "items": arr(
                    .object(["x": .int(1)]),
                    .object(["x": .int(0)]),
                    .object(["x": .int(2)])
                )
            ])
        )
        XCTAssertEqual(
            out,
            .array([.object(["x": .int(1)]), .object(["x": .int(2)])])
        )
    }

    func testFilterPreservesEmptyArray() throws {
        let out = try IterationOperators.opFilter(
            args: arr(.array([]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    func testFilterReturnsEmptyArrayForNullSource() throws {
        let out = try IterationOperators.opFilter(
            args: arr(.null, gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    func testFilterReturnsEmptyArrayForObjectSource() throws {
        // Multi-key object so the evaluator treats it as literal data
        // rather than dispatching the single key as an operator.
        let out = try IterationOperators.opFilter(
            args: arr(.object(["foo": .int(1), "bar": .int(2)]), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    func testFilterReturnsEmptyArrayForStringSource() throws {
        let out = try IterationOperators.opFilter(
            args: arr(.string("abc"), gtZero),
            vars: .null
        )
        XCTAssertEqual(out, .array([]))
    }

    func testFilterArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try IterationOperators.opFilter(
                args: arr(.array([])),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                XCTFail("expected typeMismatch, got \(error)")
                return
            }
        }
    }

    // MARK: - reduce

    /// Canonical sum example from the json-logic-js README.
    func testReduceSumsArray() throws {
        // {"reduce": [[1, 2, 3, 4], {"+": [current, accumulator]}, 0]} → 10
        let out = try IterationOperators.opReduce(
            args: arr(
                arr(.int(1), .int(2), .int(3), .int(4)),
                addCurrentAndAccumulator,
                .int(0)
            ),
            vars: .null
        )
        XCTAssertEqual(out.asNumber, 10)
    }

    func testReduceReturnsInitialAccumulatorForEmptyArray() throws {
        let out = try IterationOperators.opReduce(
            args: arr(.array([]), addCurrentAndAccumulator, .int(7)),
            vars: .null
        )
        XCTAssertEqual(out, .int(7))
    }

    func testReduceReturnsInitialAccumulatorForNullSource() throws {
        let out = try IterationOperators.opReduce(
            args: arr(.null, addCurrentAndAccumulator, .int(7)),
            vars: .null
        )
        XCTAssertEqual(out, .int(7))
    }

    func testReduceReturnsInitialAccumulatorForObjectSource() throws {
        // Multi-key object so the evaluator treats it as literal data
        // rather than dispatching the single key as an operator.
        let out = try IterationOperators.opReduce(
            args: arr(
                .object(["foo": .int(1), "bar": .int(2)]),
                addCurrentAndAccumulator,
                .int(7)
            ),
            vars: .null
        )
        XCTAssertEqual(out, .int(7))
    }

    func testReduceReturnsInitialAccumulatorForStringSource() throws {
        let out = try IterationOperators.opReduce(
            args: arr(.string("abc"), addCurrentAndAccumulator, .int(7)),
            vars: .null
        )
        XCTAssertEqual(out, .int(7))
    }

    /// The initial accumulator is itself an expression evaluated in the
    /// outer scope. Pins that the third argument is not treated as a
    /// literal template.
    func testReduceEvaluatesInitialAccumulatorInOuterScope() throws {
        // initial = {"var": "seed"} (resolved to 100 from outer vars)
        // result = 100 + 1 + 2 = 103
        let out = try IterationOperators.opReduce(
            args: arr(
                arr(.int(1), .int(2)),
                addCurrentAndAccumulator,
                .object(["var": .string("seed")])
            ),
            vars: .object(["seed": .int(100)])
        )
        XCTAssertEqual(out.asNumber, 103)
    }

    /// The source array is also evaluated in the outer scope. Pins that
    /// the first argument can be an expression, not just a literal array.
    func testReduceEvaluatesSourceInOuterScope() throws {
        let out = try IterationOperators.opReduce(
            args: arr(
                .object(["var": .string("nums")]),
                addCurrentAndAccumulator,
                .int(0)
            ),
            vars: .object(["nums": arr(.int(1), .int(2), .int(3))])
        )
        XCTAssertEqual(out.asNumber, 6)
    }

    /// The predicate sees `{"current": item, "accumulator": acc}` as the
    /// *entire* scope — not the item itself. Outer-scope variables are
    /// not visible.
    func testReducePredicateScopeIsCurrentAndAccumulatorOnly() throws {
        // Outer has `bonus = 1000`, which the predicate would pick up if
        // the accumulator scope leaked the parent. The predicate adds
        // `current + accumulator` only, so the result must be 1+2+3 = 6
        // — not 1000-shifted.
        let out = try IterationOperators.opReduce(
            args: arr(
                arr(.int(1), .int(2), .int(3)),
                addCurrentAndAccumulator,
                .int(0)
            ),
            vars: .object(["bonus": .int(1000)])
        )
        XCTAssertEqual(out.asNumber, 6)
    }

    /// A `var` lookup against a nonexistent key in the reduce scope
    /// resolves to `null`, not the parent scope's value of that key.
    func testReducePredicateCannotReachParentScope() throws {
        // Outer has `multiplier = 10`. Predicate references {"var":
        // "multiplier"}, which lives only in the outer scope. The reducer
        // rebinds `vars` to `{current, accumulator}` with no parent
        // fallback, so the lookup resolves to `.null`. We verify that by
        // comparing `multiplier === null` inside the predicate and using
        // the result to decide what to emit — keeping the assertion
        // independent of how `null` coerces in arithmetic (which under
        // the json-logic-js spec is `parseFloat("null")` → `NaN` for
        // `+` / `*`).
        let predicate = Value.object([
            "if": arr(
                .object([
                    "==": arr(.object(["var": .string("multiplier")]), .null)
                ]),
                .object(["var": .string("current")]),
                .int(-999)
            )
        ])
        // Each iteration: multiplier resolves to null → condition true →
        // accumulator becomes the current item. After [1, 2, 3] →
        // accumulator = 3. If parent scope leaked through, accumulator
        // would be -999.
        let out = try IterationOperators.opReduce(
            args: arr(
                arr(.int(1), .int(2), .int(3)),
                predicate,
                .int(0)
            ),
            vars: .object(["multiplier": .int(10)])
        )
        XCTAssertEqual(out, .int(3))
    }

    func testReduceArityMismatchTwoArgsIsTypeError() {
        XCTAssertThrowsError(
            try IterationOperators.opReduce(
                args: arr(.array([]), addCurrentAndAccumulator),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                XCTFail("expected typeMismatch, got \(error)")
                return
            }
        }
    }

    func testReduceArityMismatchFourArgsIsTypeError() {
        XCTAssertThrowsError(
            try IterationOperators.opReduce(
                args: arr(.array([]), addCurrentAndAccumulator, .int(0), .int(1)),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                XCTFail("expected typeMismatch, got \(error)")
                return
            }
        }
    }

    // MARK: - none / map / filter scope semantics

    /// The predicate of `none`/`map`/`filter` (mirroring `some`/`all`)
    /// cannot reach the parent scope: outer-scope variables resolve to
    /// `.null` inside the per-item evaluation.
    func testNoneMapFilterPredicateCannotReachParentScope() throws {
        // Outer has `flag = true`. Inside the predicate, `{"var": "flag"}`
        // resolves to .null because the scope is the current item only.
        let predicate = Value.object(["==": arr(.object(["var": .string("flag")]), .bool(true))])

        let none = try IterationOperators.opNone(
            args: arr(arr(.object([:]), .object([:])), predicate),
            vars: .object(["flag": .bool(true)])
        )
        XCTAssertEqual(none, .bool(true))

        let map = try IterationOperators.opMap(
            args: arr(arr(.object([:]), .object([:])), predicate),
            vars: .object(["flag": .bool(true)])
        )
        XCTAssertEqual(map, .array([.bool(false), .bool(false)]))

        let filter = try IterationOperators.opFilter(
            args: arr(arr(.object([:]), .object([:])), predicate),
            vars: .object(["flag": .bool(true)])
        )
        XCTAssertEqual(filter, .array([]))
    }

    // MARK: - End-to-end through Evaluator

    /// Drives `filter` through `Evaluator.evaluateValue` so the dispatch
    /// wiring is exercised end-to-end. Mirrors the canonical
    /// json-logic-js README example for `filter`.
    func testFilterEndToEndThroughEvaluator() throws {
        // {"filter": [{"var": "integers"}, {"%": [{"var": ""}, 2]}]}
        // over [1..5] → odd numbers [1, 3, 5].
        let predicate = Value.object([
            "filter": arr(
                .object(["var": .string("integers")]),
                .object(["%": arr(.object(["var": .string("")]), .int(2))])
            )
        ])
        let vars = Value.object([
            "integers": arr(.int(1), .int(2), .int(3), .int(4), .int(5))
        ])
        XCTAssertEqual(
            try Evaluator.evaluateValue(predicate, vars: vars),
            .array([.int(1), .int(3), .int(5)])
        )
    }

    /// Chains `map` → `reduce` to sum-of-squares, end-to-end through the
    /// evaluator. Pins that nested iteration ops compose cleanly across
    /// the dispatch boundary.
    func testMapAndReduceComposeEndToEnd() throws {
        // sum( map([1,2,3,4], x*x) ) = 1 + 4 + 9 + 16 = 30
        let predicate = Value.object([
            "reduce": arr(
                .object([
                    "map": arr(
                        .object(["var": .string("integers")]),
                        .object([
                            "*": arr(
                                .object(["var": .string("")]),
                                .object(["var": .string("")])
                            )
                        ])
                    )
                ]),
                addCurrentAndAccumulator,
                .int(0)
            )
        ])
        let vars = Value.object([
            "integers": arr(.int(1), .int(2), .int(3), .int(4))
        ])
        let result = try Evaluator.evaluateValue(predicate, vars: vars)
        XCTAssertEqual(result.asNumber, 30)
    }

    // MARK: - Helpers

    /// `{">": [{"var": ""}, 0]}` — current item is greater than zero.
    private var gtZero: Value {
        .object([">": arr(.object(["var": .string("")]), .int(0))])
    }

    /// `{"==": [{"var": "status"}, "active"]}` — item.status == "active".
    private var statusEqualsActive: Value {
        .object(["==": arr(.object(["var": .string("status")]), .string("active"))])
    }

    /// `{"+": [{"var": "current"}, {"var": "accumulator"}]}` — the
    /// canonical reduce body.
    private var addCurrentAndAccumulator: Value {
        .object([
            "+": arr(
                .object(["var": .string("current")]),
                .object(["var": .string("accumulator")])
            )
        ])
    }

    private func arr(_ items: Value...) -> Value {
        .array(items)
    }
}
// swiftlint:enable type_body_length file_length
