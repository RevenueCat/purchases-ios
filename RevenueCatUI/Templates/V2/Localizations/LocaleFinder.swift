//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocaleFinder.swift
//
//  Created by Josh Holtz on 2/6/25.

import Foundation
@_spi(Internal) import RevenueCat

extension Dictionary where Key == String {

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
