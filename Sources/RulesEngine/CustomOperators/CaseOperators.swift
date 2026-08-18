//
//  CaseOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `rc.lower` and `rc.upper` — locale-independent case conversion for
    /// case-insensitive rule matching.
    ///
    /// Cross-engine contract: equivalent to `(x) => String(x).toLowerCase()` /
    /// `.toUpperCase()` polyfills — **not** `toLocaleLowerCase()`.
    enum CaseOperators {

        /// `{"rc.lower": value}` — stringifies the first argument via `jsString`
        /// (same coercion `var` path segments use), then lowercases it.
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
            let input = try Operators.firstArgEvaluated(args, vars: vars)
            return .string(jsString(input).lowercased())
        }

        /// `{"rc.upper": value}` — same coercion as `rc.lower`, then uppercases
        /// via locale-independent `String.uppercased()` (Unicode default mapping).
        static func opUpper(args: Value, vars: Scope) throws -> Value {
            let input = try Operators.firstArgEvaluated(args, vars: vars)
            return .string(jsString(input).uppercased())
        }
    }
}
