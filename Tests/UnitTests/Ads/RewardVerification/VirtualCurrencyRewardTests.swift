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

@_spi(Internal) @testable import RevenueCat

final class VirtualCurrencyRewardTests: TestCase {

    func testStoresCodeAndAmount() {
        let reward = VirtualCurrencyReward(code: "coins", amount: 5)
        expect(reward.code) == "coins"
        expect(reward.amount) == 5
    }

    func testEqualityRequiresBothFieldsToMatch() {
        let lhs = VirtualCurrencyReward(code: "coins", amount: 5)
        expect(lhs) == VirtualCurrencyReward(code: "coins", amount: 5)
        expect(lhs) != VirtualCurrencyReward(code: "gems", amount: 5)
        expect(lhs) != VirtualCurrencyReward(code: "coins", amount: 6)
    }

    func testSupportsArbitraryDecimalPrecision() {
        // Decimal preserves the full payload precision the backend may emit; sanity-check
        // a fractional and a large-scale value to make sure we don't accidentally truncate
        // to Int/Double in a future refactor.
        let fractional = VirtualCurrencyReward(code: "coins", amount: Decimal(string: "0.123456789")!)
        expect(fractional.amount) == Decimal(string: "0.123456789")!

        let large = VirtualCurrencyReward(code: "coins", amount: Decimal(string: "9999999999999999")!)
        expect(large.amount) == Decimal(string: "9999999999999999")!
    }

}
