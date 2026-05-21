//
//  ComparisonOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Comparison operators: `<`, `<=`, `>`, `>=`.
///
/// Mirrors the JSON Logic / ECMAScript Abstract Relational Comparison
/// rules:
///
/// - **Both operands are strings** → lexicographic comparison
///   (`"10" < "9"` is `true` because `'1' < '9'` byte-wise).
/// - **Otherwise** → coerce both operands to `Double` via
///   `Value.asNumber` and compare numerically. Operands that can't
///   coerce (`.object`, `.array`, unparseable strings) become
///   `Double.nan`; per IEEE 754 any comparison against `nan` returns
///   `false`, so a malformed operand makes the predicate fail closed.
///
/// `<` and `<=` accept a 3-arg "between" form per the JSON Logic spec:
/// `{"<": [a, b, c]}` reads as `a < b AND b < c`. `>` and `>=` are
/// binary only, matching the JS reference.
enum ComparisonOperators {

    /// `{"<": [a, b]}` — `a < b`. `{"<": [a, b, c]}` — `a < b AND b < c`.
    static func opLt(args: Value, vars: Value) throws -> Value {
        try evalChain(args, vars: vars, opName: "<", using: .less)
    }

    /// `{"<=": [a, b]}` — `a <= b`. `{"<=": [a, b, c]}` — `a <= b AND b <= c`.
    static func opLe(args: Value, vars: Value) throws -> Value {
        try evalChain(args, vars: vars, opName: "<=", using: .lessOrEqual)
    }

    /// `{">": [a, b]}` — `a > b`. Strictly binary; matches the JS reference.
    static func opGt(args: Value, vars: Value) throws -> Value {
        try evalBinary(args, vars: vars, opName: ">", using: .greater)
    }

    /// `{">=": [a, b]}` — `a >= b`. Strictly binary; matches the JS reference.
    static func opGe(args: Value, vars: Value) throws -> Value {
        try evalBinary(args, vars: vars, opName: ">=", using: .greaterOrEqual)
    }

    /// Comparator dispatch: factored out so the same enum case drives both
    /// the `String` (lex) and `Double` (numeric) paths in `compare`.
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

    /// Two-string operands → lex. Otherwise → numeric coercion. Encodes
    /// the JSON Logic / JS spec's Abstract Relational Comparison split.
    private static func compare(_ lhs: Value, _ rhs: Value, using cmp: Comparator) -> Bool {
        if case .string(let left) = lhs, case .string(let right) = rhs {
            return cmp.apply(left, right)
        }
        return cmp.apply(asDouble(lhs), asDouble(rhs))
    }

    /// Shared 2-or-3 arg "chain" evaluator used by `<` and `<=`. The 3-arg
    /// form is the JSON Logic between-form: each adjacent pair must
    /// satisfy `cmp`.
    private static func evalChain(
        _ args: Value,
        vars: Value,
        opName: String,
        using cmp: Comparator
    ) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        switch evaluated.count {
        case 2:
            return .bool(compare(evaluated[0], evaluated[1], using: cmp))
        case 3:
            return .bool(
                compare(evaluated[0], evaluated[1], using: cmp)
                    && compare(evaluated[1], evaluated[2], using: cmp)
            )
        default:
            throw RuleError.typeMismatch(
                message: "operator '\(opName)' expects 2 or 3 arguments, got \(evaluated.count)"
            )
        }
    }

    /// Shared 2-arg evaluator used by `>` and `>=`. No between-form per the
    /// JSON Logic spec / JS reference.
    private static func evalBinary(
        _ args: Value,
        vars: Value,
        opName: String,
        using cmp: Comparator
    ) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        guard evaluated.count == 2 else {
            throw RuleError.typeMismatch(
                message: "operator '\(opName)' expects 2 arguments, got \(evaluated.count)"
            )
        }
        return .bool(compare(evaluated[0], evaluated[1], using: cmp))
    }

    /// Coerce to `Double`, falling back to `nan` for non-numeric operands
    /// so comparisons against malformed inputs return `false` per
    /// IEEE 754.
    private static func asDouble(_ value: Value) -> Double {
        value.asNumber ?? .nan
    }
}
