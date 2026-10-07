//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentLocalization.swift
//
//  Created by James Borthwick on 2024-09-03.
// swiftlint:disable missing_docs

import Foundation

@_spi(Internal) extension PaywallComponent.LocalizationDictionary {

    public func string(key: String) throws -> String {
        guard case let .string(value) = self[key] else {
            throw LocalizationValidationError.missingLocalization(
                "Missing string localization for property with id: \"\(key)\""
            )
        }
        return value
    }

    public func image(key: String) throws -> PaywallComponent.ThemeImageUrls {
        guard case let .image(value) = self[key] else {
            throw LocalizationValidationError.missingLocalization(
                "Missing image localization for property with id: \"\(key)\""
            )
        }
        return value
    }

    @_spi(Internal) public func url(key: String) throws -> URL {
        let string = try self.string(key: key)
        guard let url = URL(string: string) else {
            throw LocalizationValidationError.invalidUrl(
                "Invalid URL localization for property with id: \"\(key)\": \"\(string)\""
            )
        }
        return url
    }

}

@_spi(Internal) extension PaywallComponent.VideoLocalizationDictionary {

    public func video(key: String) throws -> PaywallComponent.ThemeVideoUrls {
        guard let value = self[key] else {
            throw LocalizationValidationError.missingLocalization(
                "Missing video localization for property with id: \"\(key)\""
            )
        }
        return value
    }

}

extension Dictionary where Key == PaywallComponent.LocaleID, Value == PaywallComponent.LocalizationDictionary {

    /// Mirrors how RevenueCatUI chooses the locale to display: the best match for `preferredLocales`,
    /// or `defaultLocale` if the paywall doesn't support any of them.
    func displayedLocale(preferredLocales: [Locale], defaultLocale: PaywallComponent.LocaleID) -> Locale {
        let defaultLocale = Locale(identifier: defaultLocale)
        let chosenLocale = Locale.selectPreferredLocale(
            from: self.keys.map(Locale.init(identifier:)),
            preferredLocales: preferredLocales
        ) ?? defaultLocale

        return self.findLocale(chosenLocale) != nil ? chosenLocale : defaultLocale
    }

}

enum LocalizationValidationError: Error {

    case missingLocalization(String)
    case invalidUrl(String)

}
