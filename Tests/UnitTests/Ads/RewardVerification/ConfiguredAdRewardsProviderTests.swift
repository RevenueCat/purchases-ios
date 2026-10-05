//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConfiguredAdRewardsProviderTests.swift
//

import Nimble
@testable import RevenueCat
import XCTest

#if ENABLE_CONFIGURED_AD_REWARDS

final class ConfiguredAdRewardsProviderTests: TestCase {

    private var manager: MockRemoteConfigManager!
    private var provider: ConfiguredAdRewardsProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.manager = MockRemoteConfigManager()
        self.provider = ConfiguredAdRewardsProvider(manager: self.manager)
    }

    func testReturnsConfiguredRewardsInWireOrder() async throws {
        self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10],
            "more_rewards": [
                ["type": "entitlement", "identifier": "premium", "duration": "PT30M"],
                ["type": "virtual_currency", "code": "gems", "amount": 2]
            ]
        ])

        let maybeRewards = await self.provider.rewards(forAdUnitId: "ad-unit")
        let rewards = try XCTUnwrap(maybeRewards)

        expect(rewards.configuredReward.virtualCurrency?.code) == "coins"
        expect(rewards.configuredReward.virtualCurrency?.amount) == 10
        expect(rewards.moreRewards[0].entitlement?.identifier) == "premium"
        expect(rewards.moreRewards[0].entitlement?.duration) == AdRewardDuration(value: 30, unit: .minute)
        expect(rewards.moreRewards[1].virtualCurrency?.code) == "gems"
    }

    func testSupportsEachDurationUnitWithoutNormalization() async throws {
        let cases: [(String, Int, AdRewardDuration.Unit)] = [
            ("PT60M", 60, .minute),
            ("PT2H", 2, .hour),
            ("P3D", 3, .day),
            ("P4W", 4, .week),
            ("P5M", 5, .month),
            ("P6Y", 6, .year)
        ]

        for (rawDuration, value, unit) in cases {
            self.stub(content: [
                "reward": [
                    "type": "entitlement",
                    "identifier": "premium",
                    "duration": .string(rawDuration)
                ]
            ])

            let maybeReward = await self.provider.rewards(forAdUnitId: "ad-unit")
            let reward = try XCTUnwrap(maybeReward)
            expect(reward.configuredReward.entitlement?.duration) == AdRewardDuration(value: value, unit: unit)
        }
    }

    func testUnsupportedIndividualRewardsArePreserved() async throws {
        self.stub(content: [
            "reward": ["type": "future_reward"],
            "more_rewards": [
                ["type": "entitlement", "identifier": "premium", "duration": "PT30S"],
                ["type": "virtual_currency", "code": "coins", "amount": 0]
            ]
        ])

        let maybeRewards = await self.provider.rewards(forAdUnitId: "ad-unit")
        let rewards = try XCTUnwrap(maybeRewards)

        expect(rewards.configuredReward) == .unsupportedReward
        expect(rewards.moreRewards) == [.unsupportedReward, .unsupportedReward]
    }

    func testReturnsNilForMalformedOuterPayload() async {
        self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10],
            "more_rewards": ["not": "an array"]
        ])

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards).to(beNil())
    }

    func testUsesExactAdUnitIdentifierLookup() async {
        self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])

        let rewards = await self.provider.rewards(forAdUnitId: "AD-UNIT")

        expect(rewards).to(beNil())
        expect(self.manager.invokedConfigItemParameters.last?.topic) == .adRewards
        expect(self.manager.invokedConfigItemParameters.last?.itemKey) == "AD-UNIT"
    }

    func testEmptyAdUnitIdentifierReturnsNilWithoutReadingConfig() async {
        let rewards = await self.provider.rewards(forAdUnitId: "")

        expect(rewards).to(beNil())
        expect(self.manager.invokedConfigItemParameters).to(beEmpty())
    }

    private func stub(content: [String: AnyDecodable], adUnitId: String = "ad-unit") {
        self.manager.stubbedTopics[.adRewards] = [
            adUnitId: RemoteConfiguration.ConfigItem(content: content)
        ]
    }

}

#endif
