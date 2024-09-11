//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizationProvider.swift
//
//  Created by Josh Holtz on 9/10/24.
// swiftlint:disable missing_docs todo

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

struct LocalizationProvider {

    struct LocalizationInfo {
        let locale: Locale
        let localizedStrings: PaywallComponent.LocalizationDictionary
    }

    let preferred: LocalizationInfo
    let `default`: LocalizationInfo

    init(preferred: LocalizationInfo, `default`: LocalizationInfo) {
        self.preferred = preferred
        self.default = `default`
    }

    static func chooseLocalization(for componentsData: PaywallComponentsData) throws -> LocalizationProvider {

        guard !componentsData.componentsLocalizations.isEmpty else {
            Logger.error(Strings.paywall_contains_no_localization_data)
            throw LocalizationValidationError.noLocalizations
        }

        let defaultLocale = Locale(identifier: componentsData.defaultLocale)
        guard let localizedStrings = componentsData.componentsLocalizations[defaultLocale.identifier] else {
            throw LocalizationValidationError.noDefaultLocalization
        }

        let defaultLocalizationInfo = LocalizationInfo.init(
            locale: defaultLocale,
            localizedStrings: localizedStrings
        )

        // STEP 1: Get available paywall locales
        let paywallLocales = componentsData.componentsLocalizations.keys.map { Locale(identifier: $0) }

        // use default locale as a fallback if none of the user's preferred locales are not available in the paywall


        // STEP 2: choose best locale based on device's list of preferred locales.
        let chosenLocale = Self.preferredLocale(from: paywallLocales) ?? defaultLocale

        // STEP 3: Get localization for one of preferred locales in order
        if let localizedStrings = componentsData.componentsLocalizations[chosenLocale.identifier] {
            return .init(
                preferred: .init(locale: chosenLocale,
                                 localizedStrings: localizedStrings),
                default: defaultLocalizationInfo
            )
        } else {
            Logger.error(Strings.paywall_could_not_find_localization("\(chosenLocale) or \(defaultLocale)"))
            return .init(
                preferred: defaultLocalizationInfo,
                default: defaultLocalizationInfo
            )
        }
    }

    /// Returns the preferred paywall locale from the device's preferred locales.
    ///
    /// The algorithm matches first on language, then on region. If no matching locale is found,
    /// the function returns `nil`.
    ///
    /// - Parameter paywallLocales: An array of `Locale` objects representing the paywall's available locales.
    /// - Returns: A `Locale` available on the paywall chosen based on the device's preferredlocales,
    /// or `nil` if no match is found.
    ///
    /// # Example 1
    ///   device locales: `en_CA, en_US, fr_CA`
    ///   paywall locales: `en_US, fr_FR, en_CA, de_DE`
    ///   returns `en_CA`
    ///
    ///
    /// # Example 2
    ///   device locales: `en_CA, en_US, fr_CA`
    ///   paywall locales: `en_US, fr_FR, de_DE`
    ///   returns `en_US`
    ///
    /// # Example 3
    ///   device locales: `fr_CA, en_CA, en_US`
    ///   paywall locales: `en_US, fr_FR, de_DE, en_CA`
    ///   returns `fr_FR`
    ///
    /// # Example 4
    ///   device locales: `es_ES`
    ///   paywall locales: `en_US, de_DE`
    ///   returns `nil`
    ///
    static func preferredLocale(from paywallLocales: [Locale]) -> Locale? {
        for preferredLocale in Locale.preferredLocales {
            // match language
            if let languageMatch = paywallLocales.first(where: { $0.matchesLanguage(preferredLocale) }) {
                // Look for a match that includes region
                if let exactMatch = paywallLocales.first(where: { $0 == preferredLocale }) {
                    return exactMatch
                }
                // If no region match, return match that matched on region only
                return languageMatch
            }
        }

        return nil
    }

}

extension LocalizationProvider {

    enum LocalizationValidationError: Error {

        case noLocalizations
        case noDefaultLocalization
        case missingLocalization(String)
        case invalidUrl(String)

    }

}

extension LocalizationProvider {

    public func string(key: String) throws -> String {
        guard case let .string(value) = preferred.localizedStrings[key] else {
            throw LocalizationValidationError.missingLocalization(
                "Missing string localization for property with id: \"\(key)\""
            )
        }
        return value
    }

    public func image(key: String) throws -> PaywallComponent.ThemeImageUrls {
        let rawValue = preferred.localizedStrings[key] ?? `default`.localizedStrings[key]

        guard case let .image(value) = rawValue else {
            throw LocalizationValidationError.missingLocalization(
                "Missing image localization for property with id: \"\(key)\""
            )
        }
        return value
    }

}

#endif
