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

    func findLocale(_ locale: Locale) -> Value? {
        let localeIdentifier = locale.identifier

        if let exactMatch = self.valueForLocaleString(localeIdentifier) {
            return exactMatch
        }

        // For matching unknown locales with full identifier
        // Ex: `zh_CN` will become `zh_Hans_CN`
        if let maxIdentifier = locale.rc_lanuageMaxIdentifier {
            if let exactMatch = self.valueForLocaleString(maxIdentifier) {
                return exactMatch
            }
        }

        // For matching language and script without region
        if let onlyLanguageAndScriptIdentifier = locale.rc_languageAndScript,
           let exactMatch = self.valueForLocaleString(onlyLanguageAndScriptIdentifier) {
            return exactMatch
        }

        // For matching language without script or region
        if let onlyLanguageIdentifier = locale.rc_languageCode,
           let exactMatch = self.valueForLocaleString(onlyLanguageIdentifier) {
            return exactMatch
        }

        return nil
    }

    private func valueForLocaleString(_ localeIdentifier: String) -> Value? {
        if let exactMatch = self[localeIdentifier] {
            return exactMatch
        }

        // For cases like zh-Hans and zh-Hant
        let underscoreLocaleIdentifier = localeIdentifier.replacingOccurrences(of: "-", with: "_")
        return self[underscoreLocaleIdentifier]
    }

}
