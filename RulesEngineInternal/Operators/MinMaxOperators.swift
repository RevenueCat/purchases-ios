//
//  MinMaxOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Numeric extrema: `min`, `max`.
///
/// Variadic over a flat list of values (`{"max": [v1, v2, ...]}` /
/// `{"min": [v1, v2, ...]}`), matching JS `Math.max` / `Math.min`. Each
/// operand goes through `Value.asNumber` (JS `Number()`), so
/// single-element arrays bridge to a number via `toString`
/// (`Math.max(1, [2]) === 2`); multi-element arrays, objects, and
/// unparseable strings become `Double.nan` and poison the result.
///
/// Empty input mirrors `Math.max()` / `Math.min()`: `max` → `-∞`,
/// `min` → `+∞`.
enum MinMaxOperators {

    /// `{"max": [v1, v2, ...]}` — variadic numeric maximum.
    static func opMax(args: Value, vars: Value) throws -> Value {
        let numbers = try evaluateAsNumbers(args, vars: vars)
        if numbers.contains(where: { $0.isNaN }) { return .float(.nan) }
        return .float(numbers.max() ?? -.infinity)
    }

    /// `{"min": [v1, v2, ...]}` — variadic numeric minimum.
    static func opMin(args: Value, vars: Value) throws -> Value {
        let numbers = try evaluateAsNumbers(args, vars: vars)
        if numbers.contains(where: { $0.isNaN }) { return .float(.nan) }
        return .float(numbers.min() ?? .infinity)
    }

    /// Evaluate each argument and coerce it to `Double`, falling back
    /// to `nan` for non-numeric operands.
    private static func evaluateAsNumbers(_ args: Value, vars: Value) throws -> [Double] {
        try Operators.evalArgs(args, vars: vars).map { $0.asNumber ?? .nan }
    }
}
