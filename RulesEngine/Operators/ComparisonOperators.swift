//
//  ComparisonOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Comparison operators: `<`, `<=`, `>`, `>=`.
///
/// All operators coerce operands through `Value.asNumber` and compare as
/// `Double`. Operands that don't coerce (`.object`, `.array`, unparseable
/// strings) become `Double.nan`; per IEEE 754 every comparison against
/// `nan` returns `false`, so a malformed operand makes the predicate fail
/// closed — a safe default for rule authoring.
///
/// `<` and `<=` accept a 3-arg "between" form per the JSON Logic spec:
/// `{"<": [a, b, c]}` reads as `a < b AND b < c`. `>` and `>=` are binary
/// only, matching the JS reference implementation.
///
/// Note on string semantics: the JS reference compares two strings
/// lexicographically (`"10" < "9"` is true) and only coerces when types
/// mix. We always coerce numerically, which gives the more intuitive
/// `"10" < "9"` is false.
enum ComparisonOperators {

    /// `{"<": [a, b]}` — `a < b`. `{"<": [a, b, c]}` — `a < b AND b < c`.
    static func opLt(args: Value, vars: Value) throws -> Value {
        try evalChain(args, vars: vars, opName: "<", cmp: <)
    }

    /// `{"<=": [a, b]}` — `a <= b`. `{"<=": [a, b, c]}` — `a <= b AND b <= c`.
    static func opLe(args: Value, vars: Value) throws -> Value {
        try evalChain(args, vars: vars, opName: "<=", cmp: <=)
    }

    /// `{">": [a, b]}` — `a > b`. Strictly binary; matches the JS reference.
    static func opGt(args: Value, vars: Value) throws -> Value {
        try evalBinary(args, vars: vars, opName: ">", cmp: >)
    }

    /// `{">=": [a, b]}` — `a >= b`. Strictly binary; matches the JS reference.
    static func opGe(args: Value, vars: Value) throws -> Value {
        try evalBinary(args, vars: vars, opName: ">=", cmp: >=)
    }

    /// Shared 2-or-3 arg "chain" evaluator used by `<` and `<=`. The 3-arg
    /// form is the JSON Logic between-form: each adjacent pair must
    /// satisfy `cmp`.
    private static func evalChain(
        _ args: Value,
        vars: Value,
        opName: String,
        cmp: (Double, Double) -> Bool
    ) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        switch evaluated.count {
        case 2:
            return .bool(cmp(asDouble(evaluated[0]), asDouble(evaluated[1])))
        case 3:
            let (left, mid, right) = (
                asDouble(evaluated[0]),
                asDouble(evaluated[1]),
                asDouble(evaluated[2])
            )
            return .bool(cmp(left, mid) && cmp(mid, right))
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
        cmp: (Double, Double) -> Bool
    ) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        guard evaluated.count == 2 else {
            throw RuleError.typeMismatch(
                message: "operator '\(opName)' expects 2 arguments, got \(evaluated.count)"
            )
        }
        return .bool(cmp(asDouble(evaluated[0]), asDouble(evaluated[1])))
    }

    /// Coerce to `Double`, falling back to `nan` for non-numeric operands
    /// so comparisons against malformed inputs return `false` per
    /// IEEE 754.
    private static func asDouble(_ value: Value) -> Double {
        value.asNumber ?? .nan
    }
}
