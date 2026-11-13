//
//  TimeOperators.swift
//
//  Created by Alvaro Marco.
//

import Foundation

extension RulesEngine {

    /// `rc.time_since`, `rc.time_until`, `rc.duration` and
    /// `rc.relative_date_start` — relative-date operators.
    ///
    /// These mirror the backend audience evaluator one to one, so a rule
    /// evaluates the same on device as on the server. Like the backend, they
    /// work in epoch **seconds**: timestamps in, seconds out.
    ///
    /// "Now" is the snapshot's `evaluated_at` (epoch milliseconds) read from the
    /// root scope, so every operator in one evaluation sees the same instant.
    /// A rule that needs "now" while `evaluated_at` is absent throws
    /// `EvaluationError.unresolvedVariable`.
    ///
    /// A `null` input returns `null` before "now" or the unit is read, as on the
    /// backend. Arity is exact, and an unknown unit or a non-numeric operand is
    /// `EvaluationError.typeMismatch`, where the backend rejects the rule.
    enum TimeOperators {

        /// `{"rc.time_since": [timestamp]}` — seconds elapsed since
        /// `timestamp`, floored at `0` so a future timestamp reads as "now".
        static func opTimeSince(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Self.evalArgs(args, vars: vars, count: 1, operatorName: "rc.time_since")
            guard let timestamp = try Self.number(evaluated[0], operatorName: "rc.time_since") else {
                return .null
            }
            return .float(max(0, try Self.nowSeconds(vars: vars) - timestamp))
        }

        /// `{"rc.time_until": [timestamp]}` — seconds left until `timestamp`,
        /// negative once it has passed.
        static func opTimeUntil(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Self.evalArgs(args, vars: vars, count: 1, operatorName: "rc.time_until")
            guard let timestamp = try Self.number(evaluated[0], operatorName: "rc.time_until") else {
                return .null
            }
            return .float(timestamp - (try Self.nowSeconds(vars: vars)))
        }

        /// `{"rc.duration": [value, unit]}` — `value` units in seconds. `unit`
        /// must be a literal `seconds`, `minutes`, `hours` or `days`, checked
        /// before `value` is evaluated, as the backend checks it when parsing.
        static func opDuration(args: Value, vars: Scope) throws -> Value {
            let operatorName = "rc.duration"
            let arguments = try Self.arguments(args, count: 2, operatorName: operatorName)
            let seconds = try Self.secondsPerUnit(arguments[1], operatorName: operatorName)
            let evaluatedValue = try Evaluator.evaluateValue(arguments[0], vars: vars)
            guard let value = try Self.number(evaluatedValue, operatorName: operatorName) else {
                return .null
            }
            return .float(value * seconds)
        }

        /// `{"rc.relative_date_start": [direction, value, unit]}` — the start of
        /// the UTC day `value` units before now (`direction` `"last"`) or after
        /// now (any other direction), in epoch seconds.
        static func opRelativeDateStart(args: Value, vars: Scope) throws -> Value {
            let operatorName = "rc.relative_date_start"
            let evaluated = try Self.evalArgs(args, vars: vars, count: 3, operatorName: operatorName)
            guard evaluated.allSatisfy({ !$0.isNullish }),
                  let value = try Self.number(evaluated[1], operatorName: operatorName) else {
                return .null
            }

            let offset = value * (try Self.secondsPerUnit(evaluated[2], operatorName: operatorName))
            let now = try Self.nowSeconds(vars: vars)
            let target = evaluated[0] == .string("last") ? now - offset : now + offset
            return .float((target / Self.secondsPerDay).rounded(.down) * Self.secondsPerDay)
        }
    }
}

private extension RulesEngine.TimeOperators {

    static let evaluatedAtKey = "evaluated_at"
    static let secondsPerDay: Double = 86_400
    static let secondsByUnit: [String: Double] = [
        "seconds": 1,
        "minutes": 60,
        "hours": 3_600,
        "days": 86_400
    ]

    /// Arity is checked before any argument is evaluated, as the backend
    /// rejects a wrong arity when parsing the rule.
    static func arguments(_ args: RulesEngine.Value, count: Int, operatorName: String) throws -> [RulesEngine.Value] {
        let arguments = RulesEngine.Operators.argsAsList(args)
        try RulesEngine.Operators.checkArity(arguments.count, allowed: [count], operatorName: operatorName)
        return arguments
    }

    static func evalArgs(
        _ args: RulesEngine.Value,
        vars: RulesEngine.Scope,
        count: Int,
        operatorName: String
    ) throws -> [RulesEngine.Value] {
        try Self.arguments(args, count: count, operatorName: operatorName)
            .map { try RulesEngine.Evaluator.evaluateValue($0, vars: vars) }
    }

    static func nowSeconds(vars: RulesEngine.Scope) throws -> Double {
        guard let evaluatedAt = RulesEngine.AccessorOperators.lookupVar(
            in: vars.root,
            path: Self.evaluatedAtKey
        ) else {
            throw RulesEngine.EvaluationError.unresolvedVariable(path: Self.evaluatedAtKey)
        }
        guard let milliseconds = try Self.number(evaluatedAt, operatorName: Self.evaluatedAtKey) else {
            throw RulesEngine.EvaluationError.typeMismatch(message: "'\(Self.evaluatedAtKey)' is null")
        }
        return milliseconds / 1_000
    }

    /// `nil` for null. Otherwise the backend's `float()` coercion: numbers,
    /// booleans as `0` / `1`, and numeric strings.
    static func number(_ value: RulesEngine.Value, operatorName: String) throws -> Double? {
        switch value {
        case .null, .undefined:
            return nil
        case .int(let number):
            return Double(number)
        case .float(let number):
            return number
        case .bool(let flag):
            return flag ? 1 : 0
        case .string(let text):
            if let number = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return number
            }
        case .array, .object:
            break
        }
        throw RulesEngine.EvaluationError.typeMismatch(
            message: "operator '\(operatorName)' expected a number, got \(value)"
        )
    }

    static func secondsPerUnit(_ unit: RulesEngine.Value, operatorName: String) throws -> Double {
        guard case .string(let name) = unit, let seconds = Self.secondsByUnit[name] else {
            throw RulesEngine.EvaluationError.typeMismatch(
                message: "operator '\(operatorName)' expected a unit in "
                    + "\(Self.secondsByUnit.keys.sorted()), got \(unit)"
            )
        }
        return seconds
    }
}

private extension RulesEngine.Value {

    var isNullish: Bool {
        switch self {
        case .null, .undefined: return true
        default: return false
        }
    }
}
