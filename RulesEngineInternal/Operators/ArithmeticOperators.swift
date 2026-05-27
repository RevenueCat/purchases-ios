//
//  ArithmeticOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Arithmetic operators: `+`, `-`, `*`, `/`, `%`.
///
/// All operators return `.float(Double)` regardless of operand types. JSON
/// Logic in JS coerces every operand to a number before arithmetic, so
/// preserving an `.int` result would be a per-call decision with no spec
/// support. `looseEq` and `strictEq` already bridge `.int(n) ↔
/// .float(n.0)`, so callers comparing an arithmetic result to an integer
/// literal still get the expected answer.
///
/// `json-logic-js` is asymmetric about *which* JS coercion it uses, and we
/// faithfully replicate that asymmetry:
///
/// - `+` and `*` go through `parseFloat(value)` — `value` is stringified
///   first, then the longest numeric prefix is parsed. So `null`, bools,
///   the empty string, and `[1,2]` (which stringifies to `"1,2"`) all
///   yield `NaN`, while `"3.14abc"` parses as `3.14`. See `jsParseFloat`.
/// - `-`, `/`, `%` use native JS arithmetic which calls `Number(value)`
///   (a.k.a. `ToNumber`) — bool / null / empty-string become `0`, and
///   arrays / objects coerce via `ToPrimitive("number")` → `toString` →
///   recurse. So `[]` → `0`, `[1]` → `1`, `[1,2]` → `NaN`. See
///   `Value.asNumber`.
///
/// Operands that can't be coerced (`.object`, multi-element arrays,
/// unparseable strings, anything that hits `parseFloat`'s strict cases)
/// become `Double.nan` and propagate naturally — the final result is
/// `.float(nan)`, which `isTruthy` reports as falsy.
///
/// Division and modulo by zero return `.null` instead of `infinity` /
/// `nan`. JSON Logic JS produces the IEEE values, but for rule authoring
/// `null` is friendlier: it short-circuits comparisons in a predictable
/// way and matches the engine's "missing value" convention. This is the
/// one intentional deviation from the spec in this file.
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
    /// (`asNumber`). Division by zero returns `.null` (see type docs).
    static func opDiv(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "/")
        let divisor = asDouble(rhs)
        if divisor == 0.0 {
            return .null
        }
        return .float(asDouble(lhs) / divisor)
    }

    /// `{"%": [a, b]}` — modulo. Operands are coerced via JS `Number()`
    /// (`asNumber`). Modulo by zero returns `.null` (see type docs).
    static func opMod(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "%")
        let divisor = asDouble(rhs)
        if divisor == 0.0 {
            return .null
        }
        return .float(asDouble(lhs).truncatingRemainder(dividingBy: divisor))
    }

    /// `Number(value)`-style coercion for `-`, `/`, `%`. Falls back to
    /// `nan` so arithmetic propagates the failure without raising an
    /// error. `+` and `*` use `jsParseFloat` instead — see type docs.
    private static func asDouble(_ value: Value) -> Double {
        value.asNumber ?? .nan
    }
}
