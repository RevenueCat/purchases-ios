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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallData.LocalizedConfiguration {

    func processVariables(
        with package: Package,
        context: VariableHandler.Context,
        locale: Locale = .current
    ) -> ProcessedLocalizedConfiguration {
        return .init(self, package, context, locale)
    }

}

/// A type that can provide necessary information for `VariableHandler` to replace variable content in strings.
@available(iOS 15.0, *)
protocol VariableDataProvider {

    var applicationName: String { get }

    var packageIdentifier: String { get }

    var productName: String { get }

    func periodNameOrIdentifier(_ locale: Locale) -> String
    func periodNameAbbreviation(_ locale: Locale) -> String?
    func periodLength(_ locale: Locale) -> String?
    func subscriptionDuration(_ locale: Locale) -> String?
    func normalizedSubscriptionDuration(_ locale: Locale) -> String?
    func introductoryOfferDuration(_ locale: Locale) -> String?

    func localizedIntroductoryOfferPrice(showZeroDecimalPlacePrices: Bool) -> String?
    func localizedPricePerWeek(showZeroDecimalPlacePrices: Bool) -> String
    func localizedPricePerMonth(showZeroDecimalPlacePrices: Bool) -> String
    func localizedPrice(showZeroDecimalPlacePrices: Bool) -> String
    func localizedPricePerPeriod(_ locale: Locale, showZeroDecimalPlacePrices: Bool) -> String
    func localizedPricePerPeriodFull(_ locale: Locale, showZeroDecimalPlacePrices: Bool) -> String
    func localizedPriceAndPerMonth(_ locale: Locale, showZeroDecimalPlacePrices: Bool) -> String
    func localizedPriceAndPerMonthFull(_ locale: Locale, showZeroDecimalPlacePrices: Bool) -> String
    func localizedRelativeDiscount(_ discount: Double?, _ locale: Locale) -> String?

}

/// Processes strings, replacing `{{ variable }}` with their associated content.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum VariableHandler {

    /// Information necessary for computing variables
    struct Context {

        var discountRelativeToMostExpensivePerMonth: Double?
        var showZeroDecimalPlacePrices: Bool = false

    }

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider,
        context: Context,
        locale: Locale = .current
    ) -> String {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return VariableHandlerIOS16.processVariables(in: string,
                                                         with: provider,
                                                         context: context,
                                                         locale: locale)
        } else {
            return VariableHandlerIOS15.processVariables(in: string,
                                                         with: provider,
                                                         context: context,
                                                         locale: locale)
        }
    }

    fileprivate static func unrecognizedVariables(in set: Set<String>) -> Set<String> {
        return Set(
            set
                .lazy
                .filter { VariableHandler.provider(for: $0) == nil }
        )
    }

    fileprivate typealias ValueProvider = (VariableDataProvider,
                                           VariableHandler.Context,
                                           Locale) -> String?

    // swiftlint:disable:next cyclomatic_complexity
    fileprivate static func provider(for variableName: String) -> ValueProvider? {
        switch variableName {
        case "app_name": return { (provider, _, _) in provider.applicationName }
        case "price": return { (provider, context, _) in
            provider.localizedPrice(showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "price_per_period": return { (provider, context, locale) in
            provider.localizedPricePerPeriod(locale, showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "price_per_period_full": return { (provider, context, locale) in
            provider.localizedPricePerPeriodFull(locale, showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "total_price_and_per_month": return { (provider, context, locale) in
            provider.localizedPriceAndPerMonth(locale, showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "total_price_and_per_month_full": return { (provider, context, locale) in
            provider
                .localizedPriceAndPerMonthFull(locale, showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "product_name": return { (provider, _, _) in provider.productName }
        case "sub_period": return { (provider, _, locale) in provider.periodNameOrIdentifier(locale) }
        case "sub_period_length": return { (provider, _, locale) in provider.periodLength(locale) }
        case "sub_period_abbreviated": return { (provider, _, locale) in provider.periodNameAbbreviation(locale) }
        case "sub_price_per_month": return { (provider, context, _) in
            provider.localizedPricePerMonth(showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "sub_price_per_week": return { (provider, context, _) in
            provider.localizedPricePerWeek(showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "sub_duration": return { (provider, _, locale) in provider.subscriptionDuration(locale) }
        case "sub_duration_in_months": return { (provider, _, locale) in
            provider.normalizedSubscriptionDuration(locale)
        }
        case "sub_offer_duration": return { (provider, _, locale) in provider.introductoryOfferDuration(locale) }
        case "sub_offer_price": return { (provider, context, _) in
            provider.localizedIntroductoryOfferPrice(showZeroDecimalPlacePrices: context.showZeroDecimalPlacePrices)
        }
        case "sub_relative_discount": return { $0.localizedRelativeDiscount($1.discountRelativeToMostExpensivePerMonth,
                                                                            $2) }

        default:
            Logger.warning(Strings.unrecognized_variable_name(variableName: variableName))
            return nil
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension String {

    func processed(
        with provider: VariableDataProvider,
        context: VariableHandler.Context,
        locale: Locale
    ) -> Self {
        return VariableHandler.processVariables(in: self, with: provider, context: context, locale: locale)
    }

    func unrecognizedVariables() -> Set<String> {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return VariableHandlerIOS16.unrecognizedVariables(in: self)
        } else {
            return VariableHandlerIOS15.unrecognizedVariables(in: self)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension VariableDataProvider {

    func value(
        for variableName: String,
        context: VariableHandler.Context,
        locale: Locale
    ) -> String {
        VariableHandler.provider(for: variableName)?(self, context, locale) ?? ""
    }

}

// MARK: - Regex iOS 16

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private enum VariableHandlerIOS16 {

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider,
        context: VariableHandler.Context,
        locale: Locale = .current
    ) -> String {
        let matches = Self.extractVariables(from: string)
        var replacedString = string

        for variableMatch in matches.reversed() {
            let replacementValue = provider.value(for: variableMatch.variable,
                                                  context: context,
                                                  locale: locale)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum VariableHandlerIOS15 {

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider,
        context: VariableHandler.Context,
        locale: Locale = .current
    ) -> String {
        var replacedString = string
        let matches = Self.regex.matches(in: string, options: [], range: string.range)

        for match in matches.reversed() {
            let variableNameRange = match.range(at: 1)
            if let variableNameRange = Range(variableNameRange, in: string) {
                let variableName = String(string[variableNameRange])
                let replacementValue = provider.value(for: variableName,
                                                      context: context,
                                                      locale: locale)

                let adjustedRange = NSRange(
                    location: variableNameRange.lowerBound.utf16Offset(in: string) - Self.pattern.count / 2,
                    length: string.distance(from: variableNameRange.lowerBound,
                                            to: variableNameRange.upperBound) + Self.pattern.count
                )
                // swiftlint:disable:next force_unwrapping
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
