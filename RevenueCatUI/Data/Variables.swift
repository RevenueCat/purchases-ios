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

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension String {

    func processed(with provider: VariableDataProvider, locale: Locale) -> Self {
        return VariableHandler.processVariables(in: self, with: provider, locale: locale)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension VariableDataProvider {

    // swiftlint:disable:next cyclomatic_complexity
    func value(for variableName: String, locale: Locale) -> String {
        switch variableName {
        case "app_name": return self.applicationName
        case "price": return self.localizedPrice
        case "price_per_period": return self.localizedPricePerPeriod(locale)
        case "total_price_and_per_month": return self.localizedPriceAndPerMonth(locale)
        case "product_name": return self.productName
        case "sub_period": return self.periodName(locale)
        case "sub_price_per_month": return self.localizedPricePerMonth
        case "sub_duration": return self.subscriptionDuration(locale) ?? ""
        case "sub_offer_duration": return self.introductoryOfferDuration(locale) ?? ""
        case "sub_offer_price": return self.localizedIntroductoryOfferPrice ?? ""

        default:
            Logger.warning(Strings.unrecognized_variable_name(variableName: variableName))
            return ""
        }
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
        let range = NSRange(string.startIndex..., in: string)
        let matches = Self.regex.matches(in: string, options: [], range: range)

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

    private static let pattern = "{{  }}"
    // Fix-me: this can be implemented using the new Regex from Swift.
    // This regex is known at compile time and tested:
    // swiftlint:disable:next force_try
    private static let regex = try! NSRegularExpression(pattern: "\\{\\{ (\\w+) \\}\\}", options: [])

}
