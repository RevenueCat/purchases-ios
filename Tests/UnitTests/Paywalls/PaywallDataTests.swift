//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallDataTests.swift
//
//  Created by Nacho Soto on 7/11/23.

import Nimble
@testable import RevenueCat
import XCTest

class PaywallDataTests: BaseHTTPResponseTest {

    func testSample1() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        expect(paywall.templateName) == "1"
        expect(paywall.assetBaseURL) == URL(string: "https://rc-paywalls.s3.amazonaws.com")!
        expect(paywall.revision) == 7
        expect(paywall.config.packages) == ["$rc_monthly", "$rc_annual", "custom_package"]
        expect(paywall.config.defaultPackage) == "$rc_annual"
        expect(paywall.config.images) == .init(
            header: "header.heic",
            background: "background.jpg",
            icon: "icon.heic"
        )
        expect(paywall.config.imagesLowRes) == .init(
            header: "header_low_res.heic",
            background: nil,
            icon: nil
        )
        expect(paywall.config.blurredBackgroundImage) == true
        expect(paywall.config.displayRestorePurchases) == false
        expect(paywall.config.termsOfServiceURL) == URL(string: "https://revenuecat.com/tos")!
        expect(paywall.config.privacyURL) == URL(string: "https://revenuecat.com/privacy")!

        expect(paywall.config.colors.light.background?.stringRepresentation) == "#FF00AA"
        expect(paywall.config.colors.light.text1?.stringRepresentation) == "#FF00AA22"
        expect(paywall.config.colors.light.text2?.stringRepresentation) == "#FF00AA11"
        expect(paywall.config.colors.light.text3?.stringRepresentation) == "#FF00AA33"
        expect(paywall.config.colors.light.callToActionBackground?.stringRepresentation) == "#FF00AACC"
        expect(paywall.config.colors.light.callToActionForeground?.stringRepresentation) == "#FF00AA"
        expect(paywall.config.colors.light.callToActionSecondaryBackground?.stringRepresentation) == "#FF00BB"
        expect(paywall.config.colors.light.accent1?.stringRepresentation) == "#FF0000"
        expect(paywall.config.colors.light.accent2?.stringRepresentation) == "#00FF00"
        expect(paywall.config.colors.light.accent3?.stringRepresentation) == "#0000FF"

        expect(paywall.config.colors.dark?.background?.stringRepresentation) == "#FF0000"
        expect(paywall.config.colors.dark?.text1?.stringRepresentation) == "#FF0011"
        expect(paywall.config.colors.dark?.text2).to(beNil())
        expect(paywall.config.colors.dark?.text3).to(beNil())
        expect(paywall.config.colors.dark?.callToActionBackground?.stringRepresentation) == "#112233AA"
        expect(paywall.config.colors.dark?.callToActionForeground?.stringRepresentation) == "#AABBCC"
        expect(paywall.config.colors.dark?.accent1?.stringRepresentation) == "#00FFFF"
        expect(paywall.config.colors.dark?.accent2?.stringRepresentation) == "#FF00FF"
        expect(paywall.config.colors.dark?.accent3).to(beNil())

