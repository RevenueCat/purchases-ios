//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PreferredLocaleTests.swift
//
//  Created by Josh Holtz on 3/11/25.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PreferredLocaleTests: TestCase {

    let simplifiedChineseLanguages = [
        "zh", "zh_CN", "zh_SG", "zh_MY"
    ]
    let traditionalChineseLanguages = [
        "zh_TW", "zh_HK", "zh_MO"
    ]

    func testSimplifiedLanguagesMapToHans() {
        for locale in simplifiedChineseLanguages {
            let preferredLanguages = [locale]
            let normalized = Locale.normalizedLocales(from: preferredLanguages)

            expect(normalized).to(equal([Locale(identifier: "zh-Hans")]))
        }
    }

    func testSimplifiedLanguagesMapToHant() {
        for locale in traditionalChineseLanguages {
            let preferredLanguages = [locale]
            let normalized = Locale.normalizedLocales(from: preferredLanguages)

            expect(normalized).to(equal([Locale(identifier: "zh-Hant")]))
        }
    }

}
