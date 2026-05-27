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

    /// `{"+": [a, b, ...]}` — variadic sum. Each operand is coerced via
    /// JS `parseFloat`. The 1-arg form acts as a numeric cast
    /// (`{"+": ["3.14"]}` → `3.14`, but `{"+": [true]}` → `NaN` because
    /// `parseFloat("true")` is `NaN`). 0 arguments is a `.typeMismatch`.
    static func opAdd(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        guard !evaluated.isEmpty else {
            throw RuleError.typeMismatch(message: "operator '+' requires at least 1 argument")
        }
        let sum = evaluated.reduce(0.0) { $0 + jsParseFloat($1) }
        return .float(sum)
    }

    /// `{"*": [a, b, ...]}` — variadic product. Each operand is coerced
    /// via JS `parseFloat` (same rules as `+`). 0 arguments is a
    /// `.typeMismatch`.
    static func opMul(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        guard !evaluated.isEmpty else {
            throw RuleError.typeMismatch(message: "operator '*' requires at least 1 argument")
        }
        let product = evaluated.reduce(1.0) { $0 * jsParseFloat($1) }
        return .float(product)
    }

    /// `{"-": [a]}` — unary negation. `{"-": [a, b]}` — subtraction.
    /// Operands are coerced via JS `Number()` (`asNumber`). Other arities
    /// are a `.typeMismatch`.
    static func opSub(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        switch evaluated.count {
        case 1:
            return .float(-asDouble(evaluated[0]))
        case 2:
            return .float(asDouble(evaluated[0]) - asDouble(evaluated[1]))
        default:
            throw RuleError.typeMismatch(
                message: "operator '-' expects 1 or 2 arguments, got \(evaluated.count)"
            )
        }
    }

    /// `{"/": [a, b]}` — division. Operands are coerced via JS `Number()`
    /// (`asNumber`). Division by zero follows IEEE 754: `n / 0` is
    /// `±Infinity` (sign matches the dividend), `0 / 0` is `NaN`.
    static func opDiv(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "/")
        return .float(asDouble(lhs) / asDouble(rhs))
    }

    /// `{"%": [a, b]}` — modulo. Operands are coerced via JS `Number()`
    /// (`asNumber`). `n % 0` follows IEEE 754 and is `NaN`.
    static func opMod(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "%")
        return .float(asDouble(lhs).truncatingRemainder(dividingBy: asDouble(rhs)))
    }

    /// `Number(value)`-style coercion for `-`, `/`, `%`. Falls back to
    /// `nan` for non-numeric operands. `+` and `*` use `jsParseFloat`.
    private static func asDouble(_ value: Value) -> Double {
        value.asNumber ?? .nan
    }
}
