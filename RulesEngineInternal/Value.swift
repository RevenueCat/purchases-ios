//
//  Value.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// A JSON-shaped value. Used both as the parsed JSON Logic predicate tree
/// and as the resolved variable map handed in by callers.
///
/// Maps directly onto the JSON data model with one tweak: numbers are split
/// into `int(Int64)` and `float(Double)` so callers can preserve type
/// intent. Cross-type numeric comparisons / arithmetic still work — see
/// `looseEq`, `strictEq`, and the comparison helpers below.
///
/// JSON parsing intentionally lives only in tests (see the `Value+JSON.swift`
/// test helper). Production callers will cross the FFI with a typed `Value`
/// tree they construct from the host SDK's JSON parser.
enum Value: Equatable {

    case null
    case bool(Bool)
    case int(Int64)
    case float(Double)
    case string(String)
    case array([Value])
    case object([String: Value])
}

extension Value {

    /// JSON Logic truthiness rules:
    /// - `null`, `false`, `0`, `""`, `[]`, `NaN` → falsy
    /// - `object(_)` → always truthy
    /// - everything else → truthy
    var isTruthy: Bool {
        switch self {
        case .null:
            return false
        case .bool(let value):
            return value
        case .int(let value):
            return value != 0
        case .float(let value):
            return value != 0.0 && !value.isNaN
        case .string(let value):
            return !value.isEmpty
        case .array(let items):
            return !items.isEmpty
        case .object:
            return true
        }
    }

    /// JS `Number(value)` (`ToNumber`): bool→0/1, int/float→self,
    /// null→0, string→`""` or whitespace→0 / parsed-or-`nil`, array/object
    /// → `ToPrimitive("number")` → `toString` → recurse on the resulting
    /// string. So `[]` → `""` → 0, `[1]` → `"1"` → 1, `[1,2]` → `"1,2"` →
    /// `nil` (whole-string parse fails), `{}` → `"[object Object]"` →
    /// `nil`.
    ///
    /// Returning `nil` rather than `Double.nan` lets `looseEq`'s numeric
    /// fallback distinguish "no comparable number" from "the number NaN"
    /// (NaN compares unequal to itself, so a `nil` short-circuit avoids an
    /// accidental `false` masking a genuine spec match). Arithmetic
    /// callers wrap with `?? .nan` to get the JS arithmetic propagation.
    var asNumber: Double? {
        switch self {
        case .null:
            return 0.0
        case .bool(let value):
            return value ? 1.0 : 0.0
        case .int(let value):
            return Double(value)
        case .float(let value):
            return value
        case .string(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return 0.0 }
            return Double(trimmed)
        case .array, .object:
            let stringified = jsString(self)
            let trimmed = stringified.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return 0.0 }
            return Double(trimmed)
        }
    }
}

/// JSON Logic loose equality (`==`). Best-effort JS-style coercion:
///
/// - Same-type primitive comparisons are direct value equality.
/// - Cross-numeric (`int` ↔ `float`) bridges as one number type.
/// - **Same-compound**: arrays/objects compare structurally. This
///   deliberately diverges from JS's reference identity (which would
///   make two distinct array literals always unequal); structural
///   equality is what rule authors actually need when comparing a
///   `var` lookup against a literal list.
/// - **Compound vs primitive**: mirrors JS abstract equality's
///   `ToPrimitive(string-hint)` step. Arrays render via
///   `Array.prototype.toString()` (recursive comma-join, with
///   `null` / `undefined` elements rendered as the empty string);
///   objects render as `"[object Object]"`. So `[1] == "1"`, `[1, 2]
///   == "1,2"`, `[null, 1] == ",1"`, and `[] == 0` all return `true`,
///   matching json-logic-js. The recursive call falls through to the
///   primitive arms (string-vs-string or the numeric fallback).
/// - **Last-resort numeric fallback**: when two primitives don't share
///   a type, both sides are coerced to `Double` (JS `ToNumber`) and
///   compared. Returns `false` if either coercion fails.
// swiftlint:disable:next cyclomatic_complexity
func looseEq(_ lhs: Value, _ rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
        return true
    case (.null, _), (_, .null):
        return false

    case (.bool(let left), .bool(let right)):
        return left == right
    case (.string(let left), .string(let right)):
        return left == right

    case (.int(let left), .int(let right)):
        return left == right
    case (.float(let left), .float(let right)):
        return left == right
    case (.int(let intValue), .float(let floatValue)),
         (.float(let floatValue), .int(let intValue)):
        return Double(intValue) == floatValue

    case (.array(let left), .array(let right)):
        return left.count == right.count && zip(left, right).allSatisfy { looseEq($0, $1) }

    case (.object(let left), .object(let right)):
        guard left.count == right.count else { return false }
        for (key, value) in left {
            guard let other = right[key], looseEq(value, other) else { return false }
        }
        return true

    // JS abstract-equality coercion: when one side is a compound (Array
    // or Object) and the other is a primitive, ToPrimitive(string-hint)
    // the compound and re-compare. Order matters — same-compound cases
    // above must match first so `[1] == [1]` stays structural.
    case (.array(let items), _):
        return looseEq(.string(jsArrayJoin(items)), rhs)
    case (_, .array(let items)):
        return looseEq(lhs, .string(jsArrayJoin(items)))
    case (.object, _):
        return looseEq(.string(jsObjectString), rhs)
    case (_, .object):
        return looseEq(lhs, .string(jsObjectString))

    default:
        if let leftNumber = lhs.asNumber, let rightNumber = rhs.asNumber {
            return leftNumber == rightNumber
        }
        return false
    }
}

