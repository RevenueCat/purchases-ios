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

    func testDecodingWithoutPaywallComponentsSkipsPublishedBody() throws {
        let response = try OfferingsResponse.create(
            with: Self.data(for: "OfferingsWithPaywallComponents"),
            decodingMode: .withoutPaywallComponents
        )

        expect(response.offerings).to(haveCount(self.response.offerings.count))
        expect(response.offerings.first?.identifier) == self.response.offerings.first?.identifier
        expect(response.offerings.first?.packages) == self.response.offerings.first?.packages
        XCTAssertTrue(response.offerings.allSatisfy { $0.paywallComponents == nil })
        expect(response.offerings.first?.hasPaywallComponents) == true
    }

    func testDecodingWithoutPaywallComponentsInfersMarkerWithoutDecodingMalformedPayload() throws {
        let offering = try self.decodeOffering(
            paywallComponents: ["intentionally_invalid": true],
            hasPaywallComponents: nil
        )

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents) == true
    }

    func testDecodingWithoutPaywallComponentsPreservesExplicitFalseMarker() throws {
        let offering = try self.decodeOffering(
            paywallComponents: ["intentionally_invalid": true],
            hasPaywallComponents: false
        )

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents) == false
    }

    func testDecodingWithoutPaywallComponentsTreatsNullPayloadAsNotPresent() throws {
        let offering = try self.decodeOffering(paywallComponents: NSNull(), hasPaywallComponents: nil)

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents) == false
    }

    func testDecodingWithoutPaywallComponentsPreservesMissingMarkerWhenPayloadIsMissing() throws {
        let offering = try self.decodeOffering(paywallComponents: nil, hasPaywallComponents: nil)

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents).to(beNil())
    }

    func testDecodingWithoutPaywallComponentsPreservesExplicitTrueMarkerWhenPayloadIsMissing() throws {
        let offering = try self.decodeOffering(paywallComponents: nil, hasPaywallComponents: true)

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents) == true
    }

    func testDecodingWithoutPaywallComponentsPreservesExplicitTrueMarkerWhenPayloadIsNull() throws {
        let offering = try self.decodeOffering(paywallComponents: NSNull(), hasPaywallComponents: true)

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents) == true
    }

    func testDecodingWithoutPaywallComponentsInfersMarkerWhenExplicitMarkerIsNull() throws {
        let offering = try self.decodeOffering(
            paywallComponents: ["intentionally_invalid": true],
            hasPaywallComponents: NSNull()
        )

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents) == true
    }

    func testDecodingWithoutPaywallComponentsPreservesEveryOtherOfferingField() throws {
        let componentFixture = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Self.data(for: "OfferingsWithPaywallComponents")) as? [String: Any]
        )
        let legacyFixture = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Self.data(for: "Offerings")) as? [String: Any]
        )
        var offering = try XCTUnwrap((componentFixture["offerings"] as? [[String: Any]])?[safe: 1])
        let legacyPaywallOffering = try XCTUnwrap((legacyFixture["offerings"] as? [[String: Any]])?[safe: 2])

        offering["paywall"] = legacyPaywallOffering["paywall"]
        offering["metadata"] = ["string": "value", "number": 5, "boolean": true]
        offering["has_paywall_components"] = true
        offering["web_checkout_url"] = "https://example.com/offering"
        var packages = try XCTUnwrap(offering["packages"] as? [[String: Any]])
        packages[0]["web_checkout_url"] = "https://example.com/package"
        offering["packages"] = packages

        let data = try JSONSerialization.data(withJSONObject: ["offerings": [offering]])
        let full = try XCTUnwrap(
            OfferingsResponse.create(with: data, decodingMode: .withPaywallComponents).offerings.first
        )
        let pruned = try XCTUnwrap(
            OfferingsResponse.create(with: data, decodingMode: .withoutPaywallComponents).offerings.first
        )

        var expectedPruned = full
        expectedPruned.paywallComponents = nil

        expect(pruned) == expectedPruned
        expect(pruned.paywall).toNot(beNil())
        expect(pruned.metadata) == ["string": "value", "number": 5, "boolean": true]
        expect(pruned.webCheckoutUrl) == URL(string: "https://example.com/offering")
        expect(pruned.packages.first?.webCheckoutUrl) == URL(string: "https://example.com/package")
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

private extension PaywallComponentsDecodingTests {

    func decodeOffering(
        paywallComponents: Any?,
        hasPaywallComponents: Any?
    ) throws -> OfferingsResponse.Offering {
        var offering: [String: Any] = [
            "identifier": "test",
            "description": "Test offering",
            "packages": [[
                "identifier": "$rc_monthly",
                "platform_product_identifier": "product"
            ]]
        ]
        offering["paywall_components"] = paywallComponents
        offering["has_paywall_components"] = hasPaywallComponents

        let data = try JSONSerialization.data(withJSONObject: ["offerings": [offering]])
        let response = try OfferingsResponse.create(with: data, decodingMode: .withoutPaywallComponents)
        return try XCTUnwrap(response.offerings.first)
    }

}
