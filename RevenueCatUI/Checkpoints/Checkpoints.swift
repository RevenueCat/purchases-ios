//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Checkpoints.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CustomVariableValue {

    var coreCheckpointValue: RevenueCat.CheckpointValue {
        return self.map(
            string: { .string($0) },
            number: { .double($0) },
            boolean: { .boolean($0) }
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointCallParams: @unchecked Sendable {

    let customVariables: [String: CustomVariableValue]
    let localPaywallPresentationHandler: PaywallPresentationHandler?
    let presentationMode: FlowPresentationMode
    let localErrorPresentationHandler: ErrorPresentationHandler?

    init(
        customVariables: [String: Any?] = [:],
        presentationMode: FlowPresentationMode = .default,
        paywallPresenter: PaywallPresentationHandler? = nil,
        errorPresenter: ErrorPresentationHandler? = nil
    ) {
        self.customVariables = CheckpointCustomVariableParser.parse(customVariables)
        self.presentationMode = presentationMode.resolved
        self.localPaywallPresentationHandler = paywallPresenter
        self.localErrorPresentationHandler = errorPresenter
    }

    var coreParams: RevenueCat.CheckpointParams {
        return .init(customVariables: self.customVariables.mapValues(\.coreCheckpointValue))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum CheckpointCustomVariableParser {

    static func parse(_ customVariables: [String: Any?]) -> [String: CustomVariableValue] {
        let variablesWithValidKeys = RevenueCat.CustomVariableKeyValidator.validateAndFilter(customVariables)
        return variablesWithValidKeys.reduce(into: [:]) { result, entry in
            let (key, value) = entry

            guard let value else {
                Logger.warning(Self.invalidValueLogMessage(key: key, value: nil))
                return
            }

            if let customVariableValue = Self.parse(value) {
                result[key] = customVariableValue
            } else {
                Logger.warning(Self.invalidValueLogMessage(key: key, value: value))
            }
        }
    }

    private static func parse(_ value: Any) -> CustomVariableValue? {
        if let value = value as? CustomVariableValue {
            return value
        } else if Swift.type(of: value) == String.self, let value = value as? String {
            return .string(value)
        } else if Swift.type(of: value) == Int.self, let value = value as? Int {
            return .number(Double(value))
        } else if Swift.type(of: value) == Int64.self, let value = value as? Int64 {
            return .number(Double(value))
        } else if Swift.type(of: value) == Double.self, let value = value as? Double {
            return .number(value)
        } else if Swift.type(of: value) == Float.self, let value = value as? Float {
            return .number(Double(value))
        } else if Swift.type(of: value) == Bool.self, let value = value as? Bool {
            return .bool(value)
        } else {
            return nil
        }
    }

    static func invalidValueLogMessage(key: String, value: Any?) -> String {
        let typeName = value.map { String(reflecting: type(of: $0)) } ?? "nil"
        return "Dropping invalid checkpoint custom variable '\(key)': \(typeName). " +
            "Values must be strings, numbers, or booleans."
    }

}
