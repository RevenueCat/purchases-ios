//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VerifiedRewardTests.swift
//
//  Created by Pol Miro on 21/04/2026.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class VerifiedRewardTests: TestCase {

    func testVirtualCurrencyCarriesAssociatedReward() {
        let reward = VirtualCurrencyReward(code: "coins", amount: 5)
        let value: VerifiedReward = .virtualCurrency(reward)

        guard case .virtualCurrency(let captured) = value else {
            return XCTFail("Expected .virtualCurrency, got \(value)")
        }
        expect(captured) == reward
    }

    func testNoRewardAndUnsupportedRewardAreDistinctCases() {
        expect(VerifiedReward.noReward) != .unsupportedReward
        expect(VerifiedReward.noReward) == .noReward
        expect(VerifiedReward.unsupportedReward) == .unsupportedReward
    }

    func testEqualityRequiresMatchingAssociatedReward() {
        let one = VirtualCurrencyReward(code: "coins", amount: 5)
        let two = VirtualCurrencyReward(code: "coins", amount: 6)
        expect(VerifiedReward.virtualCurrency(one)) == VerifiedReward.virtualCurrency(one)
        expect(VerifiedReward.virtualCurrency(one)) != VerifiedReward.virtualCurrency(two)
        expect(VerifiedReward.virtualCurrency(one)) != VerifiedReward.noReward
        expect(VerifiedReward.virtualCurrency(one)) != VerifiedReward.unsupportedReward
    }

    func testSwitchExhaustivelyCoversAllCases() {
        let values: [VerifiedReward] = [
            .virtualCurrency(VirtualCurrencyReward(code: "coins", amount: 1)),
            .noReward,
            .unsupportedReward
        ]
        for value in values {
            switch value {
            case .virtualCurrency: continue
            case .noReward: continue
            case .unsupportedReward: continue
            }
        }
        expect(values.count) == 3
    }

}
