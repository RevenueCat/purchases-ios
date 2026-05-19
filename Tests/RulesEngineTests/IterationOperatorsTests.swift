//
//  IterationOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

// swiftlint:disable type_body_length
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
    /// returns `true` for this case — see the doc comment on
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

    // MARK: - Helpers

    /// `{">": [{"var": ""}, 0]}` — current item is greater than zero.
    private var gtZero: Value {
        .object([">": arr(.object(["var": .string("")]), .int(0))])
    }

    /// `{"==": [{"var": "status"}, "active"]}` — item.status == "active".
    private var statusEqualsActive: Value {
        .object(["==": arr(.object(["var": .string("status")]), .string("active"))])
    }

    private func arr(_ items: Value...) -> Value {
        .array(items)
    }
}
