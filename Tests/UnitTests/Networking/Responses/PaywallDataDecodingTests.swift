//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallDecodingTests.swift
//
//  Created by Josh Holtz on 12/31/24.

import Nimble
@testable import RevenueCat
import XCTest

class PaywallDataDecodingTests: BaseHTTPResponseTest {

    private var response: OfferingsResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.response = try Self.decodeFixture("Offerings")
    }

    func testDecodesPaywallData() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 2])

        expect(offering.identifier) == "paywall"
        expect(offering.description) == "Offering with paywall"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(2))

        let paywall = try XCTUnwrap(offering.paywall)
        expect(paywall.templateName) == "1"
        try expect(paywall.assetBaseURL) == XCTUnwrap(URL(string: "https://rc-paywalls.s3.amazonaws.com"))
        expect(paywall.revision) == 5

        expect(paywall.config.packages) == ["$rc_monthly", "$rc_annual", "custom_package"]
        expect(paywall.config.defaultPackage).to(beNil())
        expect(paywall.config.images.header) == "header.heic"
        expect(paywall.config.images.background).to(beNil())
        expect(paywall.config.images.icon).to(beNil())

        expect(paywall.config.imagesLowRes.header) == "header_low_res.heic"
        expect(paywall.config.imagesLowRes.background).to(beNil())
        expect(paywall.config.imagesLowRes.icon).to(beNil())

        let enConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "en_US")))
        expect(enConfig.title) == "Paywall"
        expect(enConfig.subtitle) == "Description"
        expect(enConfig.callToAction) == "Purchase now"
        expect(enConfig.callToActionWithIntroOffer) == "Purchase now"
        expect(enConfig.offerDetails) == "{{ sub_price_per_month }} per month"
        expect(enConfig.offerDetailsWithIntroOffer)
        == "Start your {{ sub_offer_duration }} trial, then {{ sub_price_per_month }} per month"
        expect(enConfig.offerName).to(beNil())
        expect(enConfig.features) == [
            .init(title: "Feature 1", content: "Content", iconID: "lock")
        ]

        let esConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "es_ES")))
        expect(esConfig.title) == "Tienda"
        expect(esConfig.subtitle).to(beNil())
        expect(esConfig.callToAction) == "Comprar"
        expect(esConfig.callToActionWithIntroOffer) == "Comprar"
        expect(esConfig.offerDetails) == "{{ sub_price_per_month }} cada mes"
        expect(esConfig.offerDetailsWithIntroOffer)
        == "Comienza tu prueba de {{ sub_offer_duration }}, y después {{ sub_price_per_month }} cada mes"
        expect(esConfig.offerName).to(beNil())
        expect(esConfig.features).to(beEmpty())

        // This test relies on this
        expect(Locale.current.identifier) == "en_US"
        expect(paywall.localizedConfiguration) == paywall.config(for: Locale.current)

        expect(paywall.config(for: Locale(identifier: "gl_ES"))).to(beNil())
    }

    func testIgnoresInvalidPaywallData() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 5])

        expect(offering.identifier) == "invalid_paywall"
        expect(offering.packages).to(haveCount(1))
        expect(offering.paywall).to(beNil())
    }

}
