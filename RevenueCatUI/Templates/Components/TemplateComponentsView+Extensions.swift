//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateComponentsView+extensions.swift
//
//  Created by James Borthwick on 2024-09-03.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateComponentsView {

    static func fallbackPaywallViewModels(error: Error? = nil) -> PaywallComponentViewModel {

        let errorDict: PaywallComponent.LocalizationDictionary = ["errorID": .string("Error creating paywall")]
        let textComponent = PaywallComponent.TextComponent(
            text: "errorID",
            color: PaywallComponent.ColorScheme(light: .hex("#000000"))
        )

        // swiftlint:disable:next force_try
        return try! PaywallComponentViewModel.text(
            TextComponentViewModel(localizedStrings: errorDict, component: textComponent)
        )

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

extension Locale {

    fileprivate static var preferredLocales: [Self] {
        return Self.preferredLanguages.map(Locale.init(identifier:))
    }

    fileprivate func matchesLanguage(_ rhs: Locale) -> Bool {
        self.removingRegion == rhs.removingRegion
    }

    // swiftlint:disable:next identifier_name
    private var rc_languageCode: String? {
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

    /// - Returns: the same locale as `self` but removing its region.
    private var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

}
#endif
