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
    private let preferApplicationLocale: Atomic<Bool> = false

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

    /// Returns the override, the app localization when enabled, and system preferred languages, in that order.
    var preferredLocales: [String] {
        let systemLocales = self.systemPreferredLocalesGetter()
        let localeOverride = self.preferredLocaleOverride.map { [$0] } ?? []
        guard self.preferApplicationLocale.value,
              let appLocaleIdentifier = self.bundlePreferredLocaleGetter() else {
            return localeOverride + systemLocales
        }

        let appLocale = Locale(identifier: appLocaleIdentifier)
        let matchingSystemLocale: String?
        // Refine language-only localizations without overriding an app's explicit region or script.
        if appLocale.identifier == appLocale.rc_languageCode {
            matchingSystemLocale = systemLocales.first {
                Locale(identifier: $0).rc_languageCode == appLocale.rc_languageCode
            }
        } else {
            matchingSystemLocale = nil
        }

        return (localeOverride + [matchingSystemLocale, appLocaleIdentifier].compactMap { $0 } + systemLocales)
            .deduplicated()
    }

    func setPreferApplicationLocale(_ enabled: Bool) {
        self.preferApplicationLocale.value = enabled
    }

    /// Sets a new preferred locale override that will take precedence over the system's preferred languages.
    func overridePreferredLocale(_ locale: String?) {
        self.preferredLocaleOverride = locale
    }

}
