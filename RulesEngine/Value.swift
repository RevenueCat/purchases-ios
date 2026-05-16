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
internal enum Value: Equatable {

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

    /// Best-effort numeric coercion used by loose comparison. Mirrors JS
    /// `ToNumber` (partial): bool→0/1, int/float→self, string→parsed (or
    /// `nil` if unparseable), null→0, everything else→`nil`.
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
            return nil
        }
    }
}

/// JSON Logic loose equality (`==`). Best-effort JS-style coercion for the
/// common primitive cases. Arrays/objects compare structurally (deviates
/// from JS reference identity but is more useful for rule authors).
// swiftlint:disable:next cyclomatic_complexity
internal func looseEq(_ lhs: Value, _ rhs: Value) -> Bool {
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

    default:
        if let leftNumber = lhs.asNumber, let rightNumber = rhs.asNumber {
            return leftNumber == rightNumber
        }
        return false
    }
}

/// JSON Logic strict equality (`===`). Same type, same value. Numeric
/// strict-eq treats `int(1)` and `float(1.0)` as equal — they represent the
/// same JS `Number`, and our split is an internal modeling choice.
// swiftlint:disable:next cyclomatic_complexity
internal func strictEq(_ lhs: Value, _ rhs: Value) -> Bool {
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
