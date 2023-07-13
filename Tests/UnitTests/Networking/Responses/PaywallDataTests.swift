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

        expect(paywall.template) == .example1
        expect(paywall.defaultLocale) == Locale(identifier: Self.defaultLocale)

        let enConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "en_US")))
        expect(enConfig.title) == "Paywall"
        expect(enConfig.subtitle) == "Description"
        expect(enConfig.callToAction) == "Purchase now"
        expect(enConfig.offerDetails) == "{{ price_per_month }} per month"

        let esConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "es_ES")))
        expect(esConfig.title) == "Tienda"
        expect(esConfig.subtitle) == "Descripción"
        expect(esConfig.callToAction) == "Comprar"
        expect(esConfig.offerDetails) == "{{ price_per_month }} cada mes"

        expect(paywall.localizedConfiguration) == paywall.config(for: Locale.current)

        expect(paywall.config(for: Locale(identifier: "gl_ES"))).to(beNil())
    }

    func testMissingCurrentLocaleLoadsDefault() throws {
        let paywall: PaywallData = try self.decodeFixture("PaywallData-missing_current_locale")

        expect(paywall.defaultLocale.identifier) == "es_ES"

        let localization = paywall.localizedConfiguration
        expect(localization.callToAction) == "Purchase now"
        expect(localization.title) == "Paywall"
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
