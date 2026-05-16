//
//  Evaluator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Top-level evaluator for JSON Logic predicates.
///
/// The evaluator is intentionally simple: literals evaluate to themselves,
/// arrays evaluate element-wise, single-key objects dispatch to an operator,
/// multi-key objects are treated as literal data. Operators handle their
/// own short-circuit / arity logic.
///
/// Diagnostic warnings (missing variables, malformed args, ignored extras)
/// are routed through `Rules.logger`. Tests can swap that logger via
/// `Rules.withLogger { ... }` to capture or silence output.
enum Evaluator {

    /// Module-internal entry point. A future iteration will surface this via
    /// the SDK-facing API.
    ///
    /// - Parameters:
    ///   - predicate: The inner `predicate` field of a rule artifact, already
    ///     parsed into a typed `Value` tree by the caller (the engine never
    ///     sees the JSON wire format — see module-level docs in `Value.swift`
    ///     for why).
    ///   - variables: The resolved variable map — typically a nested object
    ///     mirroring the namespace hierarchy (`subscriber.*`, `session.*`,
    ///     etc.).
    /// - Returns: `true` when the predicate evaluates to a truthy value per
    ///   JSON Logic rules.
    static func evaluate(predicate: Value, variables: [String: Value]) throws -> Bool {
        let scope = Value.object(variables)
        let result = try evaluateValue(predicate, vars: scope)
        return result.isTruthy
    }

    /// Recursive evaluator. Module-internal so operator implementations can
    /// call it for short-circuit / nested evaluation.
    static func evaluateValue(_ predicate: Value, vars: Value) throws -> Value {
        switch predicate {
        case .null, .bool, .int, .float, .string:
            return predicate

        case .array(let items):
            var evaluated: [Value] = []
            evaluated.reserveCapacity(items.count)
            for item in items {
                evaluated.append(try evaluateValue(item, vars: vars))
            }
            return .array(evaluated)

        case .object(let map):
            if map.count == 1, let (operatorName, args) = map.first {
                return try Operators.dispatch(op: operatorName, args: args, vars: vars)
            }
            return predicate
        }
    }
}
