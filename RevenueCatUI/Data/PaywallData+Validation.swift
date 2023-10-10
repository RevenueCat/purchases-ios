//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallData+Validation.swift
//
//  Created by Nacho Soto on 8/15/23.

import Foundation

import RevenueCat

// MARK: - Errors

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering {

    typealias ValidationResult = (displayablePaywall: PaywallData,
                                  template: PaywallTemplate,
                                  error: Offering.PaywallValidationError?)

    enum PaywallValidationError: Swift.Error, Equatable {

        case missingPaywall
        case invalidTemplate(String)
        case invalidVariables(Set<String>)
        case invalidIcons(Set<String>)

    }

}

// MARK: - Offering validation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering {

    /// - Returns: a validated paywall suitable to be displayed, and any associated error.
    func validatedPaywall(locale: Locale = .current) -> ValidationResult {
        if let paywall = self.paywall {
            switch paywall.validate() {
            case let .success(template):
                return (paywall, template, nil)

            case let .failure(error):
                // If there are any errors, create a default paywall
                // with only the configured packages.
                return (.createDefault(with: paywall.config.packages, locale: locale),
                        PaywallData.defaultTemplate,
                        error)
            }
        } else {
            // If `Offering` has no paywall, create a default one with all available packages.
            return (displayablePaywall: .createDefault(with: self.availablePackages, locale: locale),
                    PaywallData.defaultTemplate,
                    error: .missingPaywall)
        }
    }

}

// MARK: - PaywallData validation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallData {

    typealias Error = Offering.PaywallValidationError

    /// - Returns: `nil` if there are no validation errors.
    func validate() -> Result<PaywallTemplate, Error> {
        if let error = Self.validateLocalization(self.localizedConfiguration) {
            return .failure(error)
        }

        guard let template = PaywallTemplate(rawValue: self.templateName) else {
            return .failure(.invalidTemplate(self.templateName))
        }

        let invalidIcons = self.localizedConfiguration.validateIcons()
        guard invalidIcons.isEmpty else {
            return .failure(.invalidIcons(invalidIcons))
        }

        return .success(template)
    }

    /// Validates that all strings inside of `LocalizedConfiguration` contain no unrecognized variables.
    private static func validateLocalization(_ localization: LocalizedConfiguration) -> Error? {
        let unrecognizedVariables = Set(
            localization
                .allValues
                .lazy
                .compactMap { $0.unrecognizedVariables() }
                .joined()
        )

        return unrecognizedVariables.isEmpty
        ? nil
        : .invalidVariables(unrecognizedVariables)
    }

}

private extension PaywallData.LocalizedConfiguration {

    /// - Returns: the set of invalid icons
    func validateIcons() -> Set<String> {
        return Set(self.features.compactMap { $0.validateIcon() })
    }

}

private extension PaywallData.LocalizedConfiguration.Feature {

    /// - Returns: the icon ID if it's not recognized
    func validateIcon() -> String? {
        guard let iconID = self.iconID else { return nil }

        return PaywallIcon(rawValue: iconID) == nil
            ? iconID
            : nil
    }

}

// MARK: - Errors

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering.PaywallValidationError: CustomStringConvertible {

    var description: String {
        switch self {
        case .missingPaywall:
            return "Offering has no configured paywall."

        case let .invalidTemplate(name):
            return "Template not recognized: \(name)."

        case let .invalidVariables(names):
            return "Found unrecognized variables: \(names.joined(separator: ", "))."

        case let .invalidIcons(names):
            return "Found unrecognized icons: \(names.joined(separator: ", "))."
        }
    }

}

// MARK: - PaywallLocalizedConfiguration

private extension PaywallLocalizedConfiguration {

    /// The set of properties inside a `PaywallLocalizedConfiguration`.
    static var allProperties: Set<KeyPath<Self, String?>> {
        return [
            \.optionalTitle,
             \.subtitle,
             \.optionalCallToAction,
             \.callToActionWithIntroOffer,
             \.offerDetails,
             \.offerDetailsWithIntroOffer,
             \.offerName
        ]
    }

    var allValues: [String] {
        return Self
            .allProperties
            .compactMap { self[keyPath: $0] }
        + self.features.flatMap {
            [$0.title, $0.content].compactMap { $0 }
        }
    }

}

private extension PaywallLocalizedConfiguration {

    var optionalTitle: String? { return self.title }
    var optionalCallToAction: String? { self.callToAction }

}
