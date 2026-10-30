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

    private let bundlePreferredLocaleGetter: () -> String?

    /// Initializes the provider with an optional override for the preferred locale.
    /// - Parameters:
    ///   - preferredLocaleOverride: The preferred locale to override the system's preferred languages, if any.
    ///   - systemPreferredLocalesGetter: The closure to get the preferred locales, defaults to the system's preferred
    ///   languages.
    ///   - bundlePreferredLocaleGetter: The closure to get the app's preferred localization.
    init(
        preferredLocaleOverride: String?,
        systemPreferredLocalesGetter: @escaping () -> [String] = PreferredLocalesProvider.defaultPreferredLocalesGetter,
        bundlePreferredLocaleGetter: @escaping () -> String? = { Bundle.main.preferredLocalizations.first }
    ) {
        self.preferredLocaleOverride = preferredLocaleOverride
        self.systemPreferredLocalesGetter = systemPreferredLocalesGetter
        self.bundlePreferredLocaleGetter = bundlePreferredLocaleGetter
    }

    /// Returns the override, app localization, and system preferred languages, in that order of priority.
    var preferredLocales: [String] {
        return [self.preferredLocaleOverride, self.bundlePreferredLocaleGetter()].compactMap { $0 }
            + self.systemPreferredLocalesGetter()
    }

    /// Sets a new preferred locale override that will take precedence over the system's preferred languages.
    func overridePreferredLocale(_ locale: String?) {
        self.preferredLocaleOverride = locale
    }

}
