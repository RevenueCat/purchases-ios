//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IsPurchaseAllowedByRestoreBehaviorDecodingTests.swift
//
//  Created by Will Taylor on 6/12/25.

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable:next type_name
class IsPurchaseAllowedByRestoreBehaviorDecodingTests: BaseHTTPResponseTest {

    private var response: IsPurchaseAllowedByRestoreBehaviorResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.response = try Self.decodeFixture("RestoreEligibility")
    }

    func testResponseDataIsCorrect() {
        expect(self.response.isPurchaseAllowedByRestoreBehavior) == true
    }

}
