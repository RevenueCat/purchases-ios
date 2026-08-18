//
//  CustomOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// RevenueCat-specific JSON Logic operators.
    ///
    /// Operators here are namespaced under `rc.` so they cannot collide with a
    /// future standard JSON Logic operator.
    enum CustomOperators {

        static func dispatch(
            op operatorName: String,
            args: Value,
            vars: Scope
        ) throws -> Value {
            switch operatorName {
            case "rc.lower":
                return try CaseOperators.opLower(args: args, vars: vars)
            case "rc.upper":
                return try CaseOperators.opUpper(args: args, vars: vars)
            default:
                throw EvaluationError.unsupportedOperator(name: operatorName)
            }
        }
    }
}
