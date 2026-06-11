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
    ///   - predicate: The rule predicate as a JSON string.
    ///   - variables: The resolved variable scope.
    /// - Returns: `.success(true)` when the predicate evaluates to a truthy
    ///   value, `.success(false)` otherwise, or `.failure` carrying
    ///   an `EvaluationError` when parsing or evaluation fails.
    static func evaluate(
        predicate: String,
        variables: [String: Value]
    ) -> Result<Bool, EvaluationError> {
        do {
            let predicateValue = try Value.fromJSONString(predicate)
            let result = try Evaluator.evaluate(predicate: predicateValue, variables: variables)
            return .success(result)
        } catch let error as EvaluationError {
            return .failure(error)
        } catch {
            return .failure(.unknown(message: error.localizedDescription))
        }
    }
}
