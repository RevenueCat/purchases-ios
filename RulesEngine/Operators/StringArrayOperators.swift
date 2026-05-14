//
//  StringArrayOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// String + array operators: `in`, `cat`, `substr`, `merge`.
///
/// Behavior follows the JSON Logic JS reference (`json-logic-js`) with two
/// deliberate, documented deviations:
///
/// - **`in` array membership uses `looseEq`** (so `{"in": [5, ["5"]]}` is
///   true) instead of the JS reference's strict `===`. Rule authors
///   typically write integer literals against backend-supplied string
///   lists, and loose equality is more forgiving for that workflow.
///   Pure-string and pure-numeric comparisons are unaffected.
/// - **`substr` slices by Unicode code points**, not UTF-16 code units.
///   Matches Swift's default `String.Character` semantics and gives the
///   intuitive answer for multibyte strings; differs from JS only for
///   surrogate-pair characters (rare in real rule data).
enum StringArrayOperators {

    /// `{"in": [needle, haystack]}` — substring or array-membership test.
    /// For a `.string` haystack, the needle must also be a string and the
    /// test is substring containment. For an `.array` haystack, the test
    /// is element membership via `looseEq`. Any other haystack type
    /// returns `false` (mirrors JS, where a non-`indexOf`-able haystack
    /// short-circuits to false).
    static func opIn(args: Value, vars: Value) throws -> Value {
        let (needle, haystack) = try Operators.evalTwo(args, vars: vars, opName: "in")
        switch (needle, haystack) {
        case (.string(let needleString), .string(let haystackString)):
            return .bool(haystackString.contains(needleString))
        case (_, .array(let items)):
            return .bool(items.contains { looseEq(needle, $0) })
        default:
            return .bool(false)
        }
    }

    /// `{"cat": [a, b, ...]}` — variadic string concatenation. Each
    /// operand is stringified via [`stringify`]. 0 args returns `""`.
    static func opCat(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let joined = evaluated.map(stringify).joined()
        return .string(joined)
    }

    /// `{"substr": [source, start]}` or
    /// `{"substr": [source, start, length]}`. `source` is stringified.
    /// Negative `start` counts from the end. A negative `length` drops
    /// that many characters from the right of the substring that starts
    /// at `start` (matches the JS reference). Code-point-based, not
    /// byte-based — see type docs.
    static func opSubstr(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let source: Value
        let start: Value
        let length: Value?
        switch evaluated.count {
        case 2:
            source = evaluated[0]
            start = evaluated[1]
            length = nil
        case 3:
            source = evaluated[0]
            start = evaluated[1]
            length = evaluated[2]
        default:
            throw RuleError.typeMismatch(
                message: "operator 'substr' expects 2 or 3 arguments, got \(evaluated.count)"
            )
        }

        let chars = Array(stringify(source))
        let total = Int64(chars.count)

        // Non-numeric start coerces to 0 (mirrors JS:
        // `Number(undefined)` → NaN → treated as 0 by
        // `String.prototype.substr`).
        let startN = Int64(start.asNumber ?? 0)
        let begin: Int
        if startN < 0 {
            begin = Int(max(total + startN, 0))
        } else {
            begin = Int(min(startN, total))
        }

        let afterStart = Array(chars[begin...])

        let result: String
        if let length = length {
            let lenN = Int64(length.asNumber ?? 0)
            let count: Int
            if lenN < 0 {
                count = Int(max(Int64(afterStart.count) + lenN, 0))
            } else {
                count = min(Int(lenN), afterStart.count)
            }
            result = String(afterStart[..<count])
        } else {
            result = String(afterStart)
        }
        return .string(result)
    }

    /// `{"merge": [a, b, ...]}` — variadic, flattens one level. Array
    /// operands are spliced in; non-array operands are appended as
    /// single elements.
    static func opMerge(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        var merged: [Value] = []
        for item in evaluated {
            if case .array(let inner) = item {
                merged.append(contentsOf: inner)
            } else {
                merged.append(item)
            }
        }
        return .array(merged)
    }

    /// Coerce a `Value` to a `String` for `cat` / `substr`. Mirrors
    /// JavaScript's `String(value)`:
    /// - `.null` → `"null"`
    /// - `.bool` → `"true"` / `"false"`
    /// - `.int` / `.float` → numeric repr (integers render without a
    ///   trailing `.0`, matching JS)
    /// - `.string` → unchanged
    /// - `.array` → comma-joined recursive stringify (JS
    ///   `Array.prototype.toString`)
    /// - `.object` → `"[object Object]"` (matches JS; concatenating an
    ///   object is almost always a rule-authoring bug, but the result
    ///   is at least defined)
    private static func stringify(_ value: Value) -> String {
        switch value {
        case .null:
            return "null"
        case .bool(let value):
            return value ? "true" : "false"
        case .int(let value):
            return String(value)
        case .float(let value):
            return formatNumber(value)
        case .string(let value):
            return value
        case .array(let items):
            return items.map(stringify).joined(separator: ",")
        case .object:
            return "[object Object]"
        }
    }

    /// Render a `Double` the way JS would — `1.0` becomes `"1"`, `1.5`
    /// stays `"1.5"`.
    ///
    /// `Int64(exactly:)` returns `nil` for non-integer, out-of-range,
    /// NaN, and ±Infinity inputs, so the fall-through to `String(value)`
    /// covers each of those without a manual guard.
    private static func formatNumber(_ value: Double) -> String {
        if let intValue = Int64(exactly: value) {
            return String(intValue)
        }
        return String(value)
    }
}
