//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExitOfferTests.swift
//
//  Created by RevenueCat.

import Nimble
@testable import RevenueCat
import XCTest

final class ExitOfferTests: TestCase {

    func testExitOfferDecoding() throws {
        let json = """
        {
            "offering_id": "test_offering_id"
        }
        """

        let exitOffer = try JSONDecoder.default.decode(
            ExitOffer.self,
            from: json.data(using: .utf8)!
        )

        expect(exitOffer.offeringId) == "test_offering_id"
    }

    func testExitOfferEncoding() throws {
        let exitOffer = ExitOffer(offeringId: "test_offering_id")

        let data = try JSONEncoder.default.encode(exitOffer)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        expect(decoded?["offering_id"] as? String) == "test_offering_id"
    }

    func testExitOffersDecoding() throws {
        let json = """
        {
            "dismiss": {
                "offering_id": "dismiss_offering_id"
            }
        }
        """

        let exitOffers = try JSONDecoder.default.decode(
            ExitOffers.self,
            from: json.data(using: .utf8)!
        )

        expect(exitOffers.dismiss?.offeringId) == "dismiss_offering_id"
    }

    func testExitOffersDecodingWithNilDismiss() throws {
        let json = """
        {}
        """

        let exitOffers = try JSONDecoder.default.decode(
            ExitOffers.self,
            from: json.data(using: .utf8)!
        )

        expect(exitOffers.dismiss).to(beNil())
    }

    func testExitOffersEncoding() throws {
        let exitOffers = ExitOffers(dismiss: ExitOffer(offeringId: "test_id"))

        let data = try JSONEncoder.default.encode(exitOffers)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let dismiss = decoded?["dismiss"] as? [String: Any]
        expect(dismiss?["offering_id"] as? String) == "test_id"
    }

    func testExitOfferEquality() {
        let offer1 = ExitOffer(offeringId: "test")
        let offer2 = ExitOffer(offeringId: "test")
        let offer3 = ExitOffer(offeringId: "different")

        expect(offer1) == offer2
        expect(offer1) != offer3
    }

    func testExitOffersEquality() {
        let offers1 = ExitOffers(dismiss: ExitOffer(offeringId: "test"))
        let offers2 = ExitOffers(dismiss: ExitOffer(offeringId: "test"))
        let offers3 = ExitOffers(dismiss: ExitOffer(offeringId: "different"))
        let offers4 = ExitOffers(dismiss: nil)

        expect(offers1) == offers2
        expect(offers1) != offers3
        expect(offers1) != offers4
    }

}
