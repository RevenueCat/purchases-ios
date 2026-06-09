//
//  RulesEngineEvaluate.swift
//
//  Created by Antonio Pallares.
//

import Foundation

public extension RulesEngine {

    /// Evaluates a JSON Logic predicate against a native variable scope.
    ///
    /// - Parameters:
    ///   - predicate: The rule predicate as a JSON string, extracted from the
    ///     SDK artifact.
    ///   - variables: The resolved variable scope, built natively by the SDK.
    /// - Returns: `.success(true)` when the predicate evaluates to a truthy
    ///   value, `.success(false)` otherwise, or `.failure` carrying a
    ///   structured `RuleError` when parsing or evaluation fails.
    static func evaluate(
        predicate: String,
        variables: [String: Value]
    ) -> Result<Bool, RuleError> {
        do {
            let predicateValue = try Value.fromJSONString(predicate)
            let result = try Evaluator.evaluate(predicate: predicateValue, variables: variables)
            return .success(result)
        } catch let error as RuleError {
            return .failure(error)
        } catch {
            return .failure(.parse(message: error.localizedDescription))
        }
    }
}
