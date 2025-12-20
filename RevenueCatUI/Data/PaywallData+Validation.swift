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
                                  displayedLocale: Locale,
                                  template: PaywallTemplate,
                                  error: Offering.PaywallValidationError?)

    /// Errors that can occur during paywall validation.
    ///
    /// When validation fails, the paywall falls back to a default Template 2 layout
    /// using the offering's available packages. In debug builds, a red error banner
    /// is displayed; in production, the fallback renders silently.
    enum PaywallValidationError: Swift.Error, Equatable {

        /// The offering has no configured paywall (`offering.paywall == nil`).
        ///
        /// This typically means no paywall was set up in the RevenueCat dashboard,
        /// or a v2 paywall exists but hasn't been published yet.
        case missingPaywall(Offering)

        /// The paywall has no localization data.
        ///
        /// For single-tier paywalls: `localizedConfiguration` is nil.
        /// For multi-tier paywalls: `localizedConfigurationByTier` is nil.
        case missingLocalization

        /// A multi-tier paywall has an empty `config.tiers` array.
        ///
        /// Multi-tier templates require at least one tier to be configured.
        case missingTiers

        /// A tier ID exists in the paywall config but has no corresponding localization entry.
        ///
        /// The tier was configured but `localizedConfigurationByTier[tier.id]` returns nil.
        case missingTier(PaywallData.Tier)

        /// A tier has localization data but its `tierName` is nil or empty.
        ///
        /// Tier names are required for the tier selection UI (e.g., "Basic", "Premium").
        case missingTierName(PaywallData.Tier)

        /// The `templateName` doesn't match any known `PaywallTemplate` enum case.
        ///
        /// This can happen if a newer template is used with an older SDK version.
        case invalidTemplate(String)

        /// Localization strings contain unrecognized template variables.
        ///
        /// Valid variables include: `app_name`, `price`, `total_price_and_per_month`,
        /// `sub_price_per_month`, `sub_duration`, `sub_offer_price`, etc.
        /// Unrecognized variables would render as raw `{{ variable }}` text.
        case invalidVariables(Set<String>)

        /// Feature items reference icon IDs that don't exist in the `PaywallIcon` enum.
        ///
        /// Check `PaywallIcon` for the list of valid icon identifiers.
        case invalidIcons(Set<String>)

    }

}

// MARK: - Offering validation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Offering {

    /// - Returns: a validated paywall suitable to be displayed, and any associated error.
    func validatedPaywall(locale: Locale) -> ValidationResult {
        if let paywall = self.paywall {
            switch paywall.validate() {
            case let .success(template):
                return (paywall, paywall.locale ?? locale, template, nil)

            case let .failure(error):
                let paywall: PaywallData = paywall.config.packages.isEmpty
                    ? .createDefault(with: self.availablePackages, locale: locale)
                    : .createDefault(with: paywall.config.packages, locale: locale)

                return (displayablePaywall: paywall,
                        displayedLocale: locale,
                        template: PaywallData.defaultTemplate,
                        error: error)
            }
        } else {
            // If `Offering` has no paywall, create a default one with all available packages.
            return (displayablePaywall: .createDefault(with: self.availablePackages, locale: locale),
                    displayedLocale: locale,
                    template: PaywallData.defaultTemplate,
                    error: .missingPaywall(self))
        }
    }
}

// MARK: - PaywallData validation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallData {

    typealias Error = Offering.PaywallValidationError

    /// - Returns: `nil` if there are no validation errors.
    func validate() -> Result<PaywallTemplate, Error> {
        guard let template = PaywallTemplate(rawValue: self.templateName) else {
            return .failure(.invalidTemplate(self.templateName))
        }

        switch template.packageSetting.tierSetting {
        case .single:
            if let error = self.validateSingleTier() {
                return .failure(error)
            }

        case .multiple:
            if let error = self.validateMultiTier() {
                return .failure(error)
            }
        }

        return .success(template)
    }

    private func validateSingleTier() -> Error? {
        guard let localization = self.localizedConfiguration else {
            return .missingLocalization
        }

        if let error = Self.validateLocalization(localization) {
            return error
        }

        return nil
    }

    private func validateMultiTier() -> Error? {
        guard let localized = self.localizedConfigurationByTier else {
            return .missingLocalization
        }

        if self.config.tiers.isEmpty {
            return .missingTiers
        }

        for tier in self.config.tiers {
            guard let localization = localized[tier.id] else {
                return .missingTier(tier)
            }

            if localization.tierName?.isEmpty != false {
                return .missingTierName(tier)
            }

            if let error = Self.validateLocalization(localization) {
                return error
            }
        }

        return nil
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

        guard unrecognizedVariables.isEmpty else {
            return .invalidVariables(unrecognizedVariables)
        }

        let invalidIcons = localization.validateIcons()
        guard invalidIcons.isEmpty else {
            return .invalidIcons(invalidIcons)
        }

        return nil
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
        case let .missingPaywall(offering):
            return "Offering '\(offering.identifier)' has no configured paywall. If you expected to see a v2 Paywall," +
            " make sure it is published."

        case .missingLocalization:
            return "Paywall has no localization."

        case .missingTiers:
            return "Multi-tier paywall has no configured tiers."

        case let .missingTier(tier):
            return "Tier '\(tier.id)' is missing in localization."

        case let .missingTierName(tier):
            return "Tier '\(tier.id)' has no name."

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
