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

    /// Determine whether or not a Locale matches another
    /// - Parameters:
    ///   - other: Another Locale
    ///   - stricterMatching: When false, the function will generally just check the language family code,
    ///   for ios 15 or lower passing in true will ensure that the language code and the language details are both
    ///   considered after normalizing the data ignoring case & certain special characters
    /// - Returns: True or False
    func sharesLanguageCode(with other: Locale, stricterMatching: Bool = true) -> Bool {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            if self.language.isEquivalent(to: other.language) {
                return true
            } else {
                if stricterMatching { return false }
            }
        }

        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.language.languageCode == other.language.languageCode
        } else {
            if stricterMatching {
                return normalizedIdentifier == other.normalizedIdentifier
            }
            return self.languageCode?.lowercased() == other.languageCode?.lowercased()
        }
    }

    private var normalizedIdentifier: String {
        identifier
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .lowercased()
    }
}
