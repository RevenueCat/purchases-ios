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

    override func setUp() {
        super.setUp()

        expect(Locale.current.identifier).to(
            equal(Self.defaultLocale),
            description: "Tests require this"
        )
    }

    func testSample1() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        expect(paywall.template) == .singlePackage
        expect(paywall.defaultLocale) == Locale(identifier: Self.defaultLocale)
        expect(paywall.assetBaseURL) == URL(string: "https://rc-paywalls.s3.amazonaws.com")!
        expect(paywall.config.packages) == [.monthly, .annual]
        expect(paywall.config.imageNames) == ["asset_name.png"]
        expect(paywall.config.blurredBackgroundImage) == true
        expect(paywall.config.displayRestorePurchases) == false
        expect(paywall.config.termsOfServiceURL) == URL(string: "https://revenuecat.com/tos")!
        expect(paywall.config.privacyURL) == URL(string: "https://revenuecat.com/privacy")!

        expect(paywall.config.colors.light.background.stringRepresentation) == "#FF00AA"
        expect(paywall.config.colors.light.foreground.stringRepresentation) == "#FF00AA22"
        expect(paywall.config.colors.light.callToActionBackground.stringRepresentation) == "#FF00AACC"
        expect(paywall.config.colors.light.callToActionForeground.stringRepresentation) == "#FF00AA"

        expect(paywall.config.colors.dark?.background.stringRepresentation) == "#FF0000"
        expect(paywall.config.colors.dark?.foreground.stringRepresentation) == "#1100FFAA"
        expect(paywall.config.colors.dark?.callToActionBackground.stringRepresentation) == "#112233AA"
        expect(paywall.config.colors.dark?.callToActionForeground.stringRepresentation) == "#AABBCC"

        expect(paywall.imageURLs) == [
            URL(string: "https://rc-paywalls.s3.amazonaws.com/asset_name.png")!
        ]

        let enConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "en_US")))
        expect(enConfig.title) == "Paywall"
        expect(enConfig.subtitle) == "Description"
        expect(enConfig.callToAction) == "Purchase now"
        expect(enConfig.callToActionWithIntroOffer) == "Purchase now"
        expect(enConfig.offerDetails) == "{{ price_per_month }} per month"
        expect(enConfig.offerDetailsWithIntroOffer)
        == "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month"

        let esConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "es_ES")))
        expect(esConfig.title) == "Tienda"
        expect(esConfig.subtitle) == "Descripción"
        expect(esConfig.callToAction) == "Comprar"
        expect(esConfig.callToActionWithIntroOffer).to(beNil())
        expect(esConfig.offerDetails) == "{{ price_per_month }} cada mes"
        expect(esConfig.offerDetailsWithIntroOffer).to(beNil())

        expect(paywall.localizedConfiguration) == paywall.config(for: Locale.current)

        expect(paywall.config(for: Locale(identifier: "gl_ES"))).to(beNil())
    }

    func testFindsLocaleWithOnlyLanguage() throws {
        // `Locale.language.languageCode` is iOS 16 only
        // and so is RevenueCatUI anyway.
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        let enConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "en")))
        expect(enConfig.title) == "Paywall"

        let esConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "es")))
        expect(esConfig.title) == "Tienda"
    }

    func testDoesNotFindLocaleWithMissingLanguage() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-Sample1")

        expect(paywall.config(for: Locale(identifier: "fr"))).to(beNil())
    }

    func testMissingCurrentLocaleLoadsDefault() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-missing_current_locale")

        expect(paywall.defaultLocale.identifier) == "es_ES"

        let localization = paywall.localizedConfiguration
        expect(localization.callToAction) == "Comprar"
        expect(localization.title) == "Tienda"
    }

    func testFailsToDecodeWithNoImages() throws {
        expect {
            let _: PaywallData = try self.decodeFixture("PaywallData-empty_images")
        }.to(throwError(EnsureNonEmptyArrayDecodable<String>.Error()))
    }

    #if !os(watchOS)
    func testMissingCurrentAndDefaultFails() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-missing_current_and_default_locale")

        expect(paywall.defaultLocale.identifier) == "es_ES"

        expect {
            let _: PaywallData.LocalizedConfiguration = paywall.localizedConfiguration
        }.to(throwAssertion())
    }
    #endif

}

private extension PaywallDataTests {

    static let defaultLocale = "en_US"

}
