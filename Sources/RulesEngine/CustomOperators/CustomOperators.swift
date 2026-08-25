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

        // A flat switch is the point of a dispatcher; it grows one case per
        // operator, as `Operators.dispatch` does.
        // swiftlint:disable:next cyclomatic_complexity
        static func dispatch(
            op operatorName: String,
            args: Value,
            vars: Scope
        ) throws -> Value {
            switch operatorName {
            case "rc.entries":
                return try EntriesOperators.opEntries(args: args, vars: vars)
            case "rc.fromEntries":
                return try EntriesOperators.opFromEntries(args: args, vars: vars)

            case "rc.length":
                return try LengthOperator.opLength(args: args, vars: vars)

            case "rc.let":
                return try LetOperator.opLet(args: args, vars: vars)

            case "rc.lower":
                return try CaseOperators.opLower(args: args, vars: vars)
            case "rc.upper":
                return try CaseOperators.opUpper(args: args, vars: vars)

            case "rc.rootVar":
                return try RootVarOperator.opRootVar(args: args, vars: vars)

            case "rc.semverCompare":
                return try SemverOperator.opSemverCompare(args: args, vars: vars)

            case "rc.slice":
                return try SliceOperator.opSlice(args: args, vars: vars)

            case "rc.sortBy":
                return try SortByOperator.opSortBy(args: args, vars: vars)

            case "rc.split":
                return try SplitOperator.opSplit(args: args, vars: vars)

            default:
                throw EvaluationError.unsupportedOperator(name: operatorName)
            }
        }
    }
}
