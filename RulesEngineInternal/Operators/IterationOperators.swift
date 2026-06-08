//
//  IterationOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Iteration predicates: `some`, `all`. Both follow the JSON Logic JS
/// reference (`json-logic-js`).
enum IterationOperators {

    /// `{"some": [arrayExpr, predicate]}` — `true` iff `predicate` is
    /// truthy for at least one item. The array expression is evaluated in
    /// the current scope; the predicate is re-evaluated per item with
    /// `vars` rebound to that item, with no parent-scope inheritance.
    /// Empty array or non-array source returns `false`. Short-circuits on
    /// the first truthy result.
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
    /// truthy for every item. The array expression is evaluated in the
    /// current scope; the predicate is re-evaluated per item with `vars`
    /// rebound to that item, with no parent-scope inheritance. Empty array
    /// returns `false` per the JSON Logic JS spec. Non-array source
    /// returns `false`. Short-circuits on the first non-truthy result.
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
