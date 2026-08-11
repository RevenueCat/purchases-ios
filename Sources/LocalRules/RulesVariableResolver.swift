//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesVariableResolver.swift
//
//  Created by Rick van der Linden on 7/28/26.
//

import Foundation

struct RulesVariableSnapshot: Equatable, Sendable {

    let values: [String: RulesEngine.Value]
    let evaluationDate: Date
}

enum RulesVariableResolutionError: Error, Equatable, Sendable {

    case providerFailed(identifier: String, message: String)
    case conflictingValue(path: String)
}

/// Builds immutable, point-in-time variable scopes for local rule evaluation.
struct RulesVariableResolver: Sendable {

    private let providers: [any RulesVariableProvider]
    private let dateProvider: DateProvider

    /// Creates a resolver from injected providers and a clock.
    init(
        providers: [any RulesVariableProvider],
        dateProvider: DateProvider = DateProvider()
    ) {
        self.providers = providers
        self.dateProvider = dateProvider
    }

    /// Collects each provider once and merges its values under its namespace.
    ///
    /// For example, device `app_version: "1.2.3"` becomes
    /// `device.app_version: "1.2.3"` in the RulesEngine input.
    func snapshot() async throws -> RulesVariableSnapshot {
        let date = self.dateProvider.now()
        var values: [String: RulesEngine.Value] = [:]

        for provider in self.providers {
            try Task.checkCancellation()

            let providerValues: [String: RulesVariableValue]
            do {
                providerValues = try await provider.variables(at: date)
            } catch let error as CancellationError {
                throw error
            } catch {
                throw RulesVariableResolutionError.providerFailed(
                    identifier: provider.identifier,
                    message: String(describing: error)
                )
            }

            let namespace = provider.namespace.rawValue
            var namespaceValues: [String: RulesEngine.Value] = [:]
            if case .object(let existing) = values[namespace] {
                namespaceValues = existing
            }

            for (name, value) in providerValues {
                guard namespaceValues[name] == nil else {
                    throw RulesVariableResolutionError.conflictingValue(
                        path: "\(namespace).\(name)"
                    )
                }

                namespaceValues[name] = value.rulesEngineValue
            }

            values[namespace] = .object(namespaceValues)
        }

        try Task.checkCancellation()

        return RulesVariableSnapshot(values: values, evaluationDate: date)
    }
}

private extension RulesVariableValue {

    /// Converts a provider scalar into its RulesEngine equivalent.
    ///
    /// For example, `.double(3)` becomes `.float(3)`.
    var rulesEngineValue: RulesEngine.Value {
        switch self {
        case .string(let value): return .string(value)
        case .bool(let value): return .bool(value)
        case .int(let value): return .int(value)
        case .double(let value): return .float(value)
        }
    }
}
