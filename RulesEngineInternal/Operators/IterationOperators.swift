//
//  IterationOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Iteration predicates: `some`, `all`.
///
/// Both follow the JSON Logic JS reference (`json-logic-js`). Shape is
/// `{"some": [arrayExpr, predicateExpr]}` /
/// `{"all": [arrayExpr, predicateExpr]}`. The first argument is evaluated
/// in the current scope and must resolve to an array — anything else
/// short-circuits to `false`. The second argument is a literal template
/// that is evaluated per-item with `vars` rebound to the current item,
/// with no parent-scope inheritance (matches the JS reference).
///
/// **Empty-array behavior**: `all` over an empty array returns `false`,
/// not vacuous truth. This is a deliberate JSON Logic JS spec quirk
/// that the Python `json-logic` library also honors; pinned by tests.
/// The RevenueCat backend (`khepri`) currently returns `true` for the
/// same case — we deliberately follow the spec instead so the SDK stays
/// consistent with the wider JSON Logic ecosystem.
enum IterationOperators {

    /// `{"some": [arrayExpr, predicate]}` — `true` iff `predicate` is
    /// truthy for at least one item in the array. Empty array or
    /// non-array source returns `false`. Short-circuits on the first
    /// truthy result.
    static func opSome(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars, opName: "some")
        for item in items {
            let result = try Evaluator.evaluateValue(predicate, vars: item)
            if result.isTruthy { return .bool(true) }
        }
        return .bool(false)
    }

    /// `{"all": [arrayExpr, predicate]}` — `true` iff `predicate` is
    /// truthy for every item. Empty array returns `false` (deliberate
    /// JSON Logic JS spec quirk, not vacuous truth). Non-array source
    /// returns `false`. Short-circuits on the first non-truthy result.
    static func opAll(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars, opName: "all")
        guard !items.isEmpty else { return .bool(false) }
        for item in items {
            let result = try Evaluator.evaluateValue(predicate, vars: item)
            if !result.isTruthy { return .bool(false) }
        }
        return .bool(true)
    }

    /// Parse `(items, predicate)` for an iteration operator. The source
    /// argument is evaluated in the outer scope; the predicate template
    /// is returned unevaluated so the caller can re-evaluate it per
    /// item with the item as scope. A non-array source resolves to an
    /// empty `items` list, which the caller turns into `false`.
    private static func parseIterationArgs(
        _ args: Value,
        vars: Value,
        opName: String
    ) throws -> ([Value], Value) {
        let raw = Operators.argsAsList(args)
        guard raw.count == 2 else {
            throw RuleError.typeMismatch(
                message: "operator '\(opName)' expects 2 arguments, got \(raw.count)"
            )
        }
        let source = try Evaluator.evaluateValue(raw[0], vars: vars)
        guard case .array(let items) = source else { return ([], raw[1]) }
        return (items, raw[1])
    }
}
