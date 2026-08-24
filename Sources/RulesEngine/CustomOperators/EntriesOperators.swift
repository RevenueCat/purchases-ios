//
//  EntriesOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `rc.entries` and `rc.fromEntries` — convert between keyed objects and
    /// the `[key, value]` pair arrays that JSON Logic iteration operators accept.
    enum EntriesOperators {

        /// `{"rc.entries": value}` — convert a keyed object or array into an
        /// array of two-element `[key, value]` arrays so `some`, `filter`, etc.
        /// can iterate it.
        ///
        /// **Argument form**: unary operators follow `json-logic-js` spread
        /// semantics via `Operators.firstArgEvaluated` — a multi-element
        /// top-level array is a multi-argument call, not a single array
        /// operand. So `{"rc.entries": ["a", "b"]}` uses only `"a"`. To pass a
        /// literal array operand, wrap it:
        /// `{"rc.entries": [["a", "b"]]}`.
        ///
        /// - **Object**: pairs sorted **lexicographically by key**. Swift
        ///   dictionaries have no insertion order; this deliberately diverges
        ///   from JS `Object.entries` insertion order. Rules must not depend on
        ///   insertion order.
        /// - **Array**: index/value pairs with **string** keys (`"0"`, `"1"`, …),
        ///   matching `Object.entries(["a","b"]) === [["0","a"],["1","b"]]`.
        /// - **Anything else** (null, undefined, bool, number, string): throws
        ///   `EvaluationError.typeMismatch`.
        ///
        /// Strings throw rather than yielding the character pairs JS
        /// `Object.entries("ab")` produces. A string reaching here means the rule
        /// points at the wrong field, and iterating its characters would let that
        /// rule keep evaluating to a confident wrong answer.
        static func opEntries(args: Value, vars: Scope) throws -> Value {
            let input = try Operators.firstArgEvaluated(args, vars: vars)

            switch input {
            case .object(let map):
                let sortedKeys = map.keys.sorted()
                let pairs = sortedKeys.map { key in
                    Value.array([.string(key), map[key] ?? .null])
                }
                return .array(pairs)

            case .array(let items):
                let pairs = items.enumerated().map { index, value in
                    Value.array([.string(String(index)), value])
                }
                return .array(pairs)

            default:
                throw EvaluationError.typeMismatch(
                    message: "operator 'rc.entries' expected object or array, got \(input)"
                )
            }
        }

        /// `{"rc.fromEntries": pairs}` — inverse of `rc.entries`.
        ///
        /// **Argument form**: same spread semantics as `rc.entries`. A literal
        /// pair list must be wrapped as a single operand, e.g.
        /// `{"rc.fromEntries": [[["a", 1], ["b", 2]]]}`. Extra arguments are
        /// silently ignored, matching `!` and `!!`.
        ///
        /// - **Array of two-element arrays**: builds an object. Keys are coerced
        ///   via `jsString` (same helper `var` uses for path segments).
        /// - **Duplicate keys**: last occurrence wins, matching JS.
        /// - **Empty array**: `{}`.
        /// - **Non-array argument**, or any entry that is not a two-element
        ///   array: throws `EvaluationError.typeMismatch`.
        ///
        /// Malformed entries throw rather than being skipped. Dropping them
        /// would build a partial object that reads as a legitimate result, so a
        /// rule could match on the surviving keys alone.
        static func opFromEntries(args: Value, vars: Scope) throws -> Value {
            let input = try Operators.firstArgEvaluated(args, vars: vars)

            guard case .array(let entries) = input else {
                throw EvaluationError.typeMismatch(
                    message: "operator 'rc.fromEntries' expected array, got \(input)"
                )
            }

            var result: [String: Value] = [:]
            for entry in entries {
                guard case .array(let pair) = entry, pair.count == 2 else {
                    throw EvaluationError.typeMismatch(
                        message: "operator 'rc.fromEntries' expected a two-element "
                            + "[key, value] entry, got \(entry)"
                    )
                }

                result[jsString(pair[0])] = pair[1]
            }
            return .object(result)
        }
    }
}
