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

/// The outcome of evaluating an ordered collection of local rules.
enum LocalRulesEvaluationResult<ID: Sendable>: Sendable {

    case matched(ID)
    case notMatched
    case indeterminate(LocalRulesEvaluationError)
}

extension LocalRulesEvaluationResult: Equatable where ID: Equatable {}

/// A failure that prevented local rules from producing a definitive non-match.
enum LocalRulesEvaluationError: Error, Equatable, Sendable {

    case variableResolution(RulesVariableResolutionError)
    case predicateEvaluation(ruleIndex: Int, error: RulesEngine.EvaluationError)
    case unexpected(message: String)
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

    /// Returns the first matching rule, using one snapshot for the full call.
    ///
    /// For example, rules `[("a", false), ("b", true)]` return `.matched("b")`.
    func match<Rule: LocalRule>(in rules: [Rule]) async -> LocalRulesEvaluationResult<Rule.ID> {
        guard !rules.isEmpty else {
            return .notMatched
        }

        let snapshot: RulesVariableSnapshot
        do {
            snapshot = try await self.variableResolver.snapshot()
        } catch let error as RulesVariableResolutionError {
            return .indeterminate(.variableResolution(error))
        } catch {
            return .indeterminate(.unexpected(message: String(describing: error)))
        }

        var firstEvaluationError: LocalRulesEvaluationError?

        for (index, rule) in rules.enumerated() {
            switch RulesEngine.evaluate(
                predicate: rule.predicate,
                variables: snapshot.values
            ) {
            case .success(true):
                return .matched(rule.id)
            case .success(false):
                continue
            case .failure(let error):
                if firstEvaluationError == nil {
                    firstEvaluationError = .predicateEvaluation(ruleIndex: index, error: error)
                }
            }
        }

        return firstEvaluationError.map(LocalRulesEvaluationResult.indeterminate) ?? .notMatched
    }

    /// Returns whether any rule matches, treating an indeterminate result as no match.
    func matchesAny<Rule: LocalRule>(in rules: [Rule]) async -> Bool {
        if case .matched = await self.match(in: rules) {
            return true
        } else {
            return false
        }
    }
}
