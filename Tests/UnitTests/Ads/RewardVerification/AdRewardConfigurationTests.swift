//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdRewardConfigurationTests.swift
//

import Nimble
@testable import RevenueCat
import XCTest

#if ENABLE_CONFIGURED_AD_REWARDS

final class AdRewardConfigurationTests: TestCase {

    func testVirtualCurrencyConfiguration() throws {
        let reward = try XCTUnwrap(VirtualCurrencyRewardConfiguration(code: "coins", amount: 10))
        let configuration = AdRewardConfiguration.virtualCurrency(reward)

        expect(configuration.virtualCurrency) == reward
        expect(configuration.entitlement).to(beNil())
    }

    func testEntitlementConfiguration() throws {
        let duration = try XCTUnwrap(AdRewardDuration(value: 30, unit: .minute))
        let reward = try XCTUnwrap(EntitlementRewardConfiguration(identifier: "pro", duration: duration))
        let configuration = AdRewardConfiguration.entitlement(reward)

        expect(configuration.entitlement) == reward
        expect(configuration.virtualCurrency).to(beNil())
    }

    func testUnsupportedConfiguration() {
        expect(AdRewardConfiguration.unsupportedReward.virtualCurrency).to(beNil())
        expect(AdRewardConfiguration.unsupportedReward.entitlement).to(beNil())
    }

    func testDurationRejectsNonPositiveValues() {
        expect(AdRewardDuration(value: 0, unit: .minute)).to(beNil())
        expect(AdRewardDuration(value: -1, unit: .minute)).to(beNil())
    }

    func testSecondDurationUnitRawValue() {
        expect(AdRewardDuration.Unit.second.rawValue) == "second"
    }

    func testEntitlementConfigurationRejectsEmptyIdentifier() throws {
        let duration = try XCTUnwrap(AdRewardDuration(value: 30, unit: .minute))

        expect(EntitlementRewardConfiguration(identifier: "", duration: duration)).to(beNil())
    }

    func testConfiguredRewardsExposePrimaryAndAdditionalRewards() throws {
        let currency = try XCTUnwrap(VirtualCurrencyRewardConfiguration(code: "coins", amount: 10))
        let duration = try XCTUnwrap(AdRewardDuration(value: 30, unit: .minute))
        let entitlement = try XCTUnwrap(
            EntitlementRewardConfiguration(identifier: "pro", duration: duration)
        )
        let configured = ConfiguredAdRewards(
            configuredReward: .virtualCurrency(currency),
            moreRewards: [.entitlement(entitlement)]
        )

        expect(configured.configuredReward.virtualCurrency) == currency
        expect(configured.moreRewards) == [.entitlement(entitlement)]
    }

}

#endif
