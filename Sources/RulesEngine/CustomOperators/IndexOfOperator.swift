//
//  IndexOfOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Name used in this operator's error messages.
private let operatorName = "rc.indexOf"

extension RulesEngine {

    /// `rc.indexOf` — where a value sits in an array, or a substring in a string.
    enum IndexOfOperator {

        /// `{"rc.indexOf": [haystack, needle]}` — the position of the first
        /// occurrence, or `-1` when there is none. The haystack comes first,
        /// like every other `rc.` operator, even though `in` takes the needle
        /// first.
        ///
        /// - **Array**: strict equality against each element, the same test
        ///   `in` uses, so an array or object needle never matches.
        /// - **String**: substring search. An empty needle sits at `0`, as in
        ///   JS.
        ///
        /// Absence returns `-1` rather than throwing: a value that is not
        /// there is an ordinary answer, not a lowering bug, and `-1` keeps the
        /// result usable in arithmetic. A haystack that is neither array nor
        /// string, or a non-string needle against a string haystack, is a
        /// lowering bug and throws `EvaluationError.typeMismatch`.
        static func opIndexOf(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Operators.evalArgs(args, vars: vars)

            guard evaluated.count == 2 else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expects 2 arguments, "
                        + "got \(evaluated.count)"
                )
            }

            let needle = evaluated[1]

            switch evaluated[0] {
            case .array(let items):
                let position = items.firstIndex { RulesEngine.strictEq($0, needle) }
                return .int(Int64(position ?? -1))

            case .string(let haystack):
                guard case .string(let needle) = needle else {
                    throw EvaluationError.typeMismatch(
                        message: "operator '\(operatorName)' expected a string to search for "
                            + "in a string, got \(needle)"
                    )
                }
                return .int(Int64(Self.position(of: needle, in: haystack)))

            default:
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected an array or string to search, "
                        + "got \(evaluated[0])"
                )
            }
        }

        /// Position of the first `needle` in `haystack`, or `-1`.
        ///
        /// Two separate questions, deliberately answered by different units.
        /// *Where* the needle occurs is a match, so it is searched over UTF-16
        /// code units like `in` and `rc.split`. *How far in* that is, is a
        /// count, so the text before the match is measured with
        /// `LengthOperator.stringLength` — the same function behind
        /// `rc.length`. The two operators therefore always report positions in
        /// the same unit, including if that unit ever changes.
        ///
        /// Neither operand can hold an unpaired surrogate, so a match never
        /// starts inside a surrogate pair and the prefix is always whole text.
        private static func position(of needle: String, in haystack: String) -> Int {
            let units = Array(haystack.utf16)
            let needleUnits = Array(needle.utf16)

            guard !needleUnits.isEmpty else { return 0 }
            guard needleUnits.count <= units.count else { return -1 }

            for start in 0...(units.count - needleUnits.count)
            where units[start..<(start + needleUnits.count)].elementsEqual(needleUnits) {
                return LengthOperator.stringLength(String(decoding: units[..<start], as: UTF16.self))
            }

            return -1
        }
    }
}
