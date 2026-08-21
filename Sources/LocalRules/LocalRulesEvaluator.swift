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
        return try await self.match(in: rules, customVariables: customVariables) { $0.predicate }
    }

    /// Same, for rules that don't carry their own predicate and have to look it up.
    ///
    /// The predicate is resolved one rule at a time, so a rule after the match never pays for a lookup. A
    /// lookup that throws ends the call: a predicate the SDK couldn't obtain is not the same answer as one
    /// that evaluated to false, so the remaining rules can't be walked as if it hadn't matched.
    func match<Rule: Sendable>(
        in rules: [Rule],
        customVariables: [String: DimensionValue] = [:],
        predicate resolvePredicate: (Rule) async throws -> String
    ) async throws -> Rule? {
        guard !rules.isEmpty else {
            return nil
        }

        let snapshot = try await self.dimensionResolver.snapshot(customVariables: customVariables)

        var firstEvaluationError: LocalRulesEvaluationError?

        for (index, rule) in rules.enumerated() {
            let predicate = try await resolvePredicate(rule)
            try Task.checkCancellation()

            switch RulesEngine.evaluate(
                predicate: predicate,
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
