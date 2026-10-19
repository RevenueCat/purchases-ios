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

final class AdRewardConfigurationTests: TestCase {

    func testConfiguredRewardsCanRepresentAvailableConfigurationWithoutRewards() {
        let configured = ConfiguredAdRewards()

        expect(configured.reward).to(beNil())
        expect(configured.moreRewards).to(beEmpty())
    }

    func testVirtualCurrencyConfiguration() throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 10))
        let configuration = AdRewardConfiguration.virtualCurrency(reward)

        expect(configuration.virtualCurrency) == reward
        expect(configuration.entitlement).to(beNil())
    }

    func testEntitlementConfiguration() throws {
        let reward = try XCTUnwrap(
            EntitlementRewardConfiguration(identifier: "pro", durationInSeconds: 30 * 60)
        )
        expect(reward.durationInSeconds) == TimeInterval(30 * 60)
        let configuration = AdRewardConfiguration.entitlement(reward)

        expect(configuration.entitlement) == reward
        expect(configuration.virtualCurrency).to(beNil())
    }

    func testUnsupportedConfiguration() {
        expect(AdRewardConfiguration.unsupportedReward.virtualCurrency).to(beNil())
        expect(AdRewardConfiguration.unsupportedReward.entitlement).to(beNil())
    }

    func testEntitlementConfigurationRejectsNonPositiveDurations() {
        expect(EntitlementRewardConfiguration(identifier: "pro", durationInSeconds: 0)).to(beNil())
        expect(EntitlementRewardConfiguration(identifier: "pro", durationInSeconds: -1)).to(beNil())
    }

    func testEntitlementConfigurationRejectsEmptyIdentifier() {
        expect(EntitlementRewardConfiguration(identifier: "", durationInSeconds: 30 * 60)).to(beNil())
    }

    func testConfiguredRewardsExposePrimaryAndAdditionalRewards() throws {
        let currency = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 10))
        let entitlement = try XCTUnwrap(
            EntitlementRewardConfiguration(identifier: "pro", durationInSeconds: 30 * 60)
        )
        let configured = ConfiguredAdRewards(
            reward: .virtualCurrency(currency),
            moreRewards: [.entitlement(entitlement)]
        )

        expect(configured.reward?.virtualCurrency) == currency
        expect(configured.moreRewards) == [.entitlement(entitlement)]
    }

}
