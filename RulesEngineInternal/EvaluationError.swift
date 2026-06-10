//
//  EvaluationError.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// Errors surfaced by the rules engine.
    ///
    /// Note on missing variables: the evaluator does **not** raise an error
    /// for them — per the JSON Logic spec, they resolve to `null` and a warning
    /// is logged instead.
    public enum EvaluationError: Error, Equatable {

        /// The predicate JSON could not be parsed.
        case parse(message: String)

        /// An operator was given arguments of the wrong shape (e.g. wrong arity)
        /// or types that cannot be reconciled.
        case typeMismatch(message: String)

        /// The predicate references a JSON Logic operator the engine does not
        /// implement. Carries the operator name so callers can decide policy
        /// (default-deny, log, etc.).
        case unsupportedOperator(name: String)

        /// An unexpected error that is not one of the structured cases above.
        case unknown(message: String)
    }
}

extension RulesEngine.EvaluationError: CustomStringConvertible {

    /// A human-readable description of the error.
    public var description: String {
        switch self {
        case .parse(let message):
            return "failed to parse predicate JSON: \(message)"
        case .typeMismatch(let message):
            return "type mismatch: \(message)"
        case .unsupportedOperator(let name):
            return "unsupported operator: \(name)"
        case .unknown(let message):
            return "unknown error: \(message)"
        }
    }
}
