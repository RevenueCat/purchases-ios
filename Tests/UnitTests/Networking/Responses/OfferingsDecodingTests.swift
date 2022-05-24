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
        expect(self.response.offerings).to(haveCount(2))
    }

    func testDecodesFirstOffering() throws {
        let offering = try XCTUnwrap(self.response.offerings.first)

        expect(offering.identifier) == "default"
        expect(offering.description) == "standard set of packages"
        expect(offering.packages).to(haveCount(2))

        let package1 = offering.packages[0]
        let package2 = offering.packages[1]

        expect(package1.identifier) == PackageType.monthly.description
        expect(package1.platformProductIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"

        expect(package2.identifier) == PackageType.annual.description
        expect(package2.platformProductIdentifier) == "com.revenuecat.yearly_10.99.2_week_intro"
    }

    func testDecodesSecondOffering() throws {
        let offering = try XCTUnwrap(self.response.offerings.last)

        expect(offering.identifier) == "alternate"
        expect(offering.description) == "alternate offering"
        expect(offering.packages).to(haveCount(1))

        let package = offering.packages[0]

        expect(package.identifier) == PackageType.lifetime.description
        expect(package.platformProductIdentifier) == "com.revenuecat.other_product"
    }

}
