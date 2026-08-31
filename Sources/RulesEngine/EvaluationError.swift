//
//  EvaluationError.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// Errors surfaced by the rules engine.
    enum EvaluationError: Error, Equatable, Sendable {

        /// The predicate JSON could not be parsed.
        case parse(message: String)

        /// The predicate reads a variable that the evaluation scope does not
        /// provide, and the rule supplies no default for it. Carries the
        /// dot-path that failed to resolve.
        ///
        /// This is a deliberate divergence from `json-logic-js`, which resolves
        /// an absent variable to `null`. That `null` then coerces to `0` in a
        /// numeric comparison and `""` in a string one, so a rule can answer
        /// `true` for a reason that has nothing to do with the user — a missing
        /// `now` turns `{">": [expires, now]}` into `expires > 0`, which is true
        /// for every subscription that ever existed. An absent variable means
        /// "unknown", and unknown is not the same answer as "no", so the engine
        /// refuses to guess and hands the decision to the caller.
        ///
        /// A rule that genuinely tolerates absence says so explicitly with the
        /// spec's own escape hatch, `{"var": ["path", default]}`, which never
        /// raises this error.
        case unresolvedVariable(path: String)

        /// An operator was given arguments of the wrong shape (e.g. wrong arity)
        /// or types that cannot be reconciled.
        case typeMismatch(message: String)

        /// The predicate references a JSON Logic operator the engine does not
        /// implement. Carries the operator name.
        case unsupportedOperator(name: String)

        /// An unexpected error that is not one of the structured cases above.
        case unknown(message: String)
    }
}

extension RulesEngine.EvaluationError: CustomStringConvertible {

    /// A human-readable description of the error.
    var description: String {
        switch self {
        case .parse(let message):
            return "failed to parse predicate JSON: \(message)"
        case .unresolvedVariable(let path):
            return "unresolved variable: \(path)"
        case .typeMismatch(let message):
            return "type mismatch: \(message)"
        case .unsupportedOperator(let name):
            return "unsupported operator: \(name)"
        case .unknown(let message):
            return "unknown error: \(message)"
        }
    }
}
