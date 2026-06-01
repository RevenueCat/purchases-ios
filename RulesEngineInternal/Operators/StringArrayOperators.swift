//
//  StringArrayOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// String + array operators: `in`, `cat`, `substr`, `merge`.
///
/// Behavior follows the JSON Logic JS reference (`json-logic-js`).
/// `substr` slices by Unicode code points, not UTF-16 code units —
/// matches Swift's `String.Character` semantics; differs from JS only
/// for surrogate-pair characters.
enum StringArrayOperators {

    /// `{"in": [needle, haystack]}` — substring or array-membership
    /// test. For a `.string` haystack, the needle is stringified and
    /// the test is substring containment (mirrors JS
    /// `String.prototype.indexOf`); an empty haystack is falsy in
    /// json-logic-js (`if (!b) return false`), so `in` never matches.
    /// For an `.array` haystack, the test is strict element equality
    /// (mirrors JS `Array.prototype.indexOf`, which uses `===`). Any
    /// other haystack type returns `false`. `json-logic-js` declares
    /// `in` as `function(a, b)`, so missing or extra operands
    /// short-circuit to `false`.
    static func opIn(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let needle = evaluated.first ?? .null
        let haystack = evaluated.indices.contains(1) ? evaluated[1] : .null
        switch haystack {
        case .string(let haystackString):
            // json-logic-js: `if (!b || …) return false` — empty string is
            // falsy, so `in` never matches regardless of needle.
            if haystackString.isEmpty { return .bool(false) }
            return .bool(haystackString.contains(jsString(needle)))
        case .array(let items):
            return .bool(items.contains { strictEq(needle, $0) })
        default:
            return .bool(false)
        }
    }

    /// `{"cat": [a, b, ...]}` — variadic string concatenation. Each
    /// operand is rendered via [`jsArrayElementString`] (mirrors
    /// `Array.prototype.join` on the argument list: `null` → `""`).
    /// 0 args returns `""`.
    static func opCat(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let joined = evaluated.map(jsArrayElementString).joined()
        return .string(joined)
    }

    /// `{"substr": [source, start]}` or
    /// `{"substr": [source, start, length]}`. `source` is stringified.
    /// Negative `start` counts from the end. A negative `length` drops
    /// that many characters from the right of the substring that starts
    /// at `start`. Code-point-based, not byte-based — see type docs.
    /// `json-logic-js` declares `substr` as
    /// `function(source, start, end)`, so a missing `start` defaults
    /// to `0` and arguments past the third are silently ignored.
    static func opSubstr(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let source = evaluated.first ?? .null
        let start = evaluated.indices.contains(1) ? evaluated[1] : .null
        let length: Value? = evaluated.indices.contains(2) ? evaluated[2] : nil

        let chars = Array(jsString(source))
        let total = chars.count

        // Non-numeric start coerces to 0 (matches JS `ToInteger`).
        let startN = Operators.clampedInt(start.asNumber ?? 0)
        let begin: Int
        if startN < 0 {
            begin = max(total + startN, 0)
        } else {
            begin = min(startN, total)
        }

        let afterStart = Array(chars[begin...])

        let result: String
        if let length = length {
            let lenN = Operators.clampedInt(length.asNumber ?? 0)
            let count: Int
            if lenN < 0 {
                count = max(afterStart.count + lenN, 0)
            } else {
                count = min(lenN, afterStart.count)
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
}
