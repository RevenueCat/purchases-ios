//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsDecodingTests.swift
//
//  Created by Nacho Soto on 5/12/22.

import Nimble
@testable import RevenueCat
import XCTest

class OfferingsDecodingTests: BaseHTTPResponseTest {

    private var response: OfferingsResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.response = try self.decodeFixture("Offerings")
    }

    func testDecodesAllOfferings() throws {
        expect(self.response.currentOfferingId) == "default"
        expect(self.response.offerings).to(haveCount(6))
    }

    func testDecodesFirstOffering() throws {
        let offering = try XCTUnwrap(self.response.offerings.first)

        expect(offering.identifier) == "default"
        expect(offering.description) == "standard set of packages"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(2))

        let package1 = try XCTUnwrap(offering.packages.first)
        let package2 = try XCTUnwrap(offering.packages[safe: 1])

        expect(package1.identifier) == PackageType.monthly.description
        expect(package1.platformProductIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"

        expect(package2.identifier) == PackageType.annual.description
        expect(package2.platformProductIdentifier) == "com.revenuecat.yearly_10.99.2_week_intro"
    }

    func testDecodesSecondOffering() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 1])

        expect(offering.identifier) == "alternate"
        expect(offering.description) == "alternate offering"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(1))

        let package = try XCTUnwrap(offering.packages.first)

        expect(package.identifier) == PackageType.lifetime.description
        expect(package.platformProductIdentifier) == "com.revenuecat.other_product"
    }

    func testDecodesMetadataOffering() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 3])

        expect(offering.identifier) == "metadata"
        expect(offering.description) == "offering with metadata"
        expect(offering.metadata) == [
            "int": 5,
            "double": 5.5,
            "boolean": true,
            "string": "five",
            "array": ["five"],
            "dictionary": [
                "string": "five"
            ]
        ]
        expect(offering.packages).to(haveCount(1))

        let package = try XCTUnwrap(offering.packages.first)

        expect(package.identifier) == PackageType.lifetime.description
        expect(package.platformProductIdentifier) == "com.revenuecat.other_product"
    }

    func testDecodesNullMetadataOffering() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 4])

        expect(offering.identifier) == "nullmetadata"
        expect(offering.description) == "offering with null metadata"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(1))

        let package = try XCTUnwrap(offering.packages.first)

        expect(package.identifier) == PackageType.lifetime.description
        expect(package.platformProductIdentifier) == "com.revenuecat.other_product"
    }

    func testDecodesPaywallData() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 2])

        expect(offering.identifier) == "paywall"
        expect(offering.description) == "Offering with paywall"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(2))

        let paywall = try XCTUnwrap(offering.paywall)
        expect(paywall.template) == .onePackageStandard
        expect(paywall.defaultLocale) == Locale(identifier: "en_US")
        try expect(paywall.assetBaseURL) == XCTUnwrap(URL(string: "https://rc-paywalls.s3.amazonaws.com"))

        expect(paywall.config.packages) == [.monthly, .annual]
        expect(paywall.config.defaultPackage).to(beNil())
        expect(paywall.config.images.header) == "header.jpg"
        expect(paywall.config.images.background).to(beNil())
        expect(paywall.config.images.icon).to(beNil())

        let enConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "en_US")))
        expect(enConfig.title) == "Paywall"
        expect(enConfig.subtitle) == "Description"
        expect(enConfig.callToAction) == "Purchase now"
        expect(enConfig.callToActionWithIntroOffer) == "Purchase now"
        expect(enConfig.offerDetails) == "{{ price_per_month }} per month"
        expect(enConfig.offerDetailsWithIntroOffer)
        == "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month"
        expect(enConfig.offerName).to(beNil())
        expect(enConfig.features) == [
            .init(title: "Feature 1", content: "Content", iconID: "lock")
        ]

        let esConfig = try XCTUnwrap(paywall.config(for: Locale(identifier: "es_ES")))
        expect(esConfig.title) == "Tienda"
        expect(esConfig.subtitle) == "Descripción"
        expect(esConfig.callToAction) == "Comprar"
        expect(esConfig.callToActionWithIntroOffer) == "Comprar"
        expect(esConfig.offerDetails) == "{{ price_per_month }} cada mes"
        expect(esConfig.offerDetailsWithIntroOffer)
        == "Comienza tu prueba de {{ intro_duration }}, y después {{ price_per_month }} cada mes"
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

    func testEncoding() throws {
        expect(try self.response.encodeAndDecode()) == self.response
    }

}
