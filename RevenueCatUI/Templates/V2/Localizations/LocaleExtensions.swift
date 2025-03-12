//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocaleExtensions.swift
//
//  Created by Josh Holtz on 2/7/25.

import Foundation

extension Locale {

    static var preferredLocales: [Self] {
        return Self.normalizedLocales(from: Self.preferredLanguages)
    }

    static func normalizedLocales(from preferredLanguages: [String]) -> [Self] {
        return preferredLanguages
            .map(Locale.normalizedLocaleIdentifier)
            .map(Locale.init(identifier:))
    }

    static func normalizedLocaleIdentifier(_ identifier: String) -> String {
        if let normalizedZH = Self.mapZHToHansOrHant(identifier) {
            return normalizedZH
        }

        return identifier
    }

    // Mapping other Chinese language codes to either simplified or traditional as
    // those are the Chinese identifier that we support
    static func mapZHToHansOrHant(_ identifier: String) -> String? {
        let underscoreLocaleIdentifier = identifier.replacingOccurrences(of: "-", with: "_")

        let hansLocales: Set<String> = [
            "zh", "zh_CN", "zh_SG", "zh_MY"
        ]
        let hantLocales: Set<String> = [
            "zh_TW", "zh_HK", "zh_MO"
        ]

        if hansLocales.contains(underscoreLocaleIdentifier) {
            return "zh_Hans"
        } else if hantLocales.contains(underscoreLocaleIdentifier) {
            return "zh_Hant"
        } else {
            return nil
        }
    }

    func matchesLanguage(_ rhs: Locale) -> Bool {
        self.removingRegion == rhs.removingRegion
    }

    // swiftlint:disable:next identifier_name
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

    /// - Returns: the same locale as `self` but removing its region.
    private var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

}
