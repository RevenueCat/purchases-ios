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
    var localizedConfiguration: LocalizedConfiguration {
        return self.localizedConfiguration(for: Self.localesOrderedByPriority)
    }

    // Visible for testing
    internal func localizedConfiguration(for preferredLocales: [Locale]) -> LocalizedConfiguration {
        // Allows us to search each locale in order of priority, both with the region and without.
        // Example: [en_UK, es_ES] => [en_UK, en, es_ES, es]
        let locales: [Locale] = preferredLocales.flatMap { [$0, $0.removingRegion].compactMap { $0 } }

        Logger.verbose(Strings.paywalls.looking_up_localization(preferred: preferredLocales,
                                                                search: locales))

        let result: (locale: Locale, config: LocalizedConfiguration)? = locales
            .lazy
            .compactMap { locale in
                self.config(for: locale)
                    .map { (locale, $0) }
            }
            .first { _ in true } // See https://github.com/apple/swift/issues/55374

        if let result {
            Logger.verbose(Strings.paywalls.found_localization(result.locale))

            return result.config
        } else {
            let (locale, fallback) = self.fallbackLocalizedConfiguration

            Logger.warn(Strings.paywalls.fallback_localization(localeIdentifier: locale))

            return fallback
        }
    }

    // Visible for testing
    /// - Returns: The list of locales that paywalls should try to search for.
    /// Includes `Locale.current` and `Locale.preferredLanguages`.
    internal static var localesOrderedByPriority: [Locale] {
        return [.current] + Locale.preferredLocales
    }

    private var fallbackLocalizedConfiguration: (String, LocalizedConfiguration) {
        // This can't happen because `localization` has `@EnsureNonEmptyCollectionDecodable`.
        guard let result = self.localization.first else {
            fatalError("Corrupted data: localization is empty.")
        }

        return result
    }

}

// MARK: -

extension Locale {

    fileprivate static var preferredLocales: [Self] {
        return Self.preferredLanguages.map(Locale.init(identifier:))
    }

}
