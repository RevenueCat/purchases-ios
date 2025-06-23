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

extension Dictionary where Key == String {

    /// Finds the best matching value for the provided locale with the restriction that the key
    /// must match the language of the provided locale.
    func findLocale(_ locale: Locale) -> Value? {
        let preferredIdentifiers = Self.preferredMatchedLocalesIdentifiers(from: Array(self.keys),
                                                                           preferredLanguages: [locale.identifier])

        for localeIdentifier in preferredIdentifiers {
            if let value = self[localeIdentifier] {
                return value
            }
        }

        return nil
    }

    /// Returns the elements in `identifiers` that best match the any language in `preferredLanguages`
    /// (i.e. same language code), sorted by best match.
    ///
    /// This method takes into account the order of `preferredLanguages` to determine the best match.
    /// E.g.
    /// if `preferredLanguages` is `["en-US", "es-ES"]`, then the identifier `en-GB`
    /// will be preferred over `es-ES`.
    ///
    /// - important: As specified in the documentation of `Bundle.preferredLocalizations(from:forPreferences:)`
    /// "_This method doesn’t return all localizations in order of user preference. To get this information,
    /// you can call this method repeatedly, each time removing the identifiers returned by the previous call._"
    /// This means that not all matches will be returned, but only the best ones based on `preferredLanguages`.
    static func preferredMatchedLocalesIdentifiers(from identifiers: [String],
                                                   preferredLanguages: [String]) -> [String] {

        let preferredLocales = preferredLanguages.map(Locale.init)
        let identifiersCandidates = identifiers.filter { identifier in
            let locale = Locale(identifier: identifier)
            return preferredLocales.contains { $0.matchesLanguage(locale) }
        }

        guard !identifiersCandidates.isEmpty else {
            return []
        }

        let identifiers = Bundle.preferredLocalizations(from: identifiersCandidates,
                                                        forPreferences: preferredLanguages)
        return identifiers
    }

}
