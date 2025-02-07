//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocaleFinderTests.swift
//
//  Created by Josh Holtz on 2/6/25.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class LocaleFinderTest: TestCase {

    static let expectedTranslations = ["expected": "translations"]
    static let wrongTranslations = ["wrong": "translations"]

    func test_en_US() {
        let localizations = [
            "en_US": Self.expectedTranslations,
            "es_ES": Self.wrongTranslations
        ]

        let locale = Locale(identifier: "en_US")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_zh_Hans() {
        let localizations = [
            "zh_Hans": Self.expectedTranslations,
            "es_ES": Self.wrongTranslations
        ]

        let locale = Locale(identifier: "zh-Hans")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

}
