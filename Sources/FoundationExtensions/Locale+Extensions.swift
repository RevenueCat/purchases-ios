//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Locale+Extensions.swift
//
//  Created by Nacho Soto on 6/21/23.

import Foundation

@_spi(Internal)
public extension Locale {

    /// Returns true if the language component of the Locale is equal to the one of self
    func matchesLanguage(_ rhs: Locale) -> Bool {
        self.removingRegion == rhs.removingRegion
    }

    // swiftlint:disable identifier_name
    /// The code of the currency used by the locale.
    var rc_currencyCode: String? {
        #if swift(>=5.9)
        // `Locale.currencyCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.currency?.identifier
        } else {
            return self.currencyCode
        }
        #else
        return self.currencyCode
        #endif
    }

    /// The language code that identifies the locale's language.
    var rc_languageCode: String? {
        #if swift(>=5.9)
        // `Locale.languageCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.languageCode?.identifier
        } else {
            return self.languageCode
        }
        #else
        return self.languageCode
        #endif
    }
    // swiftlint:enable identifier_name

    /// - Returns: the same locale as `self` but removing its region.
    var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

    /// Selects the best-matching locale from `availableLocales` given `preferredLocales`.
    ///
    /// Matches on language first, then picks the closest region/script within language matches.
    /// Returns `nil` if no language match exists for any preferred locale.
    static func selectPreferredLocale(from availableLocales: [Locale],
                                      preferredLocales: [Locale]) -> Locale? {
        for preferred in preferredLocales {
            let languageMatches = availableLocales
                .filter { $0.rc_languageCode == preferred.rc_languageCode }
                .sorted { $0.identifier < $1.identifier }
            guard let firstMatch = languageMatches.first else { continue }

            let bestIdentifier = Bundle.preferredLocalizations(
                from: languageMatches.map(\.identifier),
                forPreferences: [preferred.identifier]
            ).first
            return languageMatches.first { $0.identifier == bestIdentifier } ?? firstMatch
        }
        return nil
    }

}

@_spi(Internal)
public extension Dictionary where Key == String {

    /// Finds the best matching value for the provided locale with the restriction that the key
    /// must match the language of the provided locale.
    func findLocale(_ locale: Locale) -> Value? {
        let preferredIdentifiers = Self.preferredMatchedLocalesIdentifiers(from: Array(self.keys),
                                                                           preferredLanguage: locale.identifier)

        for localeIdentifier in preferredIdentifiers {
            if let value = self[localeIdentifier] {
                return value
            }
        }

        return nil
    }

    /// Returns the languages in `identifiers` that share the same language code as `preferredLanguage`
    /// and that best match `preferredLanguage`, sorted by match quality.
    ///
    /// Note: This method does not guarantee that all `identifiers` will be returned, only the best matches.
    static func preferredMatchedLocalesIdentifiers(from identifiers: [String],
                                                   preferredLanguage: String) -> [String] {

        let preferredLocale = Locale(identifier: preferredLanguage)
        let identifiersCandidates = identifiers.filter {
            Locale(identifier: $0).matchesLanguage(preferredLocale)
        }

        guard !identifiersCandidates.isEmpty else {
            return []
        }

        // As specified in the documentation of `Bundle.preferredLocalizations(from:forPreferences:)`
        // "_This method doesn’t return all localizations in order of user preference. To get this information,
        // you can call this method repeatedly, each time removing the identifiers returned by the previous call._"
        // This means that not all matches will be returned, but only the best ones based on `preferredLanguage`.
        let identifiers = Bundle.preferredLocalizations(from: identifiersCandidates,
                                                        forPreferences: [preferredLanguage])
        return identifiers
    }

}
