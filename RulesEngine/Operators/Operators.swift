//
//  Operators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// JSON Logic operator dispatcher and shared helpers.
///
/// Operators are responsible for evaluating their own arguments. Most use
/// the `evalTwo` / `evalArgs` helpers which evaluate eagerly; short-circuit
/// operators (`and`, `or`, `if`) iterate manually.
enum Operators {

    /// Dispatch a JSON Logic operator. Throws `RuleError.unsupportedOperator`
    /// when the operator name isn't implemented in this slice.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func dispatch(
        op operatorName: String,
        args: Value,
        vars: Value
    ) throws -> Value {
        switch operatorName {
        case "var":
            return try AccessorOperators.opVar(args: args, vars: vars)
        case "missing":
            return try AccessorOperators.opMissing(args: args, vars: vars)
        case "missing_some":
            return try AccessorOperators.opMissingSome(args: args, vars: vars)

        case "==":
            return try EqualityOperators.opLooseEq(args: args, vars: vars)
        case "!=":
            return try EqualityOperators.opLooseNe(args: args, vars: vars)
        case "===":
            return try EqualityOperators.opStrictEq(args: args, vars: vars)
        case "!==":
            return try EqualityOperators.opStrictNe(args: args, vars: vars)

        case "!":
            return try LogicOperators.opNot(args: args, vars: vars)
        case "!!":
            return try LogicOperators.opNotNot(args: args, vars: vars)
        case "and":
            return try LogicOperators.opAnd(args: args, vars: vars)
        case "or":
            return try LogicOperators.opOr(args: args, vars: vars)
        case "if":
            return try LogicOperators.opIf(args: args, vars: vars)

        case "+":
            return try ArithmeticOperators.opAdd(args: args, vars: vars)
        case "-":
            return try ArithmeticOperators.opSub(args: args, vars: vars)
        case "*":
            return try ArithmeticOperators.opMul(args: args, vars: vars)
        case "/":
            return try ArithmeticOperators.opDiv(args: args, vars: vars)
        case "%":
            return try ArithmeticOperators.opMod(args: args, vars: vars)

        case "<":
            return try ComparisonOperators.opLt(args: args, vars: vars)
        case "<=":
            return try ComparisonOperators.opLe(args: args, vars: vars)
        case ">":
            return try ComparisonOperators.opGt(args: args, vars: vars)
        case ">=":
            return try ComparisonOperators.opGe(args: args, vars: vars)

        case "in":
            return try StringArrayOperators.opIn(args: args, vars: vars)
        case "cat":
            return try StringArrayOperators.opCat(args: args, vars: vars)
        case "substr":
            return try StringArrayOperators.opSubstr(args: args, vars: vars)
        case "merge":
            return try StringArrayOperators.opMerge(args: args, vars: vars)

        default:
            throw RuleError.unsupportedOperator(name: operatorName)
        }
    }

    // MARK: - Shared helpers

    /// Treat an operator argument as an argument list. Per JSON Logic, a
    /// single-value argument is implicitly wrapped in a one-element list,
    /// so `{"!": true}` and `{"!": [true]}` are equivalent.
    static func argsAsList(_ args: Value) -> [Value] {
        if case .array(let items) = args {
            return items
        }
        return [args]
    }

    /// Evaluate every element in an argument list.
    static func evalArgs(_ args: Value, vars: Value) throws -> [Value] {
        try argsAsList(args).map { try Evaluator.evaluateValue($0, vars: vars) }
    }

    /// Evaluate exactly two arguments. Used by binary operators (`==`, `!=`,
    /// `===`, `!==`, and the comparison operators a future iteration will
    /// add).
    static func evalTwo(
        _ args: Value,
        vars: Value,
        opName: String
    ) throws -> (Value, Value) {
        let evaluated = try evalArgs(args, vars: vars)
        guard evaluated.count == 2 else {
            throw RuleError.typeMismatch(
                message: "operator '\(opName)' expects 2 arguments, got \(evaluated.count)"
            )
        }
        return (evaluated[0], evaluated[1])
    }

    /// Safely truncate a `Double` to `Int` for index / count math. The
    /// default `Int(_:)` initializer traps on `NaN`, `±Infinity`, and
    /// out-of-range finite values — and a malformed predicate can easily
    /// produce any of those (`asNumber` returns raw NaN for `.float(.nan)`,
    /// for arithmetic on non-numeric operands, or for `Double("nan")` /
    /// `Double("inf")` parses of `.string`). NaN coerces to `0` (mirroring
    /// JS `ToInteger`); `±Infinity` and out-of-range values clamp to
    /// `Int.max` / `Int.min` so downstream `min` / `max` clamping handles
    /// them naturally.
    static func clampedInt(_ value: Double) -> Int {
        if value.isNaN { return 0 }
        if value >= Double(Int.max) { return .max }
        if value <= Double(Int.min) { return .min }
        return Int(value)
    }
}
