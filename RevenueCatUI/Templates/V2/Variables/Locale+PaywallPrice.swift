//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Locale+PaywallPrice.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

extension Locale {

    /// The locale for prices and other numbers on a paywall: the paywall's language with the storefront country,
    /// so prices computed per period match the price coming from the store. Mirrors Android's `currencyLocale`.
    static func paywallPriceLocale(
        paywallLocale: Locale,
        storefrontCountryCode: String?,
        availableIdentifiers: [String] = Locale.availableIdentifiers
    ) -> Locale {
        return Self.storefrontPriceLocale(
            paywallLocale: paywallLocale,
            storefrontCountryCode: storefrontCountryCode,
            availableIdentifiers: availableIdentifiers
        )
    }

    /// The available locales for the storefront country keyed by language.
    /// POSIX locales are excluded because their currency format can contain spacing that differs from the store format.
    static func storefrontLocalesByLanguage(
        storefrontCountryCode: String?,
        availableIdentifiers: [String] = Locale.availableIdentifiers
    ) -> [String: Locale] {
        guard let region = Self.regionCode(fromStorefrontCountryCode: storefrontCountryCode) else {
            return [:]
        }

        var localesByLanguage: [String: Locale] = [:]
        for identifier in availableIdentifiers.sorted() {
            let components = NSLocale.components(fromLocaleIdentifier: identifier)
            guard components[NSLocale.Key.countryCode.rawValue]?.uppercased() == region,
                  components[NSLocale.Key.variantCode.rawValue]?.uppercased() != "POSIX",
                  let language = components[NSLocale.Key.languageCode.rawValue]?.lowercased() else {
                continue
            }
            localesByLanguage[language] = Locale(identifier: identifier)
        }
        return localesByLanguage
    }

}

private extension Locale {

    static func storefrontPriceLocale(
        paywallLocale: Locale,
        storefrontCountryCode: String?,
        availableIdentifiers: [String]
    ) -> Locale {
        guard let region = Self.regionCode(fromStorefrontCountryCode: storefrontCountryCode) else {
            return paywallLocale
        }

        var components = NSLocale.components(fromLocaleIdentifier: paywallLocale.identifier)
        components[NSLocale.Key.countryCode.rawValue] = region
        let scriptKey = NSLocale.Key.scriptCode.rawValue
        // Foundation also recognizes region-based script preferences, such as zh_TW for Traditional Chinese.
        let languageID = NSLocale.canonicalLanguageIdentifier(from: paywallLocale.identifier)
        if let script = components[scriptKey] ?? NSLocale.components(fromLocaleIdentifier: languageID)[scriptKey] {
            components[scriptKey] = script
            return Locale(identifier: Locale.identifier(fromComponents: components))
        }

        let fallbackLocale = Locale(identifier: Locale.identifier(fromComponents: components))
        let storefrontLocales = Self.storefrontLocalesByLanguage(
            storefrontCountryCode: region,
            availableIdentifiers: availableIdentifiers
        )

        // Use a storefront locale with the same number format when possible, preserving its currency
        // symbol (for example, ¥ in Japan). Otherwise, keep the paywall language's number format.
        if let language = paywallLocale.rc_languageCode?.lowercased(),
           let locale = storefrontLocales[language] {
            // A language-only match can select an arbitrary script when the storefront lists several.
            return (locale as NSLocale).object(forKey: .scriptCode) == nil ? locale : fallbackLocale
        }

        return storefrontLocales.values
            .sorted { $0.identifier < $1.identifier }
            .first { $0.hasSameNumberFormat(as: fallbackLocale) }
            ?? fallbackLocale
    }

    /// The App Store uses ISO 3166-1 alpha-3 codes (`SAU`). ICU maps them to alpha-2 (`SA`), and keeps alpha-2 codes.
    static func regionCode(fromStorefrontCountryCode storefrontCountryCode: String?) -> String? {
        guard let storefrontCountryCode = storefrontCountryCode?.trimmingCharacters(in: .whitespaces),
              !storefrontCountryCode.isEmpty else {
            return nil
        }

        let components = NSLocale.components(fromLocaleIdentifier: "und_\(storefrontCountryCode)")
        return components[NSLocale.Key.countryCode.rawValue]?.uppercased()
    }

    func hasSameNumberFormat(as other: Locale) -> Bool {
        return self.formattedNumberSample == other.formattedNumberSample
    }

    var formattedNumberSample: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = self
        return formatter.string(from: 1_234_567.89)
    }

}

#endif
