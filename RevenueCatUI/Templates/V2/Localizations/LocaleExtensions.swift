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
        return Self.preferredLanguages.map(Locale.init(identifier:))
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

    // swiftlint:disable:next identifier_name
    var rc_languageScript: String? {
        #if swift(>=5.9)
        // `Locale.languageCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.script?.identifier
        } else {
            return self.scriptCode ?? self.fallbackScriptForiOS15
        }
        #else
        return self.scriptCode ?? self.fallbackScriptForiOS15
        #endif
    }

    // swiftlint:disable:next identifier_name
    var rc_languageRegion: String? {
        #if swift(>=5.9)
        // `Locale.languageCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.region?.identifier
        } else {
            return self.regionCode
        }
        #else
        return self.regionCode
        #endif
    }

    // swiftlint:disable:next identifier_name
    var rc_lanuageMaxIdentifier: String? {
        #if swift(>=5.9)
        // `Locale.languageCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.maximalIdentifier
        } else {
            return [
                self.rc_languageCode,
                self.rc_languageScript,
                self.rc_languageRegion
            ].compactMap { $0 }.joined(separator: "-")
        }
        #else
        return [
            self.rc_languageCode,
            self.rc_languageScript,
            self.rc_languageRegion
        ].compactMap { $0 }.joined(separator: "-")
        #endif
    }

    // swiftlint:disable:next identifier_name
    var rc_languageAndScript: String? {
        return [
            self.rc_languageCode,
            self.rc_languageScript
        ].compactMap { $0 }.joined(separator: "-")
    }

    /// - Returns: the same locale as `self` but removing its region.
    private var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

    /// iOS 15 returns a nil scriptCode for these locale identifiers so hardcoding fallbacks
    private var fallbackScriptForiOS15: String? {
        let map: [String: String] = [
            "zh_CN": "Hans",
            "zh_SG": "Hans",
            "zh_MY": "Hans",
            "zh_TW": "Hant",
            "zh_HK": "Hant",
            "zh_MO": "Hant"
        ]

        return map[self.identifier]
    }

}
