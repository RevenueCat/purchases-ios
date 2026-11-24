//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPriceLocaleTests.swift

import Nimble
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PaywallPriceLocaleTests: TestCase {

    func testExcludesPOSIXLocale() {
        let result = Locale.storefrontLocalesByLanguage(
            storefrontCountryCode: "USA",
            availableIdentifiers: ["en_US", "en_US_POSIX"]
        )["en"]

        expect(result?.identifier) == "en_US"
        expect(Self.format(1.99, "USD", result)) == "$1.99"
    }

    func testPreservesSelectionBehaviorForNonPOSIXVariants() {
        let result = Locale.storefrontLocalesByLanguage(
            storefrontCountryCode: "ESP",
            availableIdentifiers: ["ca_ES_VALENCIA", "ca_ES"]
        )["ca"]

        expect(result?.identifier) == "ca_ES_VALENCIA"
    }

    func testAcceptsAlpha2StorefrontCountryCodes() {
        let result = Locale.storefrontLocalesByLanguage(
            storefrontCountryCode: "SA",
            availableIdentifiers: ["ar_SA", "en_SA", "ar_EG"]
        )

        expect(result.mapValues(\.identifier)) == ["ar": "ar_SA", "en": "en_SA"]
    }

    func testUsesPaywallLocaleWithoutStorefront() {
        let locale = Self.priceLocale("es_ES", storefront: nil)

        expect(locale.identifier) == "es_ES"
    }

    func testSkipsStorefrontLocalesWithDifferentDigitsWhenPaywallLanguageIsMissing() {
        expect(Locale.storefrontLocalesByLanguage(storefrontCountryCode: "ISR")["es"]).to(beNil())

        let locale = Self.priceLocale("es_ES", storefront: "ISR")

        expect(locale.identifier) == "en_IL"
        let price = Self.format(149.9, "ILS", locale)
        expect(price).to(contain("149.90"))
        expect(Self.hasArabicIndicDigits(price)) == false
    }

    func testUsesStorefrontLocaleForPaywallLanguage() {
        let locale = Self.priceLocale("en_US", storefront: "JPN")

        expect(locale.identifier) == "en_JP"
        expect(Self.format(149, "JPY", locale)) == "¥149"
    }

    func testPreservesChinesePaywallScriptOnChinaStorefront() {
        let identifiers = ["zh_CN", "zh_Hans_CN", "zh_Hant_CN"]

        for (paywall, expected) in [("zh-Hans", "zh_Hans_CN"), ("zh-Hant", "zh_Hant_CN"),
                                   ("zh", "zh_CN"), ("zh_TW", "zh_Hant_CN")] {
            let locale = Self.priceLocale(paywall, storefront: "CHN", availableIdentifiers: identifiers)
            expect(locale) == Locale(identifier: expected)
        }
    }

    func testPreservesPaywallScriptWhenStorefrontOnlyListsAnotherScript() {
        let locale = Self.priceLocale("sr-Latn", storefront: "SRB", availableIdentifiers: ["sr_Cyrl_RS"])

        expect(locale) == Locale(identifier: "sr_Latn_RS")
    }

    func testFallsBackToStorefrontLocaleWithSameNumberFormat() {
        let locale = Self.priceLocale(
            "en_US",
            storefront: "JPN",
            availableIdentifiers: ["ja_JP"]
        )

        expect(locale.identifier) == "ja_JP"
    }

    func testKeepsPaywallNumberFormatWhenNoStorefrontLocaleMatches() {
        let locale = Self.priceLocale(
            "ar",
            storefront: "ISR",
            availableIdentifiers: ["he_IL"]
        )

        expect(locale.identifier) == "ar_IL"
        expect(Self.hasArabicIndicDigits(Self.format(2.58, "USD", locale))) == true
    }

    func testArabicPaywallOnSaudiStorefrontUsesArabicDigits() {
        let locale = Self.priceLocale("ar", storefront: "SAU")

        expect(locale.identifier) == "ar_SA"
        expect(Self.format(2.58, "USD", locale)).to(contain("٢٫٥٨"))
    }

    func testEnglishPaywallOnSaudiStorefrontUsesWesternDigits() {
        let locale = Self.priceLocale("en_US", storefront: "SAU")

        expect(locale.identifier) == "en_SA"
        expect(Self.format(2.58, "USD", locale)).to(contain("2.58"))
    }

    func testChooseLocalizationKeepsArabicPaywallWithNumberingSystemOverride() {
        let provider = PaywallsV2View.chooseLocalization(
            componentsLocalizations: ["en": [:], "ar": [:]],
            preferredLocales: [Locale(identifier: "ar-SA-u-nu-latn"), Locale(identifier: "en_US")],
            defaultLocale: "en",
            storefrontCountryCode: "SAU",
            preferredLocaleOverride: "ar-SA-u-nu-latn"
        )

        expect(provider.locale.identifier) == "ar"
        expect(Locale.characterDirection(forLanguage: provider.locale.identifier)) == .rightToLeft
        expect(provider.priceLocale?.identifier) == "ar_SA"
        expect(provider.numberingSystem) == "latn"
    }

    func testChooseLocalizationUsesPaywallLanguageForPriceLocale() {
        let provider = PaywallsV2View.chooseLocalization(
            componentsLocalizations: ["en": [:], "ar": [:]],
            preferredLocales: [Locale(identifier: "en_US"), Locale(identifier: "ar_SA")],
            defaultLocale: "en",
            storefrontCountryCode: "SAU",
            preferredLocaleOverride: nil
        )

        expect(provider.locale.identifier) == "en"
        expect(provider.priceLocale?.identifier) == "en_SA"
    }

    private static func priceLocale(
        _ paywallLocale: String,
        storefront: String?,
        availableIdentifiers: [String] = Locale.availableIdentifiers
    ) -> Locale {
        return Locale.paywallPriceLocale(
            paywallLocale: Locale(identifier: paywallLocale),
            storefrontCountryCode: storefront,
            availableIdentifiers: availableIdentifiers
        )
    }

    private static func hasArabicIndicDigits(_ string: String?) -> Bool {
        return string?.unicodeScalars.contains { (0x0660...0x0669).contains($0.value) } ?? false
    }

    private static func format(_ price: Decimal, _ currencyCode: String, _ locale: Locale?) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        return formatter.string(from: price as NSDecimalNumber)
    }

}

#endif
