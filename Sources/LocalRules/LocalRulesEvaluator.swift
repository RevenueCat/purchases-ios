//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalRulesEvaluator.swift
//
//  Created by Rick van der Linden on 7/28/26.
//

import Foundation

/// A rule that can be evaluated against locally collected dimensions.
protocol LocalRule: Sendable {

    var predicate: String { get }
}

/// A predicate failure that prevented local rules from producing a definitive non-match.
enum LocalRulesEvaluationError: Error, Equatable, Sendable {

    case predicateEvaluation(ruleIndex: Int, error: RulesEngine.EvaluationError)
}

/// Evaluates rules against fresh, locally collected dimensions.
final class LocalRulesEvaluator: Sendable {

    private let dimensionResolver: DimensionResolver

    init(
        dimensionProviders: [any DimensionProvider],
        dateProvider: DateProvider = DateProvider()
    ) {
        self.dimensionResolver = DimensionResolver(
            dimensionProviders: dimensionProviders,
            dateProvider: dateProvider
        )
    }

    /// Returns the first matching rule, using one snapshot for the full call.
    ///
    /// For example, rules `[("a", false), ("b", true)]` return the second rule.
    /// Developer-supplied values are available to predicates under `custom.*`.
    func match<Rule: LocalRule>(
        in rules: [Rule],
        customVariables: [String: DimensionValue] = [:]
    ) async throws -> Rule? {
        guard !rules.isEmpty else {
            return nil
        }

        let snapshot = try await self.dimensionResolver.snapshot(customVariables: customVariables)

        var firstEvaluationError: LocalRulesEvaluationError?

        for (index, rule) in rules.enumerated() {
            switch RulesEngine.evaluate(
                predicate: rule.predicate,
                variables: snapshot.values
            ) {
            case .success(true):
                return rule
            case .success(false):
                continue
            case .failure(let error):
                if firstEvaluationError == nil {
                    firstEvaluationError = .predicateEvaluation(ruleIndex: index, error: error)
                }
            }
        }

        if let firstEvaluationError {
            throw firstEvaluationError
        }

        return nil
    }
}
