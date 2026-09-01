//
//  SliceOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Name used in this operator's error messages.
private let operatorName = "rc.slice"

extension RulesEngine {

    /// `rc.slice` — takes a run of elements out of an array.
    enum SliceOperator {

        /// `{"rc.slice": [array, start]}` or
        /// `{"rc.slice": [array, start, length]}`.
        ///
        /// Start and length mean what they mean in `substr`, the string operator
        /// already in the engine: a negative `start` counts from the end, a
        /// negative `length` drops that many elements from the right, and both
        /// clamp to the array instead of failing. Strings keep using `substr`.
        ///
        /// Indices must be whole numbers — `.float` is accepted because all
        /// arithmetic returns it, so `length - 1` is an ordinary way to reach the
        /// last element. A fractional or non-numeric index throws
        /// `EvaluationError.typeMismatch`, as does a non-array operand.
        static func opSlice(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Operators.evalArgs(args, vars: vars)

            try Operators.checkArity(evaluated.count, allowed: [2, 3], operatorName: operatorName)

            guard case .array(let items) = evaluated[0] else {
                var hint = ""
                if case .string = evaluated[0] {
                    hint = "; strings use 'substr'"
                }
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected an array to slice, "
                        + "got \(evaluated[0])\(hint)"
                )
            }

            let start = try Self.index(evaluated[1], argument: "start")
            let begin = start < 0 ? max(items.count + start, 0) : min(start, items.count)
            let remaining = Array(items[begin...])

            guard evaluated.count == 3 else { return .array(remaining) }

            let length = try Self.index(evaluated[2], argument: "length")
            let count = length < 0
                ? max(remaining.count + length, 0)
                : min(length, remaining.count)
            return .array(Array(remaining[..<count]))
        }

        /// Reads a whole-number index, rejecting anything that is not one.
        private static func index(_ value: Value, argument: String) throws -> Int {
            switch value {
            case .int(let number):
                return Int(clamping: number)
            case .float(let number) where number.truncatingRemainder(dividingBy: 1) == 0:
                return Operators.clampedInt(number)
            default:
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected a whole number "
                        + "\(argument), got \(value)"
                )
            }
        }
    }
}
