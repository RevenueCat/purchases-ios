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

    case providerFailed(providerName: String, message: String)
    case conflictingValue(path: String)
}

/// Builds an immutable, point-in-time root scope for local rule evaluation.
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

    /// Collects each provider once and merges its values into the canonical root scope.
    ///
    /// `custom` and `backend` remain nested reserved objects. Every other value is flat.
    func snapshot(
        customVariables: [String: DimensionValue] = [:],
        backendValues: [String: DimensionValue] = [:]
    ) async throws -> DimensionSnapshot {
        let date = self.dateProvider.now()
        var values: [String: RulesEngine.Value] = [
            Self.evaluatedAtKey: .int(Int64(date.timeIntervalSince1970 * 1_000))
        ]

        for provider in self.dimensionProviders {
            try Task.checkCancellation()

            let providerValues: [String: DimensionValue]
            do {
                providerValues = try await provider.dimensions(at: date)
            } catch let error as CancellationError {
                throw error
            } catch {
                throw DimensionResolutionError.providerFailed(
                    providerName: provider.name,
                    message: String(describing: error)
                )
            }

            for (name, value) in DimensionValueConverter.convert(
                providerValues,
                parentPath: provider.name
            ) {
                guard !Self.reservedRootKeys.contains(name), values[name] == nil else {
                    throw DimensionResolutionError.conflictingValue(
                        path: name
                    )
                }

                values[name] = value
            }
        }

        Self.addPerEvaluationValues(
            CustomVariableKeyValidator.validateAndFilter(customVariables),
            root: Self.customKey,
            to: &values
        )
        Self.addPerEvaluationValues(
            backendValues,
            root: Self.backendKey,
            to: &values
        )

        try Task.checkCancellation()

        return DimensionSnapshot(values: values, evaluationDate: date)
    }

    private static func addPerEvaluationValues(
        _ dimensions: [String: DimensionValue],
        root: String,
        to values: inout [String: RulesEngine.Value]
    ) {
        let converted = DimensionValueConverter.convert(dimensions, parentPath: root)
        if !converted.isEmpty {
            values[root] = .object(converted)
        }
    }

    private static let evaluatedAtKey = "evaluated_at"
    private static let customKey = "custom"
    private static let backendKey = "backend"
    private static let reservedRootKeys: Set<String> = [Self.evaluatedAtKey, Self.customKey, Self.backendKey]
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
