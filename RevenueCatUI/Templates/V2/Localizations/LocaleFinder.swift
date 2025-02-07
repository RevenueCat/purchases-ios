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

        if let exactMatch = self[localeIdentifier] {
            return exactMatch
        }

        // For zh-Hans and zh-Hant
        let underscoreUocaleIdentifier = localeIdentifier.replacingOccurrences(of: "-", with: "_")
        if let exactMatch = self[underscoreUocaleIdentifier] {
            return exactMatch
        }

        return nil
    }

}
