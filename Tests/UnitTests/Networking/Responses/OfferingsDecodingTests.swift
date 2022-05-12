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

    func testResponseDataIsCorrect() throws {
        expect(self.response.currentOfferingId) == "default"
        expect(self.response.offerings).to(haveCount(2))

        let offering1 = self.response.offerings[0]
        let offering2 = self.response.offerings[1]

        expect(offering1.identifier) == "default"
        expect(offering1.description) == "standard set of packages"
        expect(offering1.packages).to(haveCount(2))

        let offering1Package1 = offering1.packages[0]
        let offering1Package2 = offering1.packages[1]

        expect(offering1Package1.identifier) == PackageType.monthly.description
        expect(offering1Package1.platformProductIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"

        expect(offering1Package2.identifier) == PackageType.annual.description
        expect(offering1Package2.platformProductIdentifier) == "com.revenuecat.yearly_10.99.2_week_intro"

        expect(offering2.identifier) == "alternate"
        expect(offering2.description) == "alternate offering"
        expect(offering2.packages).to(haveCount(1))

        let offering2Package = offering2.packages[0]

        expect(offering2Package.identifier) == PackageType.lifetime.description
        expect(offering2Package.platformProductIdentifier) == "com.revenuecat.other_product"
    }

}
