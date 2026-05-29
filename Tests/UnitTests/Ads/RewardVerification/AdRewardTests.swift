//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdRewardTests.swift
//
//  Created by Pol Miro on 27/05/2026.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

final class AdRewardTests: TestCase {

    func testVirtualCurrencyCarriesAssociatedPayload() throws {
        let payload = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let reward = AdReward.virtualCurrency(payload)
        expect(reward.virtualCurrency) == payload
        expect(reward.kindRawValue) == "virtual_currency"
    }

    func testVirtualCurrencyConvenienceFactoryStoresCodeAndAmount() {
        let reward = AdReward.virtualCurrency(code: "coins", amount: 5)
        expect(reward.virtualCurrency?.code) == "coins"
        expect(reward.virtualCurrency?.amount) == 5
    }

    func testNoRewardAndUnsupportedRewardAreDistinct() {
        expect(AdReward.noReward) != .unsupportedReward
        expect(AdReward.noReward) == .noReward
        expect(AdReward.unsupportedReward) == .unsupportedReward
        expect(AdReward.noReward.virtualCurrency).to(beNil())
        expect(AdReward.unsupportedReward.virtualCurrency).to(beNil())
    }

    func testEqualityRequiresMatchingVirtualCurrencyPayload() throws {
        let one = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let two = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 6))
        expect(AdReward.virtualCurrency(one)) == AdReward.virtualCurrency(one)
        expect(AdReward.virtualCurrency(one)) != AdReward.virtualCurrency(two)
        expect(AdReward.virtualCurrency(one)) != AdReward.noReward
        expect(AdReward.virtualCurrency(one)) != AdReward.unsupportedReward
    }

    func testKindRawValuesAreStable() {
        expect(AdReward.virtualCurrency(code: "x", amount: 1).kindRawValue) == "virtual_currency"
        expect(AdReward.noReward.kindRawValue) == "no_reward"
        expect(AdReward.unsupportedReward.kindRawValue) == "unsupported_reward"
    }

}
