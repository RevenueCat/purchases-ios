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
        /// The separator is matched over UTF-16 code units — see
        /// `splitByCodeUnits`.
        ///
        /// Both operands must be strings and the separator must be non-empty,
        /// otherwise `EvaluationError.typeMismatch`. An empty separator would
        /// mean "split into characters", which the engine deliberately does not
        /// offer; arity is exact for the same reason as `rc.semverCompare`.
        static func opSplit(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Operators.evalArgs(args, vars: vars)

            try Operators.checkArity(evaluated.count, allowed: [2], operatorName: "rc.split")

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

            return .array(Self.splitByCodeUnits(input, separator: separator).map(Value.string))
        }

        /// Split on every non-overlapping occurrence of `separator`, scanning
        /// UTF-16 code units left to right, like JS `String.prototype.split`
        /// and Kotlin `String.split`.
        ///
        /// `components(separatedBy:)` instead matches by canonical
        /// equivalence, so a precomposed `é` (U+00E9) separator finds the
        /// decomposed spelling `e` (U+0065) plus a combining acute accent
        /// (U+0301) in the input, where the other two engines find nothing.
        ///
        /// A Swift `String` cannot hold an unpaired surrogate, so a match can
        /// never land inside a surrogate pair and no field is ever cut in half.
        private static func splitByCodeUnits(_ input: String, separator: String) -> [String] {
            let units = Array(input.utf16)
            let separatorUnits = Array(separator.utf16)
            var fields: [String] = []
            var fieldStart = 0
            var index = 0

            while index + separatorUnits.count <= units.count {
                guard units[index..<(index + separatorUnits.count)].elementsEqual(separatorUnits) else {
                    index += 1
                    continue
                }
                fields.append(String(decoding: units[fieldStart..<index], as: UTF16.self))
                index += separatorUnits.count
                fieldStart = index
            }

            fields.append(String(decoding: units[fieldStart...], as: UTF16.self))
            return fields
        }
    }
}