// MARK: - JS coercion helpers (used by looseEq and arithmetic)

/// JS `String(value)` for top-level conversion. Differs from
/// `jsArrayElementString` only in `null` handling: `String(null) === "null"`,
/// but `Array.prototype.join` renders `null` / `undefined` array elements
/// as the empty string. Use this for callers that need the top-level
/// toString (numeric coercion, `parseFloat`-style stringification).
func jsString(_ value: Value) -> String {
    switch value {
    case .null:
        return "null"
    case .bool(let value):
        return value ? "true" : "false"
    case .int(let value):
        return String(value)
    case .float(let value):
        return jsNumberString(value)
    case .string(let value):
        return value
    case .array(let items):
        return jsArrayJoin(items)
    case .object:
        return jsObjectString
    }
}

/// JS `parseFloat(value)`. Stringifies via `jsString`, strips leading
/// whitespace, then parses the longest valid prefix as a JS
/// `StringNumericLiteral` (optional sign, digits with optional decimal,
/// optional decimal exponent, plus the `Infinity` literal). Anything else
/// — including `null` ("null"), bools ("true" / "false"), and the empty
/// string — yields `NaN`. Lenient about trailing junk (`"3.14abc"` → 3.14)
/// to match JS's prefix-parsing behavior, which is what `+` / `*` use in
/// `json-logic-js`.
func jsParseFloat(_ value: Value) -> Double {
    if case .int(let value) = value { return Double(value) }
    if case .float(let value) = value { return value }
    return parseFloatPrefix(jsString(value))
}

private func parseFloatPrefix(_ string: String) -> Double {
    let trimmed = string.drop(while: \.isWhitespace)
    guard !trimmed.isEmpty else { return .nan }
    let str = String(trimmed)
    if str.hasPrefix("Infinity") { return .infinity }
    if str.hasPrefix("-Infinity") { return -.infinity }
    if str.hasPrefix("+Infinity") { return .infinity }
    let pattern = #"^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?"#
    guard let match = str.range(of: pattern, options: .regularExpression),
          match.lowerBound == str.startIndex else {
        return .nan
    }
    return Double(str[match]) ?? .nan
}

/// `Array.prototype.toString()` ≡ `Array.prototype.join(",")`. Renders
/// each element via `jsArrayElementString`, then comma-joins.
private func jsArrayJoin(_ items: [Value]) -> String {
    items.map(jsArrayElementString).joined(separator: ",")
}

/// JS `String(value)` semantics with the array-element twist: `null` /
/// `undefined` render as the empty string (not `"null"`); nested arrays
/// recurse; everything else uses standard JS `String()`.
private func jsArrayElementString(_ value: Value) -> String {
    switch value {
    case .null:
        return ""
    case .bool(let value):
        return value ? "true" : "false"
    case .int(let value):
        return String(value)
    case .float(let value):
        return jsNumberString(value)
    case .string(let value):
        return value
    case .array(let items):
        return jsArrayJoin(items)
    case .object:
        return jsObjectString
    }
}

/// JS `String(number)` for the cases that show up in real rule data:
/// whole-number doubles render without a decimal (`String(1.0) === "1"`),
/// `NaN` / `±Infinity` keep their JS spellings, fractional doubles use
/// Swift's default rendering (matches JS for non-pathological values).
private func jsNumberString(_ value: Double) -> String {
    if value.isNaN { return "NaN" }
    if value.isInfinite { return value > 0 ? "Infinity" : "-Infinity" }
    if let int64 = Int64(exactly: value) { return String(int64) }
    return String(value)
}

/// JS `Object.prototype.toString.call(plainObject)` for any non-Array
/// object. JSON Logic only ever encounters plain objects, so the
/// fallback `"[object Object]"` is the only spelling we need.
private let jsObjectString = "[object Object]"

/// JSON Logic strict equality (`===`). Same type, same value. Numeric
/// strict-eq treats `int(1)` and `float(1.0)` as equal — they represent the
/// same JS `Number`, and our split is an internal modeling choice.
// swiftlint:disable:next cyclomatic_complexity
func strictEq(_ lhs: Value, _ rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
        return true
    case (.bool(let left), .bool(let right)):
        return left == right
    case (.int(let left), .int(let right)):
        return left == right
    case (.float(let left), .float(let right)):
        return left == right
    case (.int(let intValue), .float(let floatValue)),
         (.float(let floatValue), .int(let intValue)):
        return Double(intValue) == floatValue
    case (.string(let left), .string(let right)):
        return left == right
    case (.array(let left), .array(let right)):
        return left.count == right.count && zip(left, right).allSatisfy { strictEq($0, $1) }
    case (.object(let left), .object(let right)):
        guard left.count == right.count else { return false }
        for (key, value) in left {
            guard let other = right[key], strictEq(value, other) else { return false }
        }
        return true
    default:
        return false
    }
}
