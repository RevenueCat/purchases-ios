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

    private static func extractVariables(from expression: String) -> [VariableMatch] {
        let variablePattern = Regex {
            Capture {
                OneOrMore {
                    "{{ "
                    OneOrMore(.word)
                    " }}"
                }
            }
        }

        return expression.matches(of: variablePattern).map { match in
            let (_, variable) = match.output
            return VariableMatch(variable: String(variable), range: match.range)
        }
    }

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider
    ) -> String {
        let matches = extractVariables(from: string)
        var replacedString = string

        for variableMatch in matches {
            let replacementValue = provider.value(for: variableMatch.variable)

            let adjustedRange = NSRange(
                location: variableMatch.range.lowerBound.utf16Offset(in: string) - Self.startPattern.count,
                length: string.distance(from: variableMatch.range.lowerBound,
                                        to: variableMatch.range.upperBound)
                + Self.startPattern.count
                + Self.endPattern.count
            )
            let replacementRange = Range(adjustedRange, in: replacedString)!

            replacedString = replacedString.replacingCharacters(in: replacementRange, with: replacementValue)
        }

        return replacedString
    }

    private static let startPattern = "{{ "
    private static let endPattern = " }}"

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
