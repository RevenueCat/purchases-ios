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
    func snapshot(
        customVariables: [String: DimensionValue] = [:],
        backendValues: [String: DimensionValue] = [:]
    ) async throws -> DimensionSnapshot {
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

            for (name, value) in DimensionValueConverter.convert(
                providerValues,
                parentPath: namespace
            ) {
                guard namespaceValues[name] == nil else {
                    throw DimensionResolutionError.conflictingValue(
                        path: "\(namespace).\(name)"
                    )
                }

                namespaceValues[name] = value
            }

            if !namespaceValues.isEmpty {
                values[namespace] = .object(namespaceValues)
            }
        }

        Self.addPerEvaluationValues(
            CustomVariableKeyValidator.validateAndFilter(customVariables),
            namespace: .custom,
            to: &values
        )
        Self.addPerEvaluationValues(
            backendValues,
            namespace: .backend,
            to: &values
        )

        try Task.checkCancellation()

        return DimensionSnapshot(values: values, evaluationDate: date)
    }

    private static func addPerEvaluationValues(
        _ dimensions: [String: DimensionValue],
        namespace: DimensionNamespace,
        to values: inout [String: RulesEngine.Value]
    ) {
        let converted = DimensionValueConverter.convert(dimensions, parentPath: namespace.rawValue)
        if !converted.isEmpty {
            values[namespace.rawValue] = .object(converted)
        }
    }
}

private enum DimensionValueConverter {

    static func convert(
        _ dimensions: [String: DimensionValue],
        parentPath: String
    ) -> [String: RulesEngine.Value] {
        return dimensions.reduce(into: [:]) { result, dimension in
            let (name, value) = dimension
            guard Self.isValidName(name) else {
                Logger.warn(Strings.remoteConfig.invalidDimensionName(name, parentPath: parentPath))
                return
            }

            guard let converted = Self.convert(value, path: "\(parentPath).\(name)") else {
                return
            }

            result[name] = converted
        }
    }

    /// Converts a provider value into its RulesEngine equivalent while filtering invalid nested names.
    private static func convert(_ dimension: DimensionValue, path: String) -> RulesEngine.Value? {
        switch dimension {
        case .string(let value): return .string(value)
        case .bool(let value): return .bool(value)
        case .int(let value): return .int(value)
        case .double(let value): return .float(value)
        case .date(let value): return .int(Int64(value.timeIntervalSince1970 * 1_000))
        case .object(let value):
            let converted = Self.convert(value, parentPath: path)
            return converted.isEmpty ? nil : .object(converted)
        case .objectList(let values):
            return .array(values.enumerated().compactMap { index, value in
                let converted = Self.convert(value, parentPath: "\(path).\(index)")
                return converted.isEmpty ? nil : .object(converted)
            })
        }
    }

    private static func isValidName(_ name: String) -> Bool {
        return name.notEmptyOrWhitespaces != nil && !name.contains(Self.pathSeparator)
    }

    private static let pathSeparator: Character = "."
}
