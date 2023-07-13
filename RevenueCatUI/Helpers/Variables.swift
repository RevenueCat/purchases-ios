import Foundation
import RevenueCat

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension PaywallData.LocalizedConfiguration {

    func processVariables(with package: Package) -> ProcessedLocalizedConfiguration {
        return .init(self, package)
    }

}

/// A type that can provide necessary information for `VariableHandler` to replace variable content in strings.
protocol VariableDataProvider {

    var localizedPricePerMonth: String { get }
    var productName: String { get }
    var introductoryOfferDuration: String? { get }

}

/// Processes strings, replacing `{{variable}}` with their associated content.
enum VariableHandler {

    static func processVariables(
        in string: String,
        with provider: VariableDataProvider
    ) -> String {
        var replacedString = string
        let range = NSRange(string.startIndex..., in: string)
        let matches = Self.regex.matches(in: string, options: [], range: range)

        for match in matches.reversed() {
            let variableNameRange = match.range(at: 1)
            if let variableNameRange = Range(variableNameRange, in: string) {
                let variableName = String(string[variableNameRange])
                let replacementValue = provider.value(for: variableName)

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

extension String {

    func processed(with provider: VariableDataProvider) -> Self {
        return VariableHandler.processVariables(in: self, with: provider)
    }

}

private extension VariableDataProvider {

    func value(for variableName: String) -> String {
        switch variableName {
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
