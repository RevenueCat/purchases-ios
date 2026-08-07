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

/// An identified rule that can be evaluated against locally collected variables.
protocol LocalRule: Sendable {

    // swiftlint:disable:next type_name
    associatedtype ID: Sendable

    var id: ID { get }
    var predicate: String { get }
}

/// A predicate failure that prevented local rules from producing a definitive non-match.
enum LocalRulesEvaluationError: Error, Equatable, Sendable {

    case predicateEvaluation(ruleIndex: Int, error: RulesEngine.EvaluationError)
}

/// Evaluates rules against fresh, locally collected variables.
final class LocalRulesEvaluator: Sendable {

    private let variableResolver: RulesVariableResolver

    init(
        providers: [any RulesVariableProvider],
        dateProvider: DateProvider = DateProvider()
    ) {
        self.variableResolver = RulesVariableResolver(
            providers: providers,
            dateProvider: dateProvider
        )
    }

    /// Returns the first matching rule identifier, using one snapshot for the full call.
    ///
    /// For example, rules `[("a", false), ("b", true)]` return `"b"`.
    func match<Rule: LocalRule>(in rules: [Rule]) async throws -> Rule.ID? {
        guard !rules.isEmpty else {
            return nil
        }

        let snapshot = try await self.variableResolver.snapshot()

        var firstEvaluationError: LocalRulesEvaluationError?

        for (index, rule) in rules.enumerated() {
            switch RulesEngine.evaluate(
                predicate: rule.predicate,
                variables: snapshot.values
            ) {
            case .success(true):
                return rule.id
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

    /// Returns whether any rule matches.
    func matchesAny<Rule: LocalRule>(in rules: [Rule]) async throws -> Bool {
        try await self.match(in: rules) != nil
    }
}
