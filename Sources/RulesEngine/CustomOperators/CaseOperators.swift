//
//  CaseOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `rc.lower` and `rc.upper` — locale-independent case conversion for
    /// case-insensitive rule matching.
    enum CaseOperators {

        /// `{"rc.lower": value}` — lowercases a string argument.
        ///
        /// Uses Swift's parameterless `String.lowercased()`, which applies
        /// Unicode default case mapping and is **locale-independent**. Do not
        /// use `Locale`-taking overloads: locale-sensitive conversion would make
        /// the same rule match on one device (e.g. Turkish *I* → dotless *ı*)
        /// and fail on another. Matches JS `toLowerCase()`, not
        /// `toLocaleLowerCase()`.
        ///
        /// Follows `Operators.firstArgEvaluated` spread semantics; extra
        /// arguments are silently ignored.
        static func opLower(args: Value, vars: Scope) throws -> Value {
            let string = try stringArgument(args, vars: vars, operatorName: "rc.lower")
            return .string(string.lowercased())
        }

        /// `{"rc.upper": value}` — same string-only contract as `rc.lower`, then
        /// uppercases via locale-independent `String.uppercased()`.
        static func opUpper(args: Value, vars: Scope) throws -> Value {
            let string = try stringArgument(args, vars: vars, operatorName: "rc.upper")
            return .string(string.uppercased())
        }

        /// Requires a string operand, throwing `EvaluationError.typeMismatch`
        /// for anything else.
        ///
        /// Non-strings are **not** coerced through `jsString`, even though JS
        /// `String(x).toLowerCase()` would accept them. Coercion makes data of
        /// the wrong shape look like real data: an explicit `null` would lower
        /// to `"null"` and compare equal to that string. Same reasoning as
        /// `rc.length` and `rc.entries`.
        private static func stringArgument(
            _ args: Value,
            vars: Scope,
            operatorName: String
        ) throws -> String {
            let input = try Operators.firstArgEvaluated(args, vars: vars)

            guard case .string(let string) = input else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected string, got \(input)"
                )
            }

            return string
        }
    }
}
