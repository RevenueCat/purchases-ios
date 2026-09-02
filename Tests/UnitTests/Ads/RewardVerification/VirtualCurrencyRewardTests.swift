//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyRewardTests.swift
//
//  Created by Pol Miro on 21/04/2026.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

final class VirtualCurrencyRewardTests: TestCase {

    func testStoresCodeAndAmount() throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        expect(reward.code) == "coins"
        expect(reward.amount) == 5
    }

    func testEqualityRequiresBothFieldsToMatch() throws {
        let lhs = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        expect(lhs) == VirtualCurrencyReward(code: "coins", amount: 5)
        expect(lhs) != VirtualCurrencyReward(code: "gems", amount: 5)
        expect(lhs) != VirtualCurrencyReward(code: "coins", amount: 6)
    }

    func testInitRejectsEmptyCode() {
        expect(VirtualCurrencyReward(code: "", amount: 5)).to(beNil())
    }

    func testInitRejectsNonPositiveAmount() {
        expect(VirtualCurrencyReward(code: "coins", amount: 0)).to(beNil())
        expect(VirtualCurrencyReward(code: "coins", amount: -1)).to(beNil())
    }

}
