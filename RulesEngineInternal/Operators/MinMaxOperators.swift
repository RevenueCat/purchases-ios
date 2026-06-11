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
        try reduceExtremum(args, vars: vars, empty: -.infinity) { Swift.max($0, $1) }
    }

    /// `{"min": [v1, v2, ...]}` — variadic numeric minimum.
    static func opMin(args: Value, vars: Value) throws -> Value {
        try reduceExtremum(args, vars: vars, empty: .infinity) { Swift.min($0, $1) }
    }

    /// Evaluate each operand to a `Double` (non-numeric → `nan`) and fold
    /// it into a single extremum in one pass. `empty` is the no-operand
    /// result (`Math.max()` → `-∞`, `Math.min()` → `+∞`); any `nan`
    /// operand poisons the accumulator, mirroring `Math.max` / `Math.min`.
    private static func reduceExtremum(
        _ args: Value,
        vars: Value,
        empty: Double,
        combine: (Double, Double) -> Double
    ) throws -> Value {
        let result = try Operators.evalArgs(args, vars: vars).reduce(empty) { accumulator, value in
            let number = value.asNumber ?? .nan
            guard !accumulator.isNaN, !number.isNaN else { return .nan }
            return combine(accumulator, number)
        }
        return .float(result)
    }
}
