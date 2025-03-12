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

        // For matching unknown locales with language code and script
        // Ex: `zh_CN` will is `zh` and `Hans` and `zh_HK` will be `zh-Hant`
        if let languageCode = locale.rc_languageCode, let languageScript = locale.rc_languageScript {
            let codeAndScriptIdentifier = "\(languageCode)_\(languageScript)"
            if let exactMatch = self.valueForLocaleString(codeAndScriptIdentifier) {
                return exactMatch
            }
        }

        // For matching language without region
        if let noRegionLocaleIdentifier = locale.rc_languageCode,
           let exactMatch = self.valueForLocaleString(noRegionLocaleIdentifier) {
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
