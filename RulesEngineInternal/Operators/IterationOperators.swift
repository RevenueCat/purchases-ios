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
///   the first and third arguments are evaluated in the outer scope. The
///   predicate is evaluated per-item with `vars` rebound to the *fixed*
///   object `{"current": <item>, "accumulator": <acc>}`, again with no
///   parent-scope inheritance. This per-item scope is the major
///   asymmetry vs. the other iteration ops (which rebind to the item
///   itself).
///
/// **Empty- and non-array sources**:
/// - `some` returns `false`.
/// - `all` returns `false` (deliberate JSON Logic JS spec quirk, not
///   vacuous truth — the Python `json-logic` library agrees; the
///   RevenueCat backend `khepri` returns `true` for the same case, but
///   we follow the spec to stay consistent with the wider JSON Logic
///   ecosystem). Pinned by tests.
/// - `none` returns `true` (vacuous truth: the JS reference implements
///   `none` in terms of `filter`, which yields `[]` for non-arrays, and
///   `[].length === 0` is `true`). Pinned by tests.
/// - `map` / `filter` return `[]`.
/// - `reduce` returns the initial accumulator unchanged.
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

    /// `{"none": [arrayExpr, predicate]}` — `true` iff `predicate` is
    /// falsy for every item. Inverse of `some`. Short-circuits on the
    /// first truthy item.
    ///
    /// Note the deliberate asymmetry with `some`/`all` for non-array
    /// sources: the JS reference implements `none` in terms of `filter`,
    /// which yields `[]` for non-arrays, and `[].length === 0` is
    /// `true`. So `none(null, …)` and `none("abc", …)` both return
    /// `true`, while `some`/`all` of those return `false`. Pinned by
    /// tests.
    static func opNone(args: Value, vars: Value) throws -> Value {
        let (items, predicate) = try parseIterationArgs(args, vars: vars, opName: "none")
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
        let (items, predicate) = try parseIterationArgs(args, vars: vars, opName: "map")
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
        let (items, predicate) = try parseIterationArgs(args, vars: vars, opName: "filter")
        var results: [Value] = []
        for item in items {
            let result = try Evaluator.evaluateValue(predicate, vars: item)
            if result.isTruthy { results.append(item) }
        }
        return .array(results)
    }

    /// `{"reduce": [arrayExpr, predicate, initialAccumulator]}` — fold
    /// over the array.
    ///
    /// The third argument is evaluated in the outer scope to seed the
    /// accumulator, then the predicate is evaluated once per item with
    /// `vars` rebound to `{"current": item, "accumulator": acc}` — the
    /// item itself is *not* the entire scope, unlike `none`/`map`/
    /// `filter`. A non-array source returns the seed unchanged.
    static func opReduce(args: Value, vars: Value) throws -> Value {
        let raw = Operators.argsAsList(args)
        guard raw.count == 3 else {
            throw RuleError.typeMismatch(
                message: "operator 'reduce' expects 3 arguments, got \(raw.count)"
            )
        }
        let source = try Evaluator.evaluateValue(raw[0], vars: vars)
        let predicate = raw[1]
        var accumulator = try Evaluator.evaluateValue(raw[2], vars: vars)
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

    /// Parse `(items, predicate)` for an iteration operator that uses
    /// the *item-as-scope* convention (`some`, `all`, `none`, `map`,
    /// `filter`). The source argument is evaluated in the outer scope;
    /// the predicate template is returned unevaluated so the caller can
    /// re-evaluate it per item. A non-array source resolves to an empty
    /// `items` list, which the caller turns into the operator's
    /// non-array fallback (`false` for `some`/`all`, `true` for `none`,
    /// `[]` for `map`/`filter`).
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
