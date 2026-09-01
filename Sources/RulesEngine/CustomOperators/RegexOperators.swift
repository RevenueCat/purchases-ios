//
//  RegexOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// Regular expression operators.
    ///
    /// Patterns are compiled by `NSRegularExpression`, whose syntax is
    /// documented at
    /// https://developer.apple.com/documentation/foundation/nsregularexpression
    ///
    /// No operator takes flags. Write `[aA]` for a case-insensitive letter.
    enum RegexOperators {

        /// `{"rc.regexMatch": [input, pattern]}` — whether the pattern occurs
        /// anywhere in the input. Anchor with `^` and `$` for a whole-string
        /// test.
        ///
        /// Both operands must be strings and the pattern must compile,
        /// otherwise `EvaluationError.typeMismatch`.
        static func opRegexMatch(args: Value, vars: Scope) throws -> Value {
            let operands = try Self.operands(
                args,
                vars: vars,
                operatorName: "rc.regexMatch",
                argumentCount: 2
            )
            return .bool(Self.firstMatch(of: operands.regex, in: operands.input) != nil)
        }

        /// Evaluates and type-checks the `[input, pattern]` pair every regex
        /// operator starts with, returning any arguments beyond it.
        static func operands(
            _ args: Value,
            vars: Scope,
            operatorName: String,
            argumentCount: Int
        ) throws -> (input: String, regex: NSRegularExpression, rest: [Value]) {
            let evaluated = try Operators.evalArgs(args, vars: vars)

            guard evaluated.count == argumentCount else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expects \(argumentCount) arguments, "
                        + "got \(evaluated.count)"
                )
            }

            guard case .string(let input) = evaluated[0] else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected a string to match against, "
                        + "got \(evaluated[0])"
                )
            }

            guard case .string(let pattern) = evaluated[1] else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected a string pattern, "
                        + "got \(evaluated[1])"
                )
            }

            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' could not compile pattern '\(pattern)'"
                )
            }

            return (input, regex, Array(evaluated.dropFirst(2)))
        }

        static func firstMatch(
            of regex: NSRegularExpression,
            in input: String
        ) -> NSTextCheckingResult? {
            regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input))
        }
    }
}
