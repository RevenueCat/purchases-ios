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
    static func opNot(args: Value, vars: Value) throws -> Value {
        let value = try firstArgEvaluated(args, vars: vars)
        return .bool(!value.isTruthy)
    }

    /// `{"!!": x}` — boolean cast. Spec: equivalent to `!!x` in JS.
    static func opNotNot(args: Value, vars: Value) throws -> Value {
        let value = try firstArgEvaluated(args, vars: vars)
        return .bool(value.isTruthy)
    }

    /// `{"and": [a, b, c]}` — short-circuit AND. Returns the first falsy
    /// value or, if all are truthy, the last value (matches JS / JSON Logic:
    /// `and` returns the actual value, not a coerced boolean). Empty input
    /// returns `.null`.
    static func opAnd(args: Value, vars: Value) throws -> Value {
        let items = Operators.argsAsList(args)
        var last: Value = .null
        for item in items {
            last = try Evaluator.evaluateValue(item, vars: vars)
            if !last.isTruthy {
                return last
            }
        }
        return last
    }

    /// `{"or": [a, b, c]}` — short-circuit OR. Returns the first truthy
    /// value or, if all are falsy, the last value. Empty input returns
    /// `.null`.
    static func opOr(args: Value, vars: Value) throws -> Value {
        let items = Operators.argsAsList(args)
        var last: Value = .null
        for item in items {
            last = try Evaluator.evaluateValue(item, vars: vars)
            if last.isTruthy {
                return last
            }
        }
        return last
    }

    /// `{"if": [cond, then, else]}` — also supports chained
    /// `[c1, t1, c2, t2, ..., else]` (think `else if`). Without an `else`
    /// clause and with no truthy condition, returns `null`.
    static func opIf(args: Value, vars: Value) throws -> Value {
        let items = Operators.argsAsList(args)
        var index = 0
        while index + 1 < items.count {
            let condition = try Evaluator.evaluateValue(items[index], vars: vars)
            if condition.isTruthy {
                return try Evaluator.evaluateValue(items[index + 1], vars: vars)
            }
            index += 2
        }
        if index < items.count {
            return try Evaluator.evaluateValue(items[index], vars: vars)
        }
        return .null
    }

    // MARK: - Helpers

    private static func firstArgEvaluated(_ args: Value, vars: Value) throws -> Value {
        let items = Operators.argsAsList(args)
        let first = items.first ?? .null
        return try Evaluator.evaluateValue(first, vars: vars)
    }
}
