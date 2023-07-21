import Foundation
import RegexBuilder
import RevenueCat

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension PaywallData.LocalizedConfiguration {

    func processVariables(with package: Package, locale: Locale = .current) -> ProcessedLocalizedConfiguration {
        return .init(self, package, locale)
    }

}

/// A type that can provide necessary information for `VariableHandler` to replace variable content in strings.
protocol VariableDataProvider {

    var localizedPrice: String { get }
    var localizedPricePerMonth: String { get }
    var productName: String { get }
    func introductoryOfferDuration(_ locale: Locale) -> String?

}

/// Processes strings, replacing `{{variable}}` with their associated content.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
enum VariableHandler {

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
        let variablePattern = Regex {
            OneOrMore {
                "{{ "
                Capture {
                    OneOrMore(.word)
                }
                " }}"
            }
        }

        return expression.matches(of: variablePattern).map { match in
            let (_, variable) = match.output
            return VariableMatch(variable: String(variable), range: match.range)
        }
    }

    private struct VariableMatch {

        let variable: String
        let range: Range<String.Index>

    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension String {

    func processed(with provider: VariableDataProvider, locale: Locale) -> Self {
        return VariableHandler.processVariables(in: self, with: provider, locale: locale)
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension VariableDataProvider {

    func value(for variableName: String, locale: Locale) -> String {
        switch variableName {
        case "price": return self.localizedPrice
        case "price_per_month": return self.localizedPricePerMonth
        case "total_price_and_per_month":
            let price = self.localizedPrice
            let perMonth = self.localizedPricePerMonth

            if price == perMonth {
                return price
            } else {
                let unit = Localization.abbreviatedUnitLocalizedString(for: .month, locale: locale)
                return "\(price) (\(perMonth)/\(unit))"
            }

        case "product_name": return self.productName
        case "intro_duration":
            return self.introductoryOfferDuration(locale) ?? ""

        default:
            Logger.warning("Couldn't find content for variable '\(variableName)'")
            return ""
        }
    }

}
