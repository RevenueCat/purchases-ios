//
//  EqualityOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Equality operators: `==`, `!=`, `===`, `!==`.
enum EqualityOperators {

    /// `{"==": [a, b]}` — JSON Logic loose equality. Coerces across primitive
    /// types (e.g. `1 == "1"` is true). Full coercion table in `looseEq`.
    static func opLooseEq(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "==")
        return .bool(looseEq(lhs, rhs))
    }

    /// `{"!=": [a, b]}` — JSON Logic loose inequality. Negation of `==`.
    static func opLooseNe(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "!=")
        return .bool(!looseEq(lhs, rhs))
    }

    /// `{"===": [a, b]}` — JSON Logic strict equality. Same type, same value
    /// (`1 === "1"` is false). See `strictEq` for the numeric subtlety
    /// around `int` vs `float`.
    static func opStrictEq(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "===")
        return .bool(strictEq(lhs, rhs))
    }

    /// `{"!==": [a, b]}` — JSON Logic strict inequality. Negation of `===`.
    static func opStrictNe(args: Value, vars: Value) throws -> Value {
        let (lhs, rhs) = try Operators.evalTwo(args, vars: vars, opName: "!==")
        return .bool(!strictEq(lhs, rhs))
    }
}
