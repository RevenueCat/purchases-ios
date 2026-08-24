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
    private let currentUserProvider: (any CurrentUserProvider)?

    /// The instant the whole snapshot describes, readable at the root of the scope.
    static let evaluatedAtKey = "evaluatedAt"

    /// Creates a resolver from injected providers, a clock, and the current customer.
    ///
    /// Without a `currentUserProvider` the snapshot describes no customer, so a customer-scoped
    /// provider contributes nothing rather than the wrong thing.
    init(
        dimensionProviders: [any DimensionProvider],
        dateProvider: DateProvider = DateProvider(),
        currentUserProvider: (any CurrentUserProvider)? = nil
    ) {
        self.dimensionProviders = dimensionProviders
        self.dateProvider = dateProvider
        self.currentUserProvider = currentUserProvider
    }

    /// Collects each provider once and merges its values under its namespace.
    ///
    /// For example, device `appVersion: "1.2.3"` becomes
    /// `device.appVersion: "1.2.3"` in the RulesEngine input.
    /// `appUserID` pins the customer for this snapshot. When nil the resolver reads the current one,
    /// which is only right for a caller that has nothing else to keep consistent with it.
    func snapshot(
        customVariables: [String: DimensionValue] = [:],
        appUserID: String? = nil
    ) async throws -> DimensionSnapshot {
        // Both read once, so every provider below describes the same customer at the same
        // instant however long any one of them suspends for.
        let context = DimensionContext(
            date: self.dateProvider.now(),
            appUserID: appUserID ?? self.currentUserProvider?.currentAppUserID ?? ""
        )
        // At the root rather than copied onto every record. A predicate inside an iteration
        // operator reaches it with `rc.rootVar`.
        var values: [String: RulesEngine.Value] = [
            Self.evaluatedAtKey: .int(Int64(context.date.timeIntervalSince1970 * 1_000))
        ]

        for provider in self.dimensionProviders {
            try Task.checkCancellation()

            let providerValues: [String: DimensionValue]
            do {
                providerValues = try await provider.dimensions(in: context)
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

        let validCustomVariables = CustomVariableKeyValidator.validateAndFilter(customVariables)
        let customVariables = DimensionValueConverter.convert(
            validCustomVariables,
            parentPath: DimensionNamespace.custom.rawValue
        )
        if !customVariables.isEmpty {
            values[DimensionNamespace.custom.rawValue] = .object(customVariables)
        }

        try Task.checkCancellation()

        return DimensionSnapshot(values: values, evaluationDate: context.date)
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
