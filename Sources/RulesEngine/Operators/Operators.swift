//
//  Operators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// JSON Logic operator dispatcher and shared helpers.
    ///
    /// Operators are responsible for evaluating their own arguments. Most use
    /// the `evalTwo` / `evalArgs` helpers which evaluate eagerly; short-circuit
    /// operators (`and`, `or`, `if`) iterate manually.
    enum Operators {

        /// Dispatch a JSON Logic operator. Throws `RulesEngine.EvaluationError.unsupportedOperator`
        /// when the operator name isn't implemented in this slice.
        // swiftlint:disable:next cyclomatic_complexity function_body_length
        static func dispatch(
            op operatorName: String,
            args: Value,
            vars: Scope
        ) throws -> Value {
            switch operatorName {
            // Accessors
            case "var":
                return try AccessorOperators.opVar(args: args, vars: vars)
            case "missing":
                return try AccessorOperators.opMissing(args: args, vars: vars)
            case "missing_some":
                return try AccessorOperators.opMissingSome(args: args, vars: vars)

            // Equality
            case "==":
                return try EqualityOperators.opLooseEq(args: args, vars: vars)
            case "!=":
                return try EqualityOperators.opLooseNe(args: args, vars: vars)
            case "===":
                return try EqualityOperators.opStrictEq(args: args, vars: vars)
            case "!==":
                return try EqualityOperators.opStrictNe(args: args, vars: vars)

            // Logic
            case "!":
                return try LogicOperators.opNot(args: args, vars: vars)
            case "!!":
                return try LogicOperators.opNotNot(args: args, vars: vars)
            case "and":
                return try LogicOperators.opAnd(args: args, vars: vars)
            case "or":
                return try LogicOperators.opOr(args: args, vars: vars)
            case "if":
                return try LogicOperators.opIf(args: args, vars: vars)

            // Arithmetic
            case "+":
                return try ArithmeticOperators.opAdd(args: args, vars: vars)
            case "-":
                return try ArithmeticOperators.opSub(args: args, vars: vars)
            case "*":
                return try ArithmeticOperators.opMul(args: args, vars: vars)
            case "/":
                return try ArithmeticOperators.opDiv(args: args, vars: vars)
            case "%":
                return try ArithmeticOperators.opMod(args: args, vars: vars)

            // Min and max
            case "min":
                return try MinMaxOperators.opMin(args: args, vars: vars)
            case "max":
                return try MinMaxOperators.opMax(args: args, vars: vars)

            // Comparison
            case "<":
                return try ComparisonOperators.opLt(args: args, vars: vars)
            case "<=":
                return try ComparisonOperators.opLe(args: args, vars: vars)
            case ">":
                return try ComparisonOperators.opGt(args: args, vars: vars)
            case ">=":
                return try ComparisonOperators.opGe(args: args, vars: vars)

            // String and array
            case "in":
                return try StringArrayOperators.opIn(args: args, vars: vars)
            case "cat":
                return try StringArrayOperators.opCat(args: args, vars: vars)
            case "substr":
                return try StringArrayOperators.opSubstr(args: args, vars: vars)
            case "merge":
                return try StringArrayOperators.opMerge(args: args, vars: vars)

            // Iteration
            case "some":
                return try IterationOperators.opSome(args: args, vars: vars)
            case "all":
                return try IterationOperators.opAll(args: args, vars: vars)
            case "none":
                return try IterationOperators.opNone(args: args, vars: vars)
            case "map":
                return try IterationOperators.opMap(args: args, vars: vars)
            case "filter":
                return try IterationOperators.opFilter(args: args, vars: vars)
            case "reduce":
                return try IterationOperators.opReduce(args: args, vars: vars)

            // Miscellaneous
            case "log":
                return try MiscOperators.opLog(args: args, vars: vars)

            default:
                return try CustomOperators.dispatch(op: operatorName, args: args, vars: vars)
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
        static func evalArgs(_ args: Value, vars: Scope) throws -> [Value] {
            try argsAsList(args).map { try Evaluator.evaluateValue($0, vars: vars) }
        }

        /// Rejects an argument count no overload of `operatorName` accepts.
        ///
        /// Only for operators that are strict about arity. Several others take
        /// a fixed number of arguments and silently ignore extras — `substr`,
        /// `<`, `reduce`, and anything reading through `firstArgEvaluated` —
        /// matching `json-logic-js`, where a spread call simply drops what the
        /// function does not declare. Whether an operator is strict is a
        /// decision each one makes; this only spells the refusal the same way
        /// every time.
        static func checkArity(_ count: Int, allowed: [Int], operatorName: String) throws {
            guard allowed.contains(count) else {
                let expected = allowed.map(String.init).joined(separator: " or ")
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expects \(expected) arguments, "
                        + "got \(count)"
                )
            }
        }

        /// Evaluate exactly two arguments. Used by binary operators (`==`,
        /// `!=`, `===`, `!==`).
        /// Evaluate args and return the first two operands. Missing
        /// operands default to `.undefined` (JS omitted-argument semantics:
        /// `function(a, b)` sees `undefined` for absent args, so e.g.
        /// `{"===": [{"and": []}]}` is `undefined === undefined`) and extras
        /// are silently discarded.
        static func evalTwo(
            _ args: Value,
            vars: Scope
        ) throws -> (Value, Value) {
            let evaluated = try evalArgs(args, vars: vars)
            let lhs = evaluated.first ?? .undefined
            let rhs = evaluated.indices.contains(1) ? evaluated[1] : .undefined
            return (lhs, rhs)
        }

        /// Evaluate the first argument of a unary operator. Uses `argsAsList`
        /// then takes index zero, matching `json-logic-js`'s
        /// `operations[op].apply(context, values)` spread semantics: a
        /// multi-element top-level array is a multi-argument call, not a
        /// single array operand. An empty arg list yields `.null`.
        static func firstArgEvaluated(_ args: Value, vars: Scope) throws -> Value {
            let items = argsAsList(args)
            let first = items.first ?? .null
            return try Evaluator.evaluateValue(first, vars: vars)
        }

        /// Safely truncate a `Double` to `Int` for index / count math.
        /// `NaN` → `0` (matches JS `ToInteger`); `±Infinity` and
        /// out-of-range finite values clamp to `Int.max` / `Int.min`.
        static func clampedInt(_ value: Double) -> Int {
            if value.isNaN { return 0 }
            if value >= Double(Int.max) { return .max }
            if value <= Double(Int.min) { return .min }
            return Int(value)
        }
    }
}
