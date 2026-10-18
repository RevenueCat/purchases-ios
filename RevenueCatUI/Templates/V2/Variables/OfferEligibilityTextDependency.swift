//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferEligibilityTextDependency.swift
//

import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VariablesV2 {

    /// Substitution reads the discount selected from intro and promo eligibility.
    var dependsOnOfferEligibility: Bool {
        return self.rawValue.hasPrefix("product.offer_")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VariableHandlerV2 {

    /// Whether `text` contains a variable whose value is chosen from intro or promo eligibility.
    static func textDependsOnOfferEligibility(
        _ text: String,
        variableCompatibilityMap: [String: String]
    ) -> Bool {
        return OfferEligibilityPlaceholder.variableNames(in: text).contains { variableName in
            self.resolvedVariable(
                variableName,
                variableCompatibilityMap: variableCompatibilityMap
            )?.dependsOnOfferEligibility == true
        }
    }

    /// Same name resolution as `findVariable`, without logging unrecognized names.
    private static func resolvedVariable(
        _ variableRaw: String,
        variableCompatibilityMap: [String: String]
    ) -> VariablesV2? {
        if let variable = VariablesV2(rawValue: variableRaw) {
            return variable
        }

        guard let mappedName = variableCompatibilityMap[variableRaw] else {
            return nil
        }

        return VariablesV2(rawValue: mappedName)
    }

}

/// Placeholder syntax shared with `Whisker`: `{{ variable | function }}`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum OfferEligibilityPlaceholder {

    // swiftlint:disable:next force_try
    private static let regex = try! NSRegularExpression(pattern: "\\{\\{\\s*(.*?)\\s*\\}\\}")

    static func variableNames(in template: String) -> [String] {
        return self.regex.matches(
            in: template,
            range: NSRange(template.startIndex..., in: template)
        ).compactMap { match in
            guard let range = Range(match.range(at: 1), in: template) else {
                return nil
            }

            let expression = String(template[range])
            let parts = expression.split(separator: "|").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard let variableName = parts.first, !variableName.isEmpty else {
                return nil
            }

            return variableName
        }
    }

}
