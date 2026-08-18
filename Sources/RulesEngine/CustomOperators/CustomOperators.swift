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
    /// future standard JSON Logic operator. Any engine evaluating these rules —
    /// including the `json-logic-js`-based web implementation — must register
    /// equivalents.
    enum CustomOperators {

        static func dispatch(
            op operatorName: String,
            args: Value,
            vars: Scope
        ) throws -> Value {
            switch operatorName {
            default:
                throw EvaluationError.unsupportedOperator(name: operatorName)
            }
        }
    }
}
