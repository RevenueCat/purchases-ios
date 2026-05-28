//
//  RuleError.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Errors surfaced by the rules engine.
///
/// Note on missing variables: the v1 evaluator does **not** raise an error
/// for them — per the JSON Logic spec, they resolve to `null` and a warning
/// is logged instead. If a strict mode is ever needed, we'd add a
/// `missingVariable` case.
enum RuleError: Error, Equatable {

    /// The predicate JSON could not be parsed.
    case parse(message: String)

    /// The predicate references a JSON Logic operator the engine does not
    /// implement. Carries the operator name so callers can decide policy
    /// (default-deny, log, etc.).
    case unsupportedOperator(name: String)
}

extension RuleError: CustomStringConvertible {

    var description: String {
        switch self {
        case .parse(let message):
            return "failed to parse predicate JSON: \(message)"
        case .unsupportedOperator(let name):
            return "unsupported operator: \(name)"
        }
    }
}
