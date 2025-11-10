//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Locale+Comparison.swift
//
//  Created by Jacob Zivan Rakidzich on 11/7/25.

import Foundation

extension Locale {

    func sharesLanguageCode(with other: Locale, strictMatching: Bool = true) -> Bool {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            if self.language.isEquivalent(to: other.language) {
                return true
            } else {
                if strictMatching { return false }
            }
        }

        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.language.languageCode == other.language.languageCode
        } else {
            return self.languageCode == other.languageCode
        }
    }
}
