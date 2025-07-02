//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PreferredLocalesProvider.swift
//
//  Created by Cesar de la Vega on 1/7/24.

import Foundation

final class PreferredLocalesProvider {

    private static let defaultPreferredLocalesGetter = {
        return Locale.preferredLanguages
    }

    /// Developer-set preferred locale that takes precedence over the system preferred locales.
    private(set) var preferredLocaleOverride: String?

    /// Closure to get the user's preferred locales, allowing for dependency injection in tests.
    private var systemPreferredLocalesGetter: () -> [String]

    /// Initializes the provider with an optional override for the preferred locale.
    /// - Parameters:
    ///   - preferredLocaleOverride: The preferred locale to override the system's preferred languages, if any.
    ///   - preferredLocalesGetter: The closure to get the preferred locales, defaults to the system's preferred
    ///   languages.
    init(
        preferredLocaleOverride: String?,
        systemPreferredLocalesGetter: @escaping () -> [String] = PreferredLocalesProvider.defaultPreferredLocalesGetter
    ) {
        self.preferredLocaleOverride = preferredLocaleOverride
        self.systemPreferredLocalesGetter = systemPreferredLocalesGetter
    }

    /// Returns the list of the user's preferred languages, including the preferred locale override as the first
    /// locale of the array.
    var preferredLocales: [String] {
        if let preferredLocaleOverride = self.preferredLocaleOverride {
            return [preferredLocaleOverride] + systemPreferredLocalesGetter()
        } else {
            return systemPreferredLocalesGetter()
        }
    }

    /// Sets a new preferred locale override that will take precedence over the system's preferred languages.
    func overridePreferredLocale(_ locale: String?) {
        self.preferredLocaleOverride = locale
    }

}
