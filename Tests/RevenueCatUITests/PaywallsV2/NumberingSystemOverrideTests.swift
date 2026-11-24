//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NumberingSystemOverrideTests.swift

import Nimble
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class NumberingSystemOverrideTests: TestCase {

    func testReadsNumberingSystemFromLanguageTag() {
        expect(Locale.numberingSystemOverride(from: "ar-SA-u-nu-latn")) == "latn"
    }

    func testReadsNumberingSystemFromLocaleIdentifier() {
        expect(Locale.numberingSystemOverride(from: "ar_SA@numbers=latn")) == "latn"
    }

    func testIgnoresOverrideWithoutNumberingSystem() {
        expect(Locale.numberingSystemOverride(from: "es-ES")).to(beNil())
        expect(Locale.numberingSystemOverride(from: nil)).to(beNil())
    }

    func testIgnoresInvalidNumberingSystems() {
        expect(Locale.numberingSystemOverride(from: "ar-SA-u-nu-zzzz")).to(beNil())
        expect(Locale.numberingSystemOverride(from: "ar-SA-u-nu-toolongvalue")).to(beNil())
        expect(Locale.numberingSystemOverride(from: "ar-SA-u-nu-1")).to(beNil())
    }

    func testCopiesOnlyTheNumberingSystem() {
        let locale = Locale(identifier: "ar_SA").withNumberingSystem("latn")

        expect(locale.identifier) == "ar_SA@numbers=latn"
        expect(Locale(identifier: "ar_SA").withNumberingSystem(nil).identifier) == "ar_SA"
    }

    func testChooseLocalizationKeepsPaywallLocaleWithNumberingSystemOverride() {
        let provider = Self.chooseLocalization(override: "ar-SA-u-nu-latn")

        expect(provider.locale.identifier) == "ar"
        expect(provider.numberingSystem) == "latn"
    }

    func testChooseLocalizationIgnoresOverridesWithoutValidNumberingSystem() {
        expect(Self.chooseLocalization(override: nil).numberingSystem).to(beNil())
        expect(Self.chooseLocalization(override: "es-ES").numberingSystem).to(beNil())
        expect(Self.chooseLocalization(override: "ar-SA-u-nu-zzzz").numberingSystem).to(beNil())
        expect(Self.chooseLocalization(override: "ar-SA-u-nu-zzzz").locale.identifier) == "ar"
    }

    private static func chooseLocalization(override: String?) -> LocalizationProvider {
        return PaywallsV2View.chooseLocalization(
            componentsLocalizations: ["en": [:], "ar": [:]],
            preferredLocales: [Locale(identifier: "ar-SA-u-nu-latn"), Locale(identifier: "en_US")],
            defaultLocale: "en",
            preferredLocaleOverride: override
        )
    }

}

#endif
