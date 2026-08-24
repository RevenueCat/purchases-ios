//
//  RulesEngineEvaluate.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// Applies a JSON Logic transformation predicate to a variable scope.
    ///
    /// The predicate is evaluated against `variables` and must produce an
    /// object, which becomes the new scope.
    ///
    /// - Parameters:
    ///   - predicate: The transformation predicate as a JSON string.
    ///   - variables: The raw variable scope.
    /// - Returns: `.success` with the transformed scope, or `.failure` carrying
    ///   an `EvaluationError` when parsing or evaluation fails, or when the
    ///   predicate evaluates to anything other than an object.
    static func transform(
        predicate: String,
        variables: [String: Value]
    ) -> Result<[String: Value], EvaluationError> {
        evaluated(predicate: predicate, variables: variables).flatMap { result in
            guard case .object(let transformed) = result else {
                return .failure(.typeMismatch(
                    message: "transformation predicate expected to produce an object, got \(result)"
                ))
            }
            return .success(transformed)
        }
    }

    /// Evaluates a JSON Logic predicate against a native variable scope.
    ///
    /// - Parameters:
    ///   - predicate: The evaluation predicate as a JSON string.
    ///   - variables: The variable scope.
    /// - Returns: `.success(true)` when the predicate evaluates to a truthy
    ///   value, `.success(false)` otherwise, or `.failure` carrying
    ///   an `EvaluationError` when parsing or evaluation fails.
    static func evaluate(
        predicate: String,
        variables: [String: Value]
    ) -> Result<Bool, EvaluationError> {
        evaluated(predicate: predicate, variables: variables).map(\.isTruthy)
    }

    /// Parses `predicate` and evaluates it against `variables`, mapping any
    /// thrown error into a `.failure`.
    private static func evaluated(
        predicate: String,
        variables: [String: Value]
    ) -> Result<Value, EvaluationError> {
        do {
            let predicateValue = try Value.fromJSONString(predicate)
            return .success(try Evaluator.evaluate(predicate: predicateValue, variables: variables))
        } catch let error as EvaluationError {
            return .failure(error)
        } catch {
            return .failure(.unknown(message: error.localizedDescription))
        }
    }
}
