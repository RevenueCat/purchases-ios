//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//   TestData.swift

import Foundation
import RegexBuilder
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PaywallData.LocalizedConfiguration {

    func processVariables(with package: Package, locale: Locale = .current) -> ProcessedLocalizedConfiguration {
        return .init(self, package, locale)
    }

}

/// A type that can provide necessary information for `VariableHandler` to replace variable content in strings.
protocol VariableDataProvider {

    var applicationName: String { get }

    var localizedPrice: String { get }
    var localizedPricePerMonth: String { get }
    var localizedIntroductoryOfferPrice: String? { get }
    var productName: String { get }

    func periodName(_ locale: Locale) -> String
    func subscriptionDuration(_ locale: Locale) -> String?
    func introductoryOfferDuration(_ locale: Locale) -> String?

    func localizedPricePerPeriod(_ locale: Locale) -> String
    func localizedPriceAndPerMonth(_ locale: Locale) -> String

}

/// Processes strings, replacing `{{ variable }}` with their associated content.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
enum VariableHandler {

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider,
        locale: Locale = .current
    ) -> String {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            return VariableHandlerIOS16.processVariables(in: string, with: provider, locale: locale)
        } else {
            return VariableHandlerIOS15.processVariables(in: string, with: provider, locale: locale)
        }
    }

    fileprivate static func unrecognizedVariables(in set: Set<String>) -> Set<String> {
        return Set(
            set
                .lazy
                .filter { VariableHandler.provider(for: $0) == nil }
        )
    }

    fileprivate typealias ValueProvider = (VariableDataProvider, Locale) -> String?

    // swiftlint:disable:next cyclomatic_complexity
    fileprivate static func provider(for variableName: String) -> ValueProvider? {
        switch variableName {
        case "app_name": return { (provider, _) in provider.applicationName }
        case "price": return { (provider, _) in provider.localizedPrice }
        case "price_per_period": return { $0.localizedPricePerPeriod($1) }
        case "total_price_and_per_month": return { $0.localizedPriceAndPerMonth($1) }
        case "product_name": return { (provider, _) in provider.productName }
        case "sub_period": return { $0.periodName($1) }
        case "sub_price_per_month": return { (provider, _) in provider.localizedPricePerMonth }
        case "sub_duration": return { $0.subscriptionDuration($1) }
        case "sub_offer_duration": return { $0.introductoryOfferDuration($1) }
        case "sub_offer_price": return { (provider, _) in provider.localizedIntroductoryOfferPrice }

        default:
            Logger.warning(Strings.unrecognized_variable_name(variableName: variableName))
            return nil
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension String {

    func processed(with provider: VariableDataProvider, locale: Locale) -> Self {
        return VariableHandler.processVariables(in: self, with: provider, locale: locale)
    }

    func unrecognizedVariables() -> Set<String> {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            return VariableHandlerIOS16.unrecognizedVariables(in: self)
        } else {
            return VariableHandlerIOS15.unrecognizedVariables(in: self)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension VariableDataProvider {

    func value(for variableName: String, locale: Locale) -> String {
        VariableHandler.provider(for: variableName)?(self, locale) ?? ""
    }

}

// MARK: - Regex iOS 16

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private enum VariableHandlerIOS16 {

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider,
        locale: Locale = .current
    ) -> String {
        let matches = Self.extractVariables(from: string)
        var replacedString = string

        for variableMatch in matches.reversed() {
            let replacementValue = provider.value(for: variableMatch.variable, locale: locale)
            replacedString = replacedString.replacingCharacters(in: variableMatch.range, with: replacementValue)
        }

        return replacedString
    }

    static func unrecognizedVariables(in string: String) -> Set<String> {
        return VariableHandler.unrecognizedVariables(
            in: Set(Self.extractVariables(from: string).map(\.variable))
        )
    }

    private static func extractVariables(from expression: String) -> [VariableMatch] {
        return expression.matches(of: Self.regex).map { match in
            let (_, variable) = match.output
            return VariableMatch(variable: String(variable), range: match.range)
        }
    }

    private struct VariableMatch {

        let variable: String
        let range: Range<String.Index>

    }

    private static let regex = Regex {
        OneOrMore {
            "{{ "
            Capture {
                OneOrMore(.word)
            }
            " }}"
        }
    }

}

// MARK: - Regex iOS 15

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private enum VariableHandlerIOS15 {

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider,
        locale: Locale = .current
    ) -> String {
        var replacedString = string
        let matches = Self.regex.matches(in: string, options: [], range: string.range)

        for match in matches.reversed() {
            let variableNameRange = match.range(at: 1)
            if let variableNameRange = Range(variableNameRange, in: string) {
                let variableName = String(string[variableNameRange])
                let replacementValue = provider.value(for: variableName, locale: locale)

                let adjustedRange = NSRange(
                    location: variableNameRange.lowerBound.utf16Offset(in: string) - Self.pattern.count / 2,
                    length: string.distance(from: variableNameRange.lowerBound,
                                            to: variableNameRange.upperBound) + Self.pattern.count
                )
                let replacementRange = Range(adjustedRange, in: replacedString)!
                replacedString = replacedString.replacingCharacters(in: replacementRange, with: replacementValue)
            }
        }

        return replacedString
    }

    static func unrecognizedVariables(in string: String) -> Set<String> {
        let matches = Self.regex.matches(in: string, options: [], range: string.range)

        var variables: Set<String> = []
        for match in matches {
            if let variableNameRange = Range(match.range(at: 1), in: string) {
                variables.insert(String(string[variableNameRange]))
            }
        }

        return VariableHandler.unrecognizedVariables(in: variables)
    }

    private static let pattern = "{{  }}"
    // Fix-me: this can be implemented using the new Regex from Swift.
    // This regex is known at compile time and tested:
    // swiftlint:disable:next force_try
    private static let regex = try! NSRegularExpression(pattern: "\\{\\{ (\\w+) \\}\\}", options: [])

}

private extension String {

    var range: NSRange { .init(self.startIndex..., in: self) }

}
