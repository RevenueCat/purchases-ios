//
//  RegexOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// Regular expression operators.
    ///
    /// The pattern is handed to the platform engine. This one and Android's
    /// are both ICU — `java.util.regex` has wrapped ICU4C since Android 2.3 —
    /// so the two devices agree, and `RegExp` in Funnels is the one that
    /// differs. Patterns are authored by the backend, which is expected to
    /// stay inside the subset all three read the same way:
    ///
    /// - `\d`, `\w`, `\s` and `\b` cover Unicode in ICU and only ASCII in JS,
    ///   so `\d` matches an Arabic-Indic digit on a device and not in
    ///   Funnels. Write `[0-9]` for the ASCII meaning.
    /// - `&&` inside a character class is set intersection in ICU and two
    ///   literal ampersands in JS.
    /// - A literal `}` needs escaping as `\}` for ICU, which reads a bare one
    ///   as a malformed quantifier. JS accepts either, so an unescaped brace
    ///   compiles in Funnels and throws on both devices.
    /// - `$` matches before a trailing newline in ICU but not in JS.
    /// - An empty pattern does not compile in ICU at all, where JS reads it
    ///   as a match at every position.
    ///
    /// The one place the devices part company is an unknown escape such as
    /// `\q`: Android rejects the pattern, this engine reads it as a literal
    /// `q`. Escape only what needs escaping.
    ///
    /// No operator takes flags, since JS has no inline `(?i)`. Write `[aA]`
    /// for a case-insensitive letter.
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

            let regex: NSRegularExpression
            do {
                regex = try NSRegularExpression(pattern: pattern)
            } catch {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' could not compile pattern "
                        + "'\(pattern)': \(error.localizedDescription)"
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
