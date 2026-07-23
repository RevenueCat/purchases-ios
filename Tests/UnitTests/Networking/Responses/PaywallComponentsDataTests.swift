//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentsDecodingTests.swift
//
//  Created by Antonio Pallares on 13/2/25.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

class PaywallComponentsDecodingTests: BaseHTTPResponseTest {

    private var response: OfferingsResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.response = try Self.decodeFixture("OfferingsWithPaywallComponents")
    }

    func testDecodesPaywallComponents() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 0])

        expect(offering.identifier) == "paywall_components"
        expect(offering.description) == "Offering with paywall components"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(1))

        let components = try XCTUnwrap(offering.paywallComponents)
        expect(components.id) == "pw_test_1"
        expect(components.templateName) == "componentsTEST"
        expect(components.revision) == 3
        expect(components.componentsConfig.base.background) == .color(.init(light: .hex("#220000ff"), dark: nil))
        expect(components.componentsConfig.base.stickyFooter) == nil
        expect(components.componentsConfig.base.stack.spacing) == 16
        expect(components.componentsConfig.base.stack.dimension) == .vertical(.center, .center)
        expect(components.componentsConfig.base.stack.components).to(haveCount(0))
    }

    func testDecodesPaywallComponentsWhenResponseAlsoContainsDraftComponents() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 1])

        expect(offering.identifier) == "paywall_components_with_draft"
        expect(offering.description) == "Offering with paywall components + draft paywall"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(1))

        let components = try XCTUnwrap(offering.paywallComponents)
        expect(components.templateName) == "componentsTEST"
        expect(components.revision) == 3
        expect(components.componentsConfig.base.background) == .color(.init(light: .hex("#220000ff"), dark: nil))
        expect(components.componentsConfig.base.stickyFooter) == nil
        expect(components.componentsConfig.base.stack.spacing) == 16
        expect(components.componentsConfig.base.stack.dimension) == .vertical(.center, .center)
        expect(components.componentsConfig.base.stack.components).to(haveCount(1))
    }

    func testDecodesPaywallComponentsWithOnlyDraftPaywallComponents() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 2])

        expect(offering.identifier) == "only_draft_paywall_components"
        expect(offering.description) == "Offering with only draft paywall"
        expect(offering.metadata) == [:]
        expect(offering.packages).to(haveCount(1))

        XCTAssertNil(offering.paywallComponents)

    }

    func testDecodesPaywallComponentsWithExitOffers() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 3])

        expect(offering.identifier) == "paywall_components_with_exit_offers"
        expect(offering.description) == "Offering with paywall components and exit offers"
        expect(offering.packages).to(haveCount(1))

        let components = try XCTUnwrap(offering.paywallComponents)
        expect(components.templateName) == "componentsTEST"

        let exitOffers = try XCTUnwrap(components.exitOffers)
        let dismissExitOffer = try XCTUnwrap(exitOffers.dismiss)
        expect(dismissExitOffer.offeringId) == "exit_offer_offering_id"
    }

    func testDecodesPaywallComponentsWithoutExitOffers() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 0])

        let components = try XCTUnwrap(offering.paywallComponents)
        expect(components.exitOffers).to(beNil())
    }

    func testDecodesPaywallComponentsWithZeroDecimalPlaceCountries() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 4])

        expect(offering.identifier) == "paywall_components_with_zero_decimal_countries"
        expect(offering.description) == "Offering with paywall components and zero decimal place countries"

        let components = try XCTUnwrap(offering.paywallComponents)
        expect(components.zeroDecimalPlaceCountries) == ["TWN", "KAZ", "MEX", "PHL", "THA", "IND"]
    }

    func testDecodesPaywallComponentsWithoutZeroDecimalPlaceCountries() throws {
        let offering = try XCTUnwrap(self.response.offerings[safe: 0])

        let components = try XCTUnwrap(offering.paywallComponents)
        expect(components.zeroDecimalPlaceCountries).to(beEmpty())
    }
}
