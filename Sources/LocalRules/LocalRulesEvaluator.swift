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

/// A predicate failure encountered while evaluating local rules.
enum LocalRulesEvaluationError: Error, Equatable, Sendable {

    case predicateEvaluation(ruleIndex: Int, error: RulesEngine.EvaluationError)
}

/// Evaluates rules against fresh, locally collected dimensions.
final class LocalRulesEvaluator: Sendable {

    private let dimensionResolver: DimensionResolver

    init(
        dimensionProviders: [any DimensionProvider],
        currentAppUserIDProvider: @escaping @Sendable () -> String,
        dateProvider: DateProvider = DateProvider()
    ) {
        self.dimensionResolver = DimensionResolver(
            dimensionProviders: dimensionProviders,
            currentAppUserIDProvider: currentAppUserIDProvider,
            dateProvider: dateProvider
        )
    }

    /// Returns the first matching rule, using one snapshot for the full call.
    ///
    /// For example, rules `[("a", false), ("b", true)]` return the second rule.
    /// Developer-supplied values are available to predicates under `custom.*`.
    /// `logPrefix` is prepended to diagnostic messages without logging predicate or dimension values.
    func match<Rule: LocalRule>(
        in rules: [Rule],
        customVariables: [String: DimensionValue] = [:],
        logPrefix: String = ""
    ) async throws -> Rule? {
        return try await self.match(
            in: rules,
            customVariables: customVariables,
            logPrefix: logPrefix
        ) { $0.predicate }
    }

    /// Same, for rules that don't carry their own predicate and have to look it up.
    ///
    /// The predicate is resolved one rule at a time, so a rule after the match never pays for a lookup. A
    /// predicate that references an unavailable local value is treated as a non-match, allowing evaluation
    /// to continue with the remaining rules. Other evaluation errors are retained and thrown if no rule
    /// matches.
    func match<Rule: Sendable>(
        in rules: [Rule],
        customVariables: [String: DimensionValue] = [:],
        logPrefix: String = "",
        predicate resolvePredicate: (Rule) async throws -> String
    ) async throws -> Rule? {
        guard !rules.isEmpty else { return nil }

        let snapshot = try await self.dimensionResolver.snapshot(
            customVariables: customVariables
        )

        Logger.verbose(Strings.localRules.evaluatingRules(
            logPrefix: logPrefix,
            ruleCount: rules.count,
            dimensions: snapshot.values.keys.sorted()
        ))

        var firstEvaluationError: LocalRulesEvaluationError?

        for (index, rule) in rules.enumerated() {
            let predicate = try await resolvePredicate(rule)
            try Task.checkCancellation()

            let result = RulesEngine.evaluate(
                predicate: predicate,
                variables: snapshot.values
            )
            let outcome = self.logEvaluationResult(
                result,
                logPrefix: logPrefix,
                ruleIndex: index + 1
            )
            if outcome.matched {
                return rule
            }
            if let error = outcome.error, firstEvaluationError == nil {
                firstEvaluationError = .predicateEvaluation(ruleIndex: index, error: error)
            }
        }

        if let firstEvaluationError {
            throw firstEvaluationError
        }

        return nil
    }

    private func logEvaluationResult(
        _ result: Result<Bool, RulesEngine.EvaluationError>,
        logPrefix: String,
        ruleIndex: Int
    ) -> (matched: Bool, error: RulesEngine.EvaluationError?) {
        switch result {
        case .success(true):
            Logger.verbose(Strings.localRules.ruleMatched(logPrefix: logPrefix, ruleIndex: ruleIndex))
            return (true, nil)
        case .success(false):
            Logger.verbose(Strings.localRules.ruleDidNotMatch(logPrefix: logPrefix, ruleIndex: ruleIndex))
            return (false, nil)
        case .failure(let error):
            switch error {
            case .unresolvedVariable(let path):
                Logger.verbose(Strings.localRules.ruleUnresolvedVariable(
                    logPrefix: logPrefix,
                    ruleIndex: ruleIndex,
                    path: path
                ))
                return (false, nil)
            default:
                Logger.debug(Strings.localRules.ruleEvaluationFailed(
                    logPrefix: logPrefix,
                    ruleIndex: ruleIndex,
                    errorKind: error.logName
                ))
                return (false, error)
            }
        }
    }
}

private extension RulesEngine.EvaluationError {

    var logName: String {
        switch self {
        case .parse: return "Parse"
        case .unresolvedVariable: return "UnresolvedVariable"
        case .typeMismatch: return "TypeMismatch"
        case .unsupportedOperator: return "UnsupportedOperator"
        case .unknown: return "Unknown"
        }
    }

}
