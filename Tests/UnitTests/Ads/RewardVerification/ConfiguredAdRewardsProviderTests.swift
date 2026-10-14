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

final class ConfiguredAdRewardsProviderTests: TestCase {

    private var manager: MockRemoteConfigManager!
    private var provider: ConfiguredAdRewardsProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.manager = MockRemoteConfigManager()
        self.provider = ConfiguredAdRewardsProvider(manager: self.manager)
    }

    func testReturnsConfiguredRewardsInWireOrder() async throws {
        try self.stub(content: [
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
            ("PT30S", 30, .second),
            ("PT60M", 60, .minute),
            ("PT2H", 2, .hour),
            ("P3D", 3, .day),
            ("P4W", 4, .week),
            ("P5M", 5, .month),
            ("P6Y", 6, .year)
        ]

        for (rawDuration, value, unit) in cases {
            try self.stub(content: [
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
        try self.stub(content: [
            "reward": ["type": "future_reward"],
            "more_rewards": [
                ["type": "entitlement", "identifier": "premium", "duration": "PT0S"],
                ["type": "virtual_currency", "code": "coins", "amount": 0]
            ]
        ])

        let maybeRewards = await self.provider.rewards(forAdUnitId: "ad-unit")
        let rewards = try XCTUnwrap(maybeRewards)

        expect(rewards.configuredReward) == .unsupportedReward
        expect(rewards.moreRewards) == [.unsupportedReward, .unsupportedReward]
    }

    func testReturnsNilForMalformedOuterPayload() async throws {
        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10],
            "more_rewards": ["not": "an array"]
        ])

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards).to(beNil())
    }

    func testUsesExactAdUnitIdentifierLookup() async throws {
        try self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])

        let rewards = await self.provider.rewards(forAdUnitId: "AD-UNIT")

        expect(rewards).to(beNil())
        expect(self.manager.invokedBlobDataParameters.last?.topic) == .adRewards
        expect(self.manager.invokedBlobDataParameters.last?.itemKey) == "default"
    }

    func testEmptyAdUnitIdentifierReturnsNilWithoutReadingConfig() async {
        let rewards = await self.provider.rewards(forAdUnitId: "")

        expect(rewards).to(beNil())
        expect(self.manager.invokedTopicCount) == 0
        expect(self.manager.invokedBlobDataParameters).to(beEmpty())
    }

    func testTemporarilyUnavailableBlobPreservesCachedConfiguration() async throws {
        try self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])
        let initial = await self.provider.rewards(forAdUnitId: "ad-unit")

        self.manager.configGeneration += 1
        self.manager.stubbedBlobData[.adRewards] = [:]
        let cached = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(initial?.configuredReward.virtualCurrency?.amount) == 10
        expect(cached) == initial
    }

    func testInvalidReplacementBlobPreservesCachedConfiguration() async throws {
        try self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])
        let initial = await self.provider.rewards(forAdUnitId: "ad-unit")

        self.manager.configGeneration += 1
        self.manager.stubbedBlobData[.adRewards]?["default"] = #"{"ad-unit":{"more_rewards":[]}}"#.asData
        let cached = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(initial?.configuredReward.virtualCurrency?.amount) == 10
        expect(cached) == initial
    }

    func testTopicRemovalClearsCachedConfiguration() async throws {
        try self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])
        let initial = await self.provider.rewards(forAdUnitId: "ad-unit")
        expect(initial).toNot(beNil())

        self.manager.configGeneration += 1
        self.manager.stubbedTopics[.adRewards] = nil
        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards).to(beNil())
    }

    private func stub(content: [String: AnyDecodable], adUnitId: String = "ad-unit") throws {
        self.manager.stubbedTopics[.adRewards] = [
            "default": RemoteConfiguration.ConfigItem(blobRef: String(repeating: "A", count: 32), prefetch: true)
        ]
        self.manager.stubbedBlobData[.adRewards] = [
            "default": try JSONEncoder.default.encode([adUnitId: AnyDecodable.object(content)])
        ]
    }

}
