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
/// in the current scope and must resolve to an array; anything else
/// short-circuits to `false`. The second argument is a literal template
/// that is evaluated per-item with `vars` rebound to the current item,
/// with no parent-scope inheritance.
///
/// **Empty-array behavior**: `all` over an empty array returns `false`,
/// not vacuous truth, per the JSON Logic JS spec.
enum IterationOperators {

    /// `{"some": [arrayExpr, predicate]}` — `true` iff `predicate` is
    /// truthy for at least one item in the array. Empty array or
    /// non-array source returns `false`. Short-circuits on the first
    /// truthy result.
    static func opSome(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars)
        guard let items else { return .bool(false) }
        for item in items {
            let result = try Evaluator.evaluateValue(predicate, vars: item)
            if result.isTruthy { return .bool(true) }
        }
        return .bool(false)
    }

    /// `{"all": [arrayExpr, predicate]}` — `true` iff `predicate` is
    /// truthy for every item. Empty array returns `false` per the JSON
    /// Logic JS spec, not vacuous truth. Non-array source returns
    /// `false`. Short-circuits on the first non-truthy result.
    static func opAll(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars)
        guard let items, !items.isEmpty else { return .bool(false) }
        for item in items {
            let result = try Evaluator.evaluateValue(predicate, vars: item)
            if !result.isTruthy { return .bool(false) }
        }
        return .bool(true)
    }

    /// Parse `(items, predicate)` for an iteration operator. The source
    /// argument is evaluated in the outer scope; the predicate template
    /// is returned unevaluated so the caller can re-evaluate it per
    /// item with the item as scope. `items` is `nil` when the source
    /// does not resolve to an array, so callers can distinguish a
    /// non-array source from a genuinely empty one (`some`/`all` treat
    /// both as `false`, but `none`/`map`/`filter`/`reduce` need the
    /// distinction). A missing predicate defaults to `.null` and
    /// arguments past the second are ignored, matching `json-logic-js`'s
    /// `function(scopedData, scopedLogic)` signature.
    private static func parseIterationArgs(
        _ args: Value,
        vars: Value
    ) throws -> (items: [Value]?, predicate: Value) {
        let raw = Operators.argsAsList(args)
        let sourceArg: Value = raw.indices.contains(0) ? raw[0] : .null
        let predicate: Value = raw.indices.contains(1) ? raw[1] : .null
        let source = try Evaluator.evaluateValue(sourceArg, vars: vars)
        guard case .array(let items) = source else { return (nil, predicate) }
        return (items, predicate)
    }
}
