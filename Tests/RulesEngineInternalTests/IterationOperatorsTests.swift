//
//  IterationOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

/// The bulk of the iteration-operator coverage lives in
/// `PredicateFixtures/iteration.json`. The cases that remain here cannot be
/// expressed faithfully as JSON fixtures because their assertions depend on
/// the exact element *type* / *structure* of an array result, which the
/// fixture format can only compare via JS string coercion (lossy for
/// objects, `null`, and the int/string/float distinction).
final class IterationOperatorsTests: XCTestCase {

    /// `map` returns the raw predicate result, not a truthy-coerced bool.
    /// Pinned so a future regression can't accidentally collapse the
    /// result type. Item objects are routed through `vars` so the
    /// evaluator does not try to dispatch their single key (`x`) as an
    /// operator.
    ///
    /// Kept as Swift: the contract is the raw `.int` element type, which
    /// string coercion (`"10,20"`) cannot distinguish from `.string`/`.float`.
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

    /// `filter` retains the *original* item, not the predicate result.
    /// Locks the spec contract — easy to accidentally regress to "return
    /// the predicate result if truthy". Item objects are routed through
    /// `vars` so the evaluator does not try to dispatch their single key
    /// (`x`) as an operator.
    ///
    /// Kept as Swift: the result is an array of objects, which coerces to
    /// `"[object Object],[object Object]"` and cannot be distinguished from
    /// a predicate-result variant via string coercion.
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

    /// With only the source argument, a missing predicate evaluates
    /// to `.null` for every item.
    ///
    /// Kept as Swift: the result `[null, null, null]` coerces to `",,"`,
    /// where `null` and the empty string are indistinguishable, defeating
    /// the "maps each item to null" assertion.
    func testMapMissingPredicateMapsEachItemToNull() throws {
        let out = try IterationOperators.opMap(
            args: arr(arr(.int(1), .int(2), .int(3))),
            vars: .null
        )
        XCTAssertEqual(out, .array([.null, .null, .null]))
    }

    // MARK: - Helpers

    private func arr(_ items: Value...) -> Value {
        .array(items)
    }
}
