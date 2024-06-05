//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetIntroEligibilityDecodingTests.swift
//
//  Created by Nacho Soto on 5/12/22.

import Nimble
@testable import RevenueCat
import XCTest

class GetIntroEligibilityDecodingTests: BaseHTTPResponseTest {

    private var response: GetIntroEligibilityResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.response = try self.decodeFixture("GetIntroEligibility")
    }

    func testResponseDataIsCorrect() throws {
        expect(self.response.eligibilityByProductIdentifier) == [
            "producta": .eligible,
            "productb": .ineligible,
            "product_c": .unknown,
            "productD": .eligible
        ]
    }

}
