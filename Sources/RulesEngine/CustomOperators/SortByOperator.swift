//
//  SortByOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Name used in this operator's error messages.
private let operatorName = "rc.sortBy"

extension RulesEngine {

    /// `rc.sortBy` — orders an array in ascending order by a key computed per item.
    enum SortByOperator {

        /// `{"rc.sortBy": [array, keyExpression]}` — the original items in
        /// ascending key order, ties keeping their input order.
        ///
        /// `keyExpression` is evaluated once per item with the scope rebound to
        /// that item, the same way `map` evaluates its template.
        ///
        /// Keys must be all strings or all finite numbers; anything else,
        /// including a mix, throws `EvaluationError.typeMismatch`. Ordering
        /// values of different types would need a total order the rule author
        /// never asked for. There is no direction argument; a descending numeric
        /// sort negates the key.
        static func opSortBy(args: Value, vars: Scope) throws -> Value {
            let raw = Operators.argsAsList(args)

            guard raw.count == 2 else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expects 2 arguments, got \(raw.count)"
                )
            }

            let source = try Evaluator.evaluateValue(raw[0], vars: vars)
            guard case .array(let items) = source else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected an array to sort, got \(source)"
                )
            }

            let keys = try items.map { item in
                try Evaluator.evaluateValue(raw[1], vars: vars.scoped(to: item))
            }

            return .array(try Self.sorted(items, by: keys))
        }

        /// Sorts by `keys`, falling back to the input position so equal keys
        /// keep their order. Swift does not guarantee `sorted(by:)` is stable,
        /// and the two engines must agree on the output for every input.
        private static func sorted(_ items: [Value], by keys: [Value]) throws -> [Value] {
            let order = try Self.comparator(for: keys)

            return zip(keys.indices, zip(keys, items))
                .sorted { left, right in
                    let (leftIndex, (leftKey, _)) = left
                    let (rightIndex, (rightKey, _)) = right
                    if order(leftKey, rightKey) { return true }
                    if order(rightKey, leftKey) { return false }
                    return leftIndex < rightIndex
                }
                .map { _, pair in pair.1 }
        }

        /// Picks the ordering the whole key set supports, or throws.
        private static func comparator(for keys: [Value]) throws -> (Value, Value) -> Bool {
            var sawString = false
            var sawNumber = false

            for key in keys {
                switch key {
                case .string:
                    sawString = true
                case .int:
                    sawNumber = true
                case .float(let number):
                    // A NaN key compares false against everything, so every
                    // pair would tie and the input would come back unsorted.
                    guard number.isFinite else {
                        throw EvaluationError.typeMismatch(
                            message: "operator '\(operatorName)' expected a finite number key, "
                                + "got \(key)"
                        )
                    }
                    sawNumber = true
                default:
                    throw EvaluationError.typeMismatch(
                        message: "operator '\(operatorName)' expected string or number keys, got \(key)"
                    )
                }
            }

            guard !(sawString && sawNumber) else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected keys of a single type, "
                        + "got both strings and numbers"
                )
            }

            if sawString {
                return { left, right in
                    guard case .string(let left) = left, case .string(let right) = right else {
                        return false
                    }
                    return left < right
                }
            }
            return { left, right in (left.asNumber ?? 0) < (right.asNumber ?? 0) }
        }
    }
}
