//
//  MinMaxOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Numeric extrema: `min`, `max`.
///
/// Both follow the json-logic-js spec: variadic over a flat list of values
/// (`{"max": [v1, v2, ...]}` / `{"min": [v1, v2, ...]}`). Each argument is
/// evaluated independently in the current scope; there is no iteration,
/// no per-item scope rebinding, and no projection — same shape as the
/// scalar arithmetic operators `+` / `*`.
///
/// Reference behavior is JS `Math.max` / `Math.min` applied to the
/// evaluated arguments. Operands that can't be coerced to a number
/// (`.object`, `.array`, unparseable strings) become `Double.nan` and
/// poison the result so a malformed predicate fails closed in the
/// expected comparison (`>= 4`, `<= 0`, etc., where any comparison
/// against NaN returns `false`).
///
/// Empty input mirrors `Math.max()` / `Math.min()`: `max` → `-∞`,
/// `min` → `+∞`. The fixed-empty values are picked so chaining a
/// `max(empty)` against a numeric threshold reads as "no value
/// satisfies" without needing a separate empty guard at the
/// rule-authoring level.
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
    /// to `nan` for non-numeric operands so the caller can short-circuit
    /// on a poisoned input.
    private static func evaluateAsNumbers(_ args: Value, vars: Value) throws -> [Double] {
        try Operators.evalArgs(args, vars: vars).map { $0.asNumber ?? .nan }
    }
}
