//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallData+Localization.swift
//
//  Created by Nacho Soto on 8/10/23.

import Foundation

public extension PaywallData {

    /// - Returns: the ``PaywallData/LocalizedConfiguration-swift.struct``  to be used
    /// based on `Locale.current` or `Locale.preferredLocales`.
    /// -  Returns: `nil` for multi-tier paywalls.
    var localizedConfiguration: LocalizedConfiguration? {
        return self.localizedConfiguration(for: Self.localesOrderedByPriority)
    }

    /// - Returns: the ``PaywallData/LocalizedConfiguration-swift.struct``  to be used
    /// based on `Locale.current` or `Locale.preferredLocales`.
    /// -  Returns: `[:]` for single-tier paywalls.
    var localizedConfigurationByTier: [String: LocalizedConfiguration]? {
        return self.localizedConfigurationByTier(for: Self.localesOrderedByPriority)
    }

    // Visible for testing
    internal func localizedConfiguration(for preferredLocales: [Locale]) -> LocalizedConfiguration? {
        return Self.localizedConfiguration(
            for: preferredLocales,
            configForLocale: self.config(for:),
            fallbackLocalization: self.fallbackLocalizedConfiguration
        )
    }

    // Visible for testing
    internal func localizedConfigurationByTier(for preferredLocales: [Locale]) -> [String: LocalizedConfiguration]? {
        return Self.localizedConfiguration(
            for: preferredLocales,
            configForLocale: self.tiersLocalization(for:),
            fallbackLocalization: self.fallbackTiersLocalized
        )
    }

    // Visible for testing
    /// - Returns: The list of locales that paywalls should try to search for.
    /// Includes `Locale.current` and `Locale.preferredLanguages`.
    internal static var localesOrderedByPriority: [Locale] {
        return [.current] + Locale.preferredLocales
    }

    private var fallbackLocalizedConfiguration: (String, LocalizedConfiguration)? {
        return self.localization.first
    }

    private var fallbackTiersLocalized: (String, [String: LocalizedConfiguration])? {
        return self.localizationByTier.first
    }

}

// MARK: -

private extension PaywallData {

    static func localizedConfiguration<Value>(
        for preferredLocales: [Locale],
        configForLocale: @escaping (Locale) -> Value?,
        fallbackLocalization: (locale: String, value: Value)?
    ) -> Value? {
        guard let (fallbackLocale, fallbackLocalization) = fallbackLocalization else {
            Logger.debug(Strings.paywalls.empty_localization)
            return nil
        }

        // Allows us to search each locale in order of priority, both with the region and without.
        // Example: [en_UK, es_ES] => [en_UK, en, es_ES, es]
        let locales: [Locale] = preferredLocales.flatMap { [$0, $0.removingRegion].compactMap { $0 } }

        Logger.verbose(Strings.paywalls.looking_up_localization(preferred: preferredLocales,
                                                                search: locales))

        let result: (locale: Locale, value: Value)? = locales
            .lazy
            .compactMap { locale in
                configForLocale(locale)
                    .map { (locale, $0) }
            }
            .first { _ in true } // See https://github.com/apple/swift/issues/55374

        if let result {
            Logger.verbose(Strings.paywalls.found_localization(result.locale))

            return result.value
        } else {
            Logger.warn(Strings.paywalls.fallback_localization(localeIdentifier: fallbackLocale))

            return fallbackLocalization
        }
    }

}

// MARK: -

extension Locale {

    fileprivate static var preferredLocales: [Self] {
        return Self.preferredLanguages.map(Locale.init(identifier:))
    }

}
