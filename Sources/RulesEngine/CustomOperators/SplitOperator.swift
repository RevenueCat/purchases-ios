//
//  SplitOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `rc.split` — splits a string into an array of fields.
    enum SplitOperator {

        /// `{"rc.split": [input, separator]}` — every field, including empty
        /// ones, as strings. Numeric-looking fields are not coerced, so
        /// `"1,2"` splits into `["1", "2"]`.
        ///
        /// A `var` path cannot index the result of an expression, so a field is
        /// read by wrapping the array in a one-element list and letting an
        /// iteration operator rebind the scope to it:
        ///
        /// ```json
        /// {"some": [[{"rc.split": [{"var": "locale"}, "-"]}],
        ///           {"===": [{"var": "0"}, "es"]}]}
        /// ```
        ///
        /// The array is also usable directly by `in` and by the iteration
        /// operators, which is enough for most membership and any/all tests.
        ///
        /// Both operands must be strings and the separator must be non-empty,
        /// otherwise `EvaluationError.typeMismatch`. An empty separator would
        /// mean "split into characters", which the engine deliberately does not
        /// offer; arity is exact for the same reason as `rc.semverCompare`.
        static func opSplit(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Operators.evalArgs(args, vars: vars)

            guard evaluated.count == 2 else {
                throw EvaluationError.typeMismatch(
                    message: "operator 'rc.split' expects 2 arguments, got \(evaluated.count)"
                )
            }

            guard case .string(let input) = evaluated[0] else {
                throw EvaluationError.typeMismatch(
                    message: "operator 'rc.split' expected a string to split, got \(evaluated[0])"
                )
            }

            guard case .string(let separator) = evaluated[1], !separator.isEmpty else {
                throw EvaluationError.typeMismatch(
                    message: "operator 'rc.split' expected a non-empty string separator, "
                        + "got \(evaluated[1])"
                )
            }

            return .array(input.components(separatedBy: separator).map(Value.string))
        }
    }
}
