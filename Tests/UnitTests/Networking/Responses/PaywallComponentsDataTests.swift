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
        let response = try OfferingsResponse.create(with: Self.data(for: "OfferingsWithPaywallComponents"))

        expect(response.offerings).to(haveCount(self.response.offerings.count))
        expect(response.offerings.first?.identifier) == self.response.offerings.first?.identifier
        expect(response.offerings.first?.packages) == self.response.offerings.first?.packages
        XCTAssertTrue(response.offerings.allSatisfy { $0.paywallComponents == nil })
        expect(response.offerings.first?.hasPaywallComponents) == true
    }

    func testDecodingWithoutPaywallComponentsPreservesPublishedAndDraftMarkers() throws {
        let offerings = try OfferingsResponse.create(
            with: Self.data(for: "OfferingsWithPaywallComponents")
        ).offerings

        expect(offerings.map(\.identifier)) == [
            "paywall_components",
            "paywall_components_with_draft",
            "only_draft_paywall_components",
            "paywall_components_with_exit_offers",
            "paywall_components_with_zero_decimal_countries"
        ]
        expect(offerings.map(\.hasPaywallComponents)) == [true, true, false, true, true]
        XCTAssertTrue(offerings.allSatisfy { $0.paywallComponents == nil })
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

    func testDecodingWithoutPaywallComponentsDefaultsMissingMarkerToFalse() throws {
        let offering = try self.decodeOffering(paywallComponents: nil, hasPaywallComponents: nil)

        expect(offering.paywallComponents).to(beNil())
        expect(offering.hasPaywallComponents) == false
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
        let pruned = try XCTUnwrap(
            OfferingsResponse.create(with: data).offerings.first
        )

        expect(pruned.identifier) == offering["identifier"] as? String
        expect(pruned.description) == offering["description"] as? String
        expect(pruned.paywallComponents).to(beNil())
        expect(pruned.hasPaywallComponents) == true
        expect(pruned.paywall).toNot(beNil())
        expect(pruned.metadata) == ["string": "value", "number": 5, "boolean": true]
        expect(pruned.webCheckoutUrl) == URL(string: "https://example.com/offering")
        expect(pruned.packages.first?.webCheckoutUrl) == URL(string: "https://example.com/package")
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
        let response = try OfferingsResponse.create(with: data)
        return try XCTUnwrap(response.offerings.first)
    }

}
