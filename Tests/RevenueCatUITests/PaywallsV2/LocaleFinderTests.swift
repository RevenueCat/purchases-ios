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

    static let simplifiedChineseLanguages = [
        "zh_CN", "zh_SG", "zh_MY"
    ]
    static let traditionalChineseLanguages = [
        "zh_TW", "zh_HK", "zh_MO"
    ]

    func test_en_US() {
        let localizations = [
            "en_US": Self.expectedTranslations,
            "es_ES": ["wrong": "this is es_ES"]
        ]

        let locale = Locale(identifier: "en_US")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_zh_Hans() {
        let localizations = [
            "zh_Hans": Self.expectedTranslations,
            "es_ES": ["wrong": "this is es_ES"]
        ]

        let locale = Locale(identifier: "zh-Hans")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_es_MX() {
        let localizations = [
            "zh_Hans": ["wrong": "this is zh_Hans"],
            "es": Self.expectedTranslations,
            "es_ES": ["wrong": "this is es_ES"]
        ]

        let locale = Locale(identifier: "es_MX")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func testSimplifiedChineseForLanguageAndScript() {
        let localizations = [
            "zh_Hans": Self.expectedTranslations,
            "zh_Hant": ["wrong": "this is zh_Hant"]
        ]

        for languageCode in Self.simplifiedChineseLanguages {
            let locale = Locale(identifier: languageCode)

            let foundLocalizations = localizations.findLocale(locale)
            expect(foundLocalizations).to(equal(Self.expectedTranslations))
        }
    }

    func testTraditionalChineseForLanguageAndScript() {
        let localizations = [
            "zh_Hans": ["wrong": "this is zh_Hans"],
            "zh_Hant": Self.expectedTranslations
        ]

        for languageCode in Self.traditionalChineseLanguages {
            let locale = Locale(identifier: languageCode)

            let foundLocalizations = localizations.findLocale(locale)
            expect(foundLocalizations).to(equal(Self.expectedTranslations))
        }
    }

    func test_zh_CN_UsingMaxIdentifier() {
        let localizations = [
            "zh_Hans_CN": Self.expectedTranslations,
            "zh_Hans": ["wrong": "this is zh_Hans"],
            "zh": ["wrong": "this is zh"]
        ]

        let locale = Locale(identifier: "zh_CN")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_zh_HK_UsingMaxIdentifier() {
        let localizations = [
            "zh_Hant_HK": Self.expectedTranslations,
            "zh_Hant": ["wrong": "this is zh_Hant"],
            "zh": ["wrong": "this is zh"]
        ]

        let locale = Locale(identifier: "zh_HK")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_zh_TW_UsingMaxIdentifier() {
        let localizations = [
            "zh_Hant_TW": Self.expectedTranslations,
            "zh_Hant": ["wrong": "this is zh_Hant"],
            "zh": ["wrong": "this is zh"]
        ]

        let locale = Locale(identifier: "zh_TW")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_es_MX_Matches_es_419() {
        let localizations = [
            "es_419": Self.expectedTranslations,
            "es_CO": ["wrong": "this is es_CO"],
            "es": ["wrong": "this is es"]
        ]

        let locale = Locale(identifier: "es_MX")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_es_MX_Matches_es_before_es_ES() {
        let localizations = [
            "en": ["wrong": "this is en"],
            "es_ES": ["wrong": "this is es_ES"],
            "es": Self.expectedTranslations
        ]

        let locale = Locale(identifier: "es_MX")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_es_MX_Matches_es_ES_if_that_is_the_only_es_language() {
        let localizations = [
            "en": ["wrong": "this is en"],
            "es_ES": Self.expectedTranslations,
            "fr_FR": ["wrong": "this is fr_FR"]
        ]

        let locale = Locale(identifier: "es_MX")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_es_ES_matches_none_when_no_es_locale_present() {
        let localizations = [
            "en": Self.expectedTranslations
        ]

        let locale = Locale(identifier: "es_ES")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(beNil())
    }

    func test_az_AZ() {
        let localizations = [
            "az": Self.expectedTranslations,
            "en": ["wrong": "this is en"]
        ]

        let locale = Locale(identifier: "az_AZ")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_eu_ES() {
        let localizations = [
            "eu": Self.expectedTranslations,
            "en": ["wrong": "this is en"]
        ]

        let locale = Locale(identifier: "eu_ES")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_sr_RS() {
        let localizations = [
            "sr": Self.expectedTranslations,
            "en": ["wrong": "this is en"]
        ]

        let locale = Locale(identifier: "sr_RS")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }

    func test_sr_Latn_RS() {
        let localizations = [
            "sr_Latn": Self.expectedTranslations,
            "en": ["wrong": "this is en"]
        ]

        let locale = Locale(identifier: "sr-Latn_RS")

        let foundLocalizations = localizations.findLocale(locale)
        expect(foundLocalizations).to(equal(Self.expectedTranslations))
    }
}
