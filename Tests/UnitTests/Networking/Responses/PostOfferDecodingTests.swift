//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostOfferDecodingTests.swift
//
//  Created by Nacho Soto on 5/12/22.

import Nimble
@testable import RevenueCat
import XCTest

class PostOfferDecodingTests: BaseHTTPResponseTest {

    private var response: PostOfferResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.response = try self.decodeFixture("PostOffer")
    }

    func testResponseDataIsCorrect() throws {
        expect(self.response.offers).to(haveCount(1))

        let offer = try XCTUnwrap(self.response.offers.first)

        expect(offer.keyIdentifier) == "C815358F"
        expect(offer.offerIdentifier) == "com.revenuecat.monthly_4.99.1_free_week"
        expect(offer.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(offer.signatureError).to(beNil())

        let signature = try XCTUnwrap(offer.signatureData)
        expect(signature.nonce) == UUID(uuidString: "aea2714d-37cb-4a40-b3fa-3a39cf2ac4ed")
        expect(signature.signature) ==
        "MEUCIQDDMArMh1PHNa75EZ49ntaNoqLIE7ueO8gjcdFYVbe57wIgLO+7M9AeIMUVMybj8ir982nDo6CfDFjTuqd5YSm8NG4="
        expect(signature.timestamp) == 1646761777900
    }

}
