//
//  IterationOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Iteration operators: `some`, `all`, `none`, `map`, `filter`, `reduce`.
///
/// All six follow the JSON Logic JS reference (`json-logic-js`):
///
/// - **Shape** (`some` / `all` / `none` / `map` / `filter`):
///   `{"<op>": [arrayExpr, predicateExpr]}`. The first argument is
///   evaluated in the outer scope and must resolve to an array; anything
///   else is treated as an empty source. The second argument is a
///   literal template that is evaluated per-item with `vars` rebound to
///   the current item, with no parent-scope inheritance.
/// - **Shape** (`reduce`):
///   `{"reduce": [arrayExpr, predicateExpr, initialAccumulator]}`. Both
///   the first and third arguments are evaluated in the outer scope.
///   The predicate is evaluated per-item with `vars` rebound to
///   `{"current": <item>, "accumulator": <acc>}`, with no parent-scope
///   inheritance.
///
/// **Empty- and non-array sources** per the JSON Logic JS spec:
/// - `some` / `all` return `false`.
/// - `none` returns `true`.
/// - `map` / `filter` return `[]`.
/// - `reduce` returns the initial accumulator unchanged.
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

    /// `{"none": [arrayExpr, predicate]}` — `true` iff `predicate` is
    /// falsy for every item. Inverse of `some`. Short-circuits on the
    /// first truthy item. Empty and non-array sources both return `true`,
    /// matching the JS reference's `!Array.isArray(x) || !x.length` guard.
    static func opNone(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars)
        guard let items else { return .bool(true) }
        for item in items {
            let result = try Evaluator.evaluateValue(predicate, vars: item)
            if result.isTruthy { return .bool(false) }
        }
        return .bool(true)
    }

    /// `{"map": [arrayExpr, predicate]}` — apply `predicate` to each
    /// item, return the new array of *raw* (non-truthy-coerced) results.
    /// Empty or non-array source yields `[]`.
    static func opMap(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars)
        guard let items else { return .array([]) }
        var results: [Value] = []
        results.reserveCapacity(items.count)
        for item in items {
            results.append(try Evaluator.evaluateValue(predicate, vars: item))
        }
        return .array(results)
    }

    /// `{"filter": [arrayExpr, predicate]}` — return only items for
    /// which `predicate` is truthy. Empty or non-array source yields
    /// `[]`. The retained items are the *original* values, not the
    /// predicate results.
    static func opFilter(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars)
        guard let items else { return .array([]) }
        var results: [Value] = []
        for item in items {
            let result = try Evaluator.evaluateValue(predicate, vars: item)
            if result.isTruthy { results.append(item) }
        }
        return .array(results)
    }

    /// `{"reduce": [arrayExpr, predicate, initialAccumulator]}` — fold
    /// over the array. The third argument is evaluated in the outer
    /// scope to seed the accumulator, then the predicate is evaluated
    /// once per item with `vars` rebound to
    /// `{"current": item, "accumulator": acc}`. A non-array source
    /// returns the seed unchanged. A missing initial accumulator
    /// defaults to `.null` and arguments past the third are ignored.
    static func opReduce(args: Value, vars: Value) throws -> Value {
        let raw = Operators.argsAsList(args)
        let sourceArg: Value = raw.indices.contains(0) ? raw[0] : .null
        let predicate: Value = raw.indices.contains(1) ? raw[1] : .null
        let source = try Evaluator.evaluateValue(sourceArg, vars: vars)
        var accumulator: Value = raw.indices.contains(2)
            ? try Evaluator.evaluateValue(raw[2], vars: vars)
            : .null
        guard case .array(let items) = source else { return accumulator }
        for item in items {
            let scope: Value = .object([
                "current": item,
                "accumulator": accumulator
            ])
            accumulator = try Evaluator.evaluateValue(predicate, vars: scope)
        }
        return accumulator
    }

    /// Parse `(items, predicate)` for the item-as-scope iteration
    /// operators (`some`, `all`, `none`, `map`, `filter`). The source
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
