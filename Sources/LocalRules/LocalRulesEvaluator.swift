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

/// Evaluates rules against fresh, locally collected variables.
///
/// Evaluation returns no identifier when a snapshot cannot be collected or no valid rule matches.
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
    func firstMatch<Rule: LocalRule>(in rules: [Rule]) async -> Rule.ID? {
        guard !rules.isEmpty,
              let snapshot = try? await self.variableResolver.snapshot() else {
            return nil
        }

        for rule in rules {
            if case .success(true) = RulesEngine.evaluate(
                predicate: rule.predicate,
                variables: snapshot.values
            ) {
                return rule.id
            }
        }

        return nil
    }

    /// Returns whether any rule matches, using one snapshot and stopping at the first match.
    func matchesAny<Rule: LocalRule>(in rules: [Rule]) async -> Bool {
        await self.firstMatch(in: rules) != nil
    }
}
