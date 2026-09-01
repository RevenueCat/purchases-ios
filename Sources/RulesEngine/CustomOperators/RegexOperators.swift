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
            let operatorName = "rc.regexMatch"
            let evaluated = try Operators.evalArgs(args, vars: vars)
            try Self.checkArity(evaluated.count, allowed: [2], operatorName: operatorName)

            let operands = try Self.operands(evaluated, operatorName: operatorName)
            return .bool(Self.firstMatch(of: operands.regex, in: operands.input) != nil)
        }

        /// `{"rc.regexExtract": [input, pattern]}` or
        /// `{"rc.regexExtract": [input, pattern, group]}` — the text of the
        /// first match, or of one of its capture groups. Group `0`, the
        /// default, is the whole match.
        ///
        /// Returns `null` when the pattern does not match, and when the group
        /// exists but took no part in the match, as group 1 of `(a)|(b)` does
        /// against `"b"`.
        ///
        /// A group number the pattern does not have is a lowering bug and
        /// throws `EvaluationError.typeMismatch`, as do non-string operands, a
        /// pattern that does not compile, and a fractional group.
        static func opRegexExtract(args: Value, vars: Scope) throws -> Value {
            let operatorName = "rc.regexExtract"
            let evaluated = try Operators.evalArgs(args, vars: vars)
            try Self.checkArity(evaluated.count, allowed: [2, 3], operatorName: operatorName)

            let operands = try Self.operands(evaluated, operatorName: operatorName)
            let group = try Self.group(evaluated.count == 3 ? evaluated[2] : nil,
                                       operatorName: operatorName)

            guard group <= operands.regex.numberOfCaptureGroups else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' asked for group \(group) of a pattern "
                        + "with \(operands.regex.numberOfCaptureGroups) capture group(s)"
                )
            }

            guard let match = Self.firstMatch(of: operands.regex, in: operands.input),
                  let range = Range(match.range(at: group), in: operands.input) else {
                return .null
            }

            return .string(String(operands.input[range]))
        }

        /// `{"rc.regexReplace": [input, pattern, replacement]}` — every match
        /// replaced, left to right.
        ///
        /// The replacement is literal text. `$1` is not a backreference: the
        /// template is read by each platform's own API rather than by ICU, so
        /// this is the one part of the feature where the two devices differ.
        /// `$&` substitutes the match in JS, throws on Android, and stays
        /// literal here; `$1` against a pattern with no groups throws on
        /// Android and yields the empty string here. None of it is exposed.
        /// Build a replacement out of captures with `rc.regexExtract` and
        /// `cat` instead.
        ///
        /// All operands must be strings and the pattern must compile,
        /// otherwise `EvaluationError.typeMismatch`.
        static func opRegexReplace(args: Value, vars: Scope) throws -> Value {
            let operatorName = "rc.regexReplace"
            let evaluated = try Operators.evalArgs(args, vars: vars)
            try Self.checkArity(evaluated.count, allowed: [3], operatorName: operatorName)

            let operands = try Self.operands(evaluated, operatorName: operatorName)

            guard case .string(let replacement) = evaluated[2] else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected a string replacement, "
                        + "got \(evaluated[2])"
                )
            }

            let input = operands.input
            return .string(
                operands.regex.stringByReplacingMatches(
                    in: input,
                    range: NSRange(input.startIndex..., in: input),
                    withTemplate: NSRegularExpression.escapedTemplate(for: replacement)
                )
            )
        }

        /// Rejects an argument count no overload accepts.
        static func checkArity(_ count: Int, allowed: [Int], operatorName: String) throws {
            guard allowed.contains(count) else {
                let expected = allowed.map(String.init).joined(separator: " or ")
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expects \(expected) arguments, "
                        + "got \(count)"
                )
            }
        }

        /// Type-checks the `[input, pattern]` pair every regex operator starts
        /// with, and compiles the pattern.
        static func operands(
            _ evaluated: [Value],
            operatorName: String
        ) throws -> (input: String, regex: NSRegularExpression) {
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

            let regex: NSRegularExpression
            do {
                regex = try NSRegularExpression(pattern: pattern)
            } catch {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' could not compile pattern "
                        + "'\(pattern)': \(error.localizedDescription)"
                )
            }

            return (input, regex)
        }

        static func firstMatch(
            of regex: NSRegularExpression,
            in input: String
        ) -> NSTextCheckingResult? {
            regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input))
        }

        /// Reads the optional group argument, defaulting to the whole match.
        private static func group(_ value: Value?, operatorName: String) throws -> Int {
            switch value {
            case .none:
                return 0
            case .int(let number) where number >= 0:
                return Int(clamping: number)
            case .float(let number)
                where number >= 0 && number.truncatingRemainder(dividingBy: 1) == 0:
                return Operators.clampedInt(number)
            case .some(let other):
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected a whole, non-negative group "
                        + "number, got \(other)"
                )
            }
        }
    }
}
