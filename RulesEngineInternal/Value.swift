//
//  Value.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// A JSON-shaped value for JSON Logic predicates and variable data.
///
/// Numbers are split into `int` and `float` cases to preserve type intent.
/// Cross-type numeric comparisons still work — see `looseEq` and `strictEq`.
enum Value: Equatable, Hashable, Sendable {

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
    /// `nil`. Arithmetic callers wrap the `nil` return with `?? .nan` to
    /// get JS arithmetic propagation.
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

/// JSON Logic loose equality (`==`). Mirrors JS abstract equality:
///
/// - Same-type primitive comparisons are direct value equality.
/// - Cross-numeric (`int` ↔ `float`) bridges as one number type.
/// - **Compound vs compound**: always `false`. JS uses reference
///   identity for arrays/objects; we have no references, so we mirror
///   the literal-vs-literal result (`[1] == [1]` → `false`,
///   `{a:1} == {a:1}` → `false`).
/// - **Compound vs primitive**: applies JS abstract equality's
///   `ToPrimitive(string-hint)` step. Arrays render via
///   `Array.prototype.toString()` (recursive comma-join, with
///   `null` / `undefined` elements rendered as the empty string);
///   objects render as `"[object Object]"`. So `[1] == "1"`, `[1, 2]
///   == "1,2"`, `[null, 1] == ",1"`, and `[] == 0` all return `true`.
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

    // Compound-vs-compound is reference equality in JS; without
    // references the only spec-aligned answer for two distinct
    // operands is `false`.
    case (.array, .array), (.object, .object), (.array, .object), (.object, .array):
        return false

    // JS abstract-equality coercion: when one side is a compound (Array
    // or Object) and the other is a primitive, ToPrimitive(string-hint)
    // the compound and re-compare. Order matters — compound-vs-compound
    // cases above must match first.
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

// MARK: - JS coercion helpers (used by looseEq, arithmetic, and stringifying operators)

/// JS `String(value)`: `null` → `"null"`, booleans → `"true"` /
/// `"false"`, numbers → numeric repr (whole-valued doubles render
/// without a decimal, `NaN` / `±Infinity` keep their JS spellings),
/// strings unchanged, arrays via `Array.prototype.join(",")` (where
/// `null` elements render as the empty string), objects as
/// `"[object Object]"`.
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

/// `Array.prototype.toString()` ≡ `Array.prototype.join(",")`. Renders
/// each element via `jsArrayElementString`, then comma-joins.
func jsArrayJoin(_ items: [Value]) -> String {
    items.map(jsArrayElementString).joined(separator: ",")
}

/// JS `Array.prototype.join` element rendering: `null` / `undefined`
/// render as the empty string (not `"null"`); everything else uses
/// `jsString`.
func jsArrayElementString(_ value: Value) -> String {
    if case .null = value { return "" }
    return jsString(value)
}

/// JS `String(number)` for the cases that show up in real rule data:
/// whole-number doubles render without a decimal (`String(1.0) === "1"`),
/// `NaN` / `±Infinity` keep their JS spellings, fractional doubles use
/// Swift's default rendering (matches JS for non-pathological values).
///
/// Known divergence from JS: for values beyond exact integer round-trip range,
/// we fall through to Swift's `String(Double)`, which may use scientific
/// notation earlier than JS (`1e19` → `"1e+19"` vs `"10000000000000000000"`).
/// This only surfaces through `var` path coercion or `looseEq`'s compound-vs-
/// primitive arm with pathological magnitudes.
func jsNumberString(_ value: Double) -> String {
    if value.isNaN { return "NaN" }
    if value.isInfinite { return value > 0 ? "Infinity" : "-Infinity" }
    if let int64 = Int64(exactly: value) { return String(int64) }
    return String(value)
}

/// JS `Object.prototype.toString.call(plainObject)` for any non-Array
/// object. JSON Logic only ever encounters plain objects, so the
/// fallback `"[object Object]"` is the only spelling we need.
let jsObjectString = "[object Object]"

/// JS `parseFloat(value)`. Stringifies via `jsString`, strips leading
/// whitespace, then parses the longest valid prefix as a JS
/// `StringNumericLiteral` (optional sign, digits with optional decimal,
/// optional decimal exponent, plus the `Infinity` literal). `null`
/// ("null"), bools ("true" / "false"), and the empty string yield `NaN`;
/// trailing junk is allowed (`"3.14abc"` → 3.14).
func jsParseFloat(_ value: Value) -> Double {
    if case .int(let value) = value { return Double(value) }
    if case .float(let value) = value { return value }
    return parseFloatPrefix(jsString(value))
}

private let numericPrefixPattern = #"^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?"#

private func parseFloatPrefix(_ string: String) -> Double {
    let trimmed = string.drop(while: \.isWhitespace)
    guard !trimmed.isEmpty else { return .nan }
    let str = String(trimmed)
    if str.hasPrefix("Infinity") { return .infinity }
    if str.hasPrefix("-Infinity") { return -.infinity }
    if str.hasPrefix("+Infinity") { return .infinity }
    guard let match = str.range(of: numericPrefixPattern, options: .regularExpression),
          match.lowerBound == str.startIndex else {
        return .nan
    }
    return Double(str[match]) ?? .nan
}

/// JSON Logic strict equality (`===`). Same type, same value. `int(1)`
/// and `float(1.0)` compare equal — they represent the same JS `Number`.
/// Arrays and objects always compare unequal (JS reference identity;
/// see `looseEq` for the same rationale).
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
    default:
        return false
    }
}