        let enConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "en_US")))
        expect(enConfig.title) == "Paywall"
        expect(enConfig.subtitle) == "Description"
        expect(enConfig.callToAction) == "Purchase now"
        expect(enConfig.callToActionWithIntroOffer) == "Purchase now"
        expect(enConfig.offerDetails) == "{{ sub_price_per_month }} per month"
        expect(enConfig.offerDetailsWithIntroOffer)
        == "Start your {{ sub_offer_duration }} trial, then {{ sub_price_per_month }} per month"
        expect(enConfig.offerName) == "{{ period }}"
        expect(enConfig.features) == [
            .init(title: "Feature 1", content: "Content 1", iconID: "lock"),
            .init(title: "Feature 2", content: "Content 2", iconID: "bell")
        ]

        let esConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "es_ES")))
        expect(esConfig.title) == "Tienda"
        expect(esConfig.subtitle).to(beNil())
        expect(esConfig.callToAction) == "Comprar"
        expect(esConfig.callToActionWithIntroOffer).to(beNil())
        expect(esConfig.offerDetails).to(beNil())
        expect(esConfig.offerDetailsWithIntroOffer).to(beNil())
        expect(esConfig.offerName) == "{{ period }}"
        expect(esConfig.features) == [
            .init(title: "Lista 1", content: "Contenido", iconID: "lock")
        ]

        expect(paywall.localizedConfiguration) == paywall.config(for: Locale.current)

        expect(paywall.config(for: Locale(identifier: "gl_ES"))).to(beNil())
    }

    func testChineseLocalizations() throws {
        // This logic only works on iOS 16+
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let paywall: PaywallData = try self.decodeFixture("PaywallData-chinese")

        let traditional = try XCTUnwrap(paywall.config(for: Locale(identifier: "zh-Hant")))
        let simplified = try XCTUnwrap(paywall.config(for: Locale(identifier: "zh-Hans")))
        let taiwan = try XCTUnwrap(paywall.config(for: Locale(identifier: "zh-TW")))

        expect(traditional.title) == "Traditional"
        expect(simplified.title) == "Simplified"
        expect(taiwan.title) == "Traditional"
    }

    func testModifyingImages() throws {
        var paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")
        var expected = paywall.config.images

        paywall.config.images.header = nil
        expected.header = nil

        expect(paywall.config.images) == expected
    }

    func testFindsLocaleWithOnlyLanguage() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        let enConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "en")))
        expect(enConfig.title) == "Paywall"

        let esConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "es")))
        expect(esConfig.title) == "Tienda"
    }

    func testLocalizedConfigurationFallsBackToLanguageWithDifferentRegion() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        let (_, enConfig) = try XCTUnwrap(paywall.localizedConfiguration(for: [
            .init(identifier: "en_IN"),
            .init(identifier: "en-IN")
        ]))
        expect(enConfig.title) == "Paywall"
    }

    func testLocalizedConfigurationLooksForCurrentLocaleWithoutRegionBeforePreferedLocales() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        let (_, enConfig) = try XCTUnwrap(paywall.localizedConfiguration(for: [
            .init(identifier: "en_IN"),
            .init(identifier: "es_ES")
        ]))
        expect(enConfig.title) == "Paywall"
    }

    func testLocalesOrderedByPriority() throws {
        let expected: [String]

        if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            expected = [
                "en-US"
            ]
        } else {
            expected = [
                // `Locale.preferredLanguages` returns `en` before iOS 17.
                "en"
            ]
        }

        expect(PaywallData.localesOrderedByPriority.map(\.identifier)) == expected
    }

    func testDoesNotFindLocaleWithMissingLanguage() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        expect(paywall.config(for: Locale(identifier: "fr"))).to(beNil())
    }

    func testMissingCurrentLocaleLoadsAvailableLocale() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-missing_current_locale")

        let localization = try XCTUnwrap(paywall.localizedConfiguration)
        expect(localization.callToAction) == "Comprar"
        expect(localization.title) == "Tienda"
    }

    func testEmptyImageNamesAreParsedAsNil() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-empty_images")

        let images = paywall.config.images
        expect(images.header).to(beNil())
        expect(images.background).to(beNil())
        expect(images.icon).to(beNil())
    }

    func testMultiTierLocalizationIsNil() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")
        expect(paywall.localizedConfigurationByTier(for: [.init(identifier: "en_US")]))
            .to(beNil())
    }

    func testEncodePaywallViewMode() throws {
        for mode in PaywallViewMode.allCases {
            expect(try mode.encodeAndDecode()) == mode
        }
    }

}

private extension PaywallDataTests {

    static let defaultLocale = "en_US"

}
