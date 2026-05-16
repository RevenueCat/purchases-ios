//
//  LogicOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Logic operators: `!`, `!!`, `and`, `or`, `if`.
///
/// `and`, `or`, and `if` short-circuit and therefore can't use the eager
/// `evalArgs` helpers — they evaluate their arguments one at a time.
enum LogicOperators {

    /// `{"!": x}` — boolean negation. Coerces to bool first per JSON Logic
    /// truthiness rules.
    static func opNot(
        args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> Value {
        let value = try firstArgEvaluated(args, vars: vars, logger: logger)
        return .bool(!value.isTruthy)
    }

    /// `{"!!": x}` — boolean cast. Spec: equivalent to `!!x` in JS.
    static func opNotNot(
        args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> Value {
        let value = try firstArgEvaluated(args, vars: vars, logger: logger)
        return .bool(value.isTruthy)
    }

    /// `{"and": [a, b, c]}` — short-circuit AND. Returns the first falsy
    /// value or, if all are truthy, the last value (matches JS / JSON Logic
    /// semantics: `and` returns the actual value, not a coerced boolean).
    static func opAnd(
        args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> Value {
        let items = Operators.argsAsList(args)
        if items.isEmpty {
            return .bool(true) // vacuous truth
        }
        var last: Value = .bool(true)
        for item in items {
            last = try Evaluator.evaluateValue(item, vars: vars, logger: logger)
            if !last.isTruthy {
                return last
            }
        }
        return last
    }

    /// `{"or": [a, b, c]}` — short-circuit OR. Returns the first truthy
    /// value or, if all are falsy, the last value.
    static func opOr(
        args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> Value {
        let items = Operators.argsAsList(args)
        if items.isEmpty {
            return .bool(false)
        }
        var last: Value = .bool(false)
        for item in items {
            last = try Evaluator.evaluateValue(item, vars: vars, logger: logger)
            if last.isTruthy {
                return last
            }
        }
        return last
    }

    /// `{"if": [cond, then, else]}` — also supports chained
    /// `[c1, t1, c2, t2, ..., else]` (think `else if`). Without an `else`
    /// clause and with no truthy condition, returns `null`.
    static func opIf(
        args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> Value {
        let items = Operators.argsAsList(args)
        if items.isEmpty {
            return .null
        }
        var index = 0
        while index + 1 < items.count {
            let condition = try Evaluator.evaluateValue(items[index], vars: vars, logger: logger)
            if condition.isTruthy {
                return try Evaluator.evaluateValue(items[index + 1], vars: vars, logger: logger)
            }
            index += 2
        }
        if index < items.count {
            return try Evaluator.evaluateValue(items[index], vars: vars, logger: logger)
        }
        return .null
    }

    // MARK: - Helpers

    private static func firstArgEvaluated(
        _ args: Value,
        vars: Value,
        logger: RulesEngineLogger
    ) throws -> Value {
        let items = Operators.argsAsList(args)
        let first = items.first ?? .null
        return try Evaluator.evaluateValue(first, vars: vars, logger: logger)
    }
}
