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
internal enum Operators {

    /// Dispatch a JSON Logic operator. Throws `RuleError.unsupportedOperator`
    /// when the operator name isn't implemented in this slice.
    // swiftlint:disable:next cyclomatic_complexity
    static func dispatch(
        op operatorName: String,
        args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> Value {
        switch operatorName {
        case "var":
            return try AccessorOperators.opVar(args: args, vars: vars, logger: logger)
        case "missing":
            return try AccessorOperators.opMissing(args: args, vars: vars, logger: logger)

        case "==":
            return try EqualityOperators.opLooseEq(args: args, vars: vars, logger: logger)
        case "!=":
            return try EqualityOperators.opLooseNe(args: args, vars: vars, logger: logger)
        case "===":
            return try EqualityOperators.opStrictEq(args: args, vars: vars, logger: logger)
        case "!==":
            return try EqualityOperators.opStrictNe(args: args, vars: vars, logger: logger)

        case "!":
            return try LogicOperators.opNot(args: args, vars: vars, logger: logger)
        case "!!":
            return try LogicOperators.opNotNot(args: args, vars: vars, logger: logger)
        case "and":
            return try LogicOperators.opAnd(args: args, vars: vars, logger: logger)
        case "or":
            return try LogicOperators.opOr(args: args, vars: vars, logger: logger)
        case "if":
            return try LogicOperators.opIf(args: args, vars: vars, logger: logger)

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
    static func evalArgs(
        _ args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> [Value] {
        try argsAsList(args).map { try Evaluator.evaluateValue($0, vars: vars, logger: logger) }
    }

    /// Evaluate exactly two arguments. Used by binary operators (`==`, `!=`,
    /// `===`, `!==`, and the comparison operators a future iteration will
    /// add).
    static func evalTwo(
        _ args: Value,
        vars: Value,
        logger: RulesEngineLogger,
        opName: String
    ) throws -> (Value, Value) {
        let evaluated = try evalArgs(args, vars: vars, logger: logger)
        guard evaluated.count == 2 else {
            throw RuleError.typeMismatch(
                message: "operator '\(opName)' expects 2 arguments, got \(evaluated.count)"
            )
        }
        return (evaluated[0], evaluated[1])
    }
}
