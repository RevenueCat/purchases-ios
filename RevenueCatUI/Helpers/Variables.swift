import Foundation
import RevenueCat
import RegexBuilder

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension PaywallData.LocalizedConfiguration {

    func processVariables(with package: Package) -> ProcessedLocalizedConfiguration {
        return .init(self, package)
    }

}

/// A type that can provide necessary information for `VariableHandler` to replace variable content in strings.
protocol VariableDataProvider {

    var localizedPrice: String { get }
    var localizedPricePerMonth: String { get }
    var productName: String { get }
    var introductoryOfferDuration: String? { get }

}

struct VariableMatch {
    let variable: String
    let range: Range<String.Index>
}


/// Processes strings, replacing `{{variable}}` with their associated content.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
enum VariableHandler {

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider
    ) -> String {
        let matches = extractVariables(from: string)
        var replacedString = string

        for variableMatch in matches.reversed() {
            let replacementValue = provider.value(for: variableMatch.variable)
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

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension String {

    func processed(with provider: VariableDataProvider) -> Self {
        return VariableHandler.processVariables(in: self, with: provider)
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension VariableDataProvider {

    func value(for variableName: String) -> String {
        switch variableName {
        case "price": return self.localizedPrice
        case "price_per_month": return self.localizedPricePerMonth
        case "product_name": return self.productName
        case "intro_duration":
            guard let introDuration = self.introductoryOfferDuration else {
                Logger.warning(
                    "Unexpectedly tried to look for intro duration when there is none, this is a logic error."
                )
                return ""
            }

            return introDuration

        default:
            Logger.warning("Couldn't find content for variable '\(variableName)'")
            return ""
        }
    }

}
