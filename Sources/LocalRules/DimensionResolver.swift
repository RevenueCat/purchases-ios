//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DimensionResolver.swift
//
//  Created by Rick van der Linden on 7/28/26.
//

import Foundation

struct DimensionSnapshot: Equatable, Sendable {

    let values: [String: RulesEngine.Value]
    let evaluationDate: Date
}

enum DimensionResolutionError: Error, Equatable, Sendable {

    case providerFailed(namespace: DimensionNamespace, message: String)
    case conflictingValue(path: String)
}

/// Builds immutable, point-in-time dimension scopes for local rule evaluation.
struct DimensionResolver: Sendable {

    private let dimensionProviders: [any DimensionProvider]
    private let dateProvider: DateProvider

    /// Creates a resolver from injected providers and a clock.
    init(
        dimensionProviders: [any DimensionProvider],
        dateProvider: DateProvider = DateProvider()
    ) {
        self.dimensionProviders = dimensionProviders
        self.dateProvider = dateProvider
    }

    /// Collects each provider once and merges its values under its namespace.
    ///
    /// For example, device `appVersion: "1.2.3"` becomes
    /// `device.appVersion: "1.2.3"` in the RulesEngine input.
    func snapshot(customVariables: [String: DimensionValue] = [:]) async throws -> DimensionSnapshot {
        let date = self.dateProvider.now()
        var values: [String: RulesEngine.Value] = [:]

        for provider in self.dimensionProviders {
            try Task.checkCancellation()

            let providerValues: [String: DimensionValue]
            do {
                providerValues = try await provider.dimensions(at: date)
            } catch let error as CancellationError {
                throw error
            } catch {
                throw DimensionResolutionError.providerFailed(
                    namespace: provider.namespace,
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
                    throw DimensionResolutionError.conflictingValue(
                        path: "\(namespace).\(name)"
                    )
                }

                namespaceValues[name] = value.rulesEngineValue
            }

            values[namespace] = .object(namespaceValues)
        }

        if !customVariables.isEmpty {
            values[DimensionNamespace.custom.rawValue] = .object(
                customVariables.mapValues(\.rulesEngineValue)
            )
        }

        try Task.checkCancellation()

        return DimensionSnapshot(values: values, evaluationDate: date)
    }
}

private extension DimensionValue {

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
