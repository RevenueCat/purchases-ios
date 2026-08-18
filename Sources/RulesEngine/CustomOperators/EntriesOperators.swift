//
//  EntriesOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `rc.entries` and `rc.fromEntries` — convert between keyed objects and
    /// the `[key, value]` pair arrays that JSON Logic iteration operators accept.
    ///
    /// Cross-engine contract: any evaluator (including a `json-logic-js` web
    /// polyfill) must match these semantics, not bare `Object.entries` /
    /// `Object.fromEntries`.
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
        ///   insertion order (same rationale as `.sortedKeys` in `Audience.swift`).
        /// - **Array**: index/value pairs with **string** keys (`"0"`, `"1"`, …),
        ///   matching `Object.entries(["a","b"]) === [["0","a"],["1","b"]]`.
        /// - **Everything else** (null, undefined, bool, number, string): `[]`
        ///   plus a warning. Returning empty matches how iteration operators treat
        ///   a non-array source and composes cleanly (`some` → `false`).
        ///
        /// **String divergence**: JS `Object.entries("ab")` yields character
        /// pairs; we return `[]` with a warning. A web polyfill written as bare
        /// `Object.entries` would disagree on strings and would *throw* on
        /// null/undefined where we return `[]`.
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
                RulesEngine.logger.warn(
                    "rc.entries: expected object or array, got \(input)"
                )
                return .array([])
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
        ///   via `jsString` (same helper `var` uses for path segments). Values
        ///   come from element `1`, or `.null` when absent.
        /// - **Duplicate keys**: last occurrence wins, matching JS.
        /// - **Non-array element**: skipped with a warning.
        /// - **Non-array argument** or **empty array**: `{}` (empty array also
        ///   yields `{}`; non-array input logs a warning).
        static func opFromEntries(args: Value, vars: Scope) throws -> Value {
            let input = try Operators.firstArgEvaluated(args, vars: vars)

            guard case .array(let entries) = input else {
                RulesEngine.logger.warn(
                    "rc.fromEntries: expected array, got \(input)"
                )
                return .object([:])
            }

            var result: [String: Value] = [:]
            for entry in entries {
                guard case .array(let pair) = entry else {
                    RulesEngine.logger.warn(
                        "rc.fromEntries: skipping non-array entry"
                    )
                    continue
                }

                let key = jsString(pair.first ?? .undefined)
                let value = pair.count >= 2 ? pair[1] : .null
                result[key] = value
            }
            return .object(result)
        }
    }
}
