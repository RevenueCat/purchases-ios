//
//  ArithmeticOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Arithmetic operators: `+`, `-`, `*`, `/`, `%`.
///
/// All operators return `.float(Double)`. `json-logic-js` is asymmetric
/// about which JS coercion each operator uses, and we replicate that:
///
/// - `+` and `*` go through `parseFloat(value)` — `value` is stringified
///   first, then the longest numeric prefix is parsed. `null`, bools,
///   the empty string, and `[1,2]` all yield `NaN`; `"3.14abc"` parses
///   as `3.14`. See `jsParseFloat`.
/// - `-`, `/`, `%` use native JS arithmetic which calls `Number(value)`
///   — bool / null / empty-string become `0`, arrays / objects coerce
///   via `ToPrimitive("number")` → `toString` → recurse. `[]` → `0`,
///   `[1]` → `1`, `[1,2]` → `NaN`. See `Value.asNumber`.
///
/// Division and modulo by zero produce the IEEE 754 values (`±Infinity`
/// for `n / 0` with `n ≠ 0`, `NaN` for `0 / 0` and any `n % 0`), matching
/// `json-logic-js`.
enum ArithmeticOperators {

    /// `{"+": [a, b, ...]}` — variadic sum, seeded with `0`. 0 arguments
    /// returns `0`. Each operand is coerced via JS `parseFloat`.
    static func opAdd(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let sum = evaluated.reduce(0.0) { $0 + jsParseFloat($1) }
        return .float(sum)
    }

    /// `{"*": [a, b, ...]}` — variadic product, no seed (matches
    /// `Array.prototype.reduce` without an initial value). The 1-arg form
    /// returns the operand unchanged (no `parseFloat` coercion). 0
    /// arguments is a `.typeMismatch` to mirror `[].reduce(fn)` throwing.
    static func opMul(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        guard let head = evaluated.first else {
            throw RulesEngine.EvaluationError.typeMismatch(message: "operator '*' requires at least 1 argument")
        }
        guard evaluated.count > 1 else { return head }
        let product = evaluated.dropFirst().reduce(jsParseFloat(head)) { $0 * jsParseFloat($1) }
        return .float(product)
    }

    /// `{"-": [a]}` — unary negation. `{"-": [a, b]}` — subtraction.
    /// `{"-": [a, b, ...]}` ignores extra operands. `{"-": []}` returns
    /// `NaN` (mirroring JS `-undefined`). Operands are coerced via JS
    /// `Number()` (`asNumber`).
    static func opSub(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let lhs = evaluated.first.map(asDouble) ?? .nan
        if evaluated.count >= 2 {
            return .float(lhs - asDouble(evaluated[1]))
        }
        return .float(-lhs)
    }

    /// `{"/": [a, b]}` — division. Extra operands are ignored; missing
    /// operands resolve to `NaN` (mirroring JS `undefined / x`). Division
    /// by zero follows IEEE 754: `n / 0` is `±Infinity`, `0 / 0` is `NaN`.
    static func opDiv(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try evalDivisorPair(args, vars: vars)
        return .float(lhs / rhs)
    }

    /// `{"%": [a, b]}` — modulo. Same arity / coercion rules as `/`;
    /// `n % 0` follows IEEE 754 and is `NaN`.
    static func opMod(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try evalDivisorPair(args, vars: vars)
        return .float(lhs.truncatingRemainder(dividingBy: rhs))
    }

    /// Evaluate two operands into `Double`, defaulting missing operands
    /// to `NaN` (mirroring JS `undefined`). Extra operands are ignored.
    private static func evalDivisorPair(_ args: Value, vars: Value) throws -> (Double, Double) {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        let lhs = evaluated.first.map(asDouble) ?? .nan
        let rhs = evaluated.count >= 2 ? asDouble(evaluated[1]) : .nan
        return (lhs, rhs)
    }

    /// `Number(value)`-style coercion for `-`, `/`, `%`. Falls back to
    /// `nan` for non-numeric operands. `+` and `*` use `jsParseFloat`.
    private static func asDouble(_ value: Value) -> Double {
        value.asNumber ?? .nan
    }
}
