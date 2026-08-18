//
//  LengthOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `rc.length` — element count for arrays, UTF-16 code-unit count for
    /// strings (JS `String.length` parity).
    enum LengthOperator {

        /// `{"rc.length": value}` — returns a numeric length suitable for
        /// arithmetic and comparisons.
        ///
        /// - **String**: length in **UTF-16 code units**, not Swift grapheme
        ///   clusters — matches JS `String.length` and the same choice in
        ///   `AccessorOperators.opMissingSome` (`string.utf16.count`).
        /// - **Array**: element count (`.count`).
        /// - **Anything else**: throws `EvaluationError.typeMismatch`.
        ///
        /// Non-string/non-array inputs throw rather than defaulting to `0`.
        /// A silent zero would make `{"==": [{"rc.length": {"var": "missing"}},
        /// 0]}` quietly true when a key is absent — the failure mode these
        /// operators exist to eliminate. This differs from `rc.entries`, which
        /// returns `[]` leniently because its result feeds iteration operators
        /// that must keep composing; length feeds arithmetic, where a wrong
        /// number is indistinguishable from a right one.
        ///
        /// Uses `Operators.firstArgEvaluated` spread semantics; extra arguments
        /// are silently ignored. Literal array operands must be wrapped
        /// (e.g. `{"rc.length": [[1, 2, 3]]}`), not passed as a multi-element
        /// arg list.
        static func opLength(args: Value, vars: Scope) throws -> Value {
            let input = try Operators.firstArgEvaluated(args, vars: vars)

            switch input {
            case .string(let string):
                return .int(Int64(string.utf16.count))

            case .array(let items):
                return .int(Int64(items.count))

            default:
                throw EvaluationError.typeMismatch(
                    message: "operator 'rc.length' expected string or array, got \(input)"
                )
            }
        }
    }
}
