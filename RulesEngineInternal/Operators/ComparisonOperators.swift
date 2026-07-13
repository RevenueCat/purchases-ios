//
//  ComparisonOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Comparison operators: `<`, `<=`, `>`, `>=`.
///
/// Per JSON Logic:
///
/// - After `ToPrimitive` (number hint), **both operands are strings**
///   → lexicographic comparison (`"10" < "9"` is `true`). Arrays and
///   objects stringify first (`[] < "a"` → `"" < "a"` → `true`).
/// - **Otherwise** → coerce both operands to `Double` via
///   `Value.asNumber` and compare numerically (`"10" < 9` → `false`).
///   Unparseable strings and objects compared numerically become
///   `Double.nan`; per IEEE 754 any comparison against `nan` returns
///   `false`.
///
/// `<` and `<=` accept a 3-arg "between" form per the JSON Logic spec:
/// `{"<": [a, b, c]}` reads as `a < b AND b < c`. `>` and `>=` are
/// binary only.
enum ComparisonOperators {

    /// `{"<": [a, b]}` — `a < b`. `{"<": [a, b, c]}` — `a < b AND b < c`.
    static func opLt(args: Value, vars: Value) throws -> Value {
        try evalChain(args, vars: vars, using: .less)
    }

    /// `{"<=": [a, b]}` — `a <= b`. `{"<=": [a, b, c]}` — `a <= b AND b <= c`.
    static func opLe(args: Value, vars: Value) throws -> Value {
        try evalChain(args, vars: vars, using: .lessOrEqual)
    }

    /// `{">": [a, b]}` — `a > b`. Strictly binary.
    static func opGt(args: Value, vars: Value) throws -> Value {
        try evalBinary(args, vars: vars, using: .greater)
    }

    /// `{">=": [a, b]}` — `a >= b`. Strictly binary.
    static func opGe(args: Value, vars: Value) throws -> Value {
        try evalBinary(args, vars: vars, using: .greaterOrEqual)
    }

    private enum Comparator {
        case less, lessOrEqual, greater, greaterOrEqual

        func apply<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool {
            switch self {
            case .less: return lhs < rhs
            case .lessOrEqual: return lhs <= rhs
            case .greater: return lhs > rhs
            case .greaterOrEqual: return lhs >= rhs
            }
        }
    }

    /// Mirrors JS `<`: `ToPrimitive` (number hint), lex when both are
    /// strings, else numeric. `nil` lhs/rhs is an omitted argument
    /// (`undefined` → `NaN` → `false`).
    private static func compare(_ lhs: Value?, _ rhs: Value?, using cmp: Comparator) -> Bool {
        guard let lhs, let rhs else {
            return cmp.apply(asDouble(lhs), asDouble(rhs))
        }
        let left = toPrimitiveForComparison(lhs)
        let right = toPrimitiveForComparison(rhs)
        if case .string(let leftString) = left, case .string(let rightString) = right {
            return cmp.apply(leftString, rightString)
        }
        return cmp.apply(asDouble(left), asDouble(right))
    }

    /// `ToPrimitive` with number hint: arrays/objects stringify; other
    /// primitives pass through unchanged.
    private static func toPrimitiveForComparison(_ value: Value) -> Value {
        switch value {
        case .string, .null, .undefined, .bool, .int, .float:
            return value
        case .array, .object:
            return .string(jsString(value))
        }
    }

    /// Shared 2-or-3 arg "chain" evaluator used by `<` and `<=`.
    /// `json-logic-js` declares the operator as `function(a, b, c)`:
    /// missing operands resolve to `undefined` (NaN comparisons are
    /// always `false`); the 3-arg form is the between-form
    /// (`a < b AND b < c`); arguments past the third are dropped.
    private static func evalChain(
        _ args: Value,
        vars: Value,
        using cmp: Comparator
    ) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let lhs = evaluated.first
        let mid = evaluated.indices.contains(1) ? evaluated[1] : nil
        if evaluated.count >= 3 {
            let rhs = evaluated[2]
            return .bool(compare(lhs, mid, using: cmp) && compare(mid, rhs, using: cmp))
        }
        return .bool(compare(lhs, mid, using: cmp))
    }

    /// Shared 2-arg evaluator used by `>` and `>=`. `json-logic-js`
    /// declares them as `function(a, b)`: extras are silently dropped
    /// and a missing operand becomes NaN (which makes any comparison
    /// `false`).
    private static func evalBinary(
        _ args: Value,
        vars: Value,
        using cmp: Comparator
    ) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let lhs = evaluated.first
        let rhs = evaluated.indices.contains(1) ? evaluated[1] : nil
        return .bool(compare(lhs, rhs, using: cmp))
    }

    /// Omitted arg or failed coercion → `nan`; `.null` → 0.
    private static func asDouble(_ value: Value?) -> Double {
        value?.asNumber ?? .nan
    }
}
