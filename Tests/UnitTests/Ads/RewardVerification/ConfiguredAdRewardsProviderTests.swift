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
                ["type": "entitlement", "identifier": "premium", "duration_in_seconds": .int(30 * 60)],
                ["type": "virtual_currency", "code": "gems", "amount": 2]
            ]
        ])

        let maybeRewards = await self.provider.rewards(forAdUnitId: "ad-unit")
        let rewards = try XCTUnwrap(maybeRewards)

        expect(rewards.reward?.virtualCurrency?.code) == "coins"
        expect(rewards.reward?.virtualCurrency?.amount) == 10
        expect(rewards.moreRewards[0].entitlement?.identifier) == "premium"
        expect(rewards.moreRewards[0].entitlement?.duration) == 30 * 60
        expect(rewards.moreRewards[1].virtualCurrency?.code) == "gems"
    }

    func testWarmPopulatesCache() async throws {
        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])

        await self.provider.warm()
        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards?.reward?.virtualCurrency?.amount) == 10
        expect(self.manager.invokedTopicCount) == 0
        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
        expect(self.manager.invokedCachedBlobDataParameters.count) == 1
    }

    func testObserverRegistrationWarmsFromCacheWithoutFetching() async throws {
        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])

        self.provider.remoteConfigEventReceived(.observerRegistered(generation: self.manager.configGeneration))

        await expect(self.manager.invokedCachedBlobDataParameters.count).toEventually(equal(1))
        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards?.reward?.virtualCurrency?.amount) == 10
        expect(self.manager.invokedTopicCount) == 0
        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
    }

    func testCommitWaitsForInFlightRefreshWithoutStartingAnotherRefresh() async throws {
        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])

        self.provider.remoteConfigEventReceived(.committed(generation: self.manager.configGeneration))

        await expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount).toEventually(equal(1))
        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards?.reward?.virtualCurrency?.amount) == 10
        expect(self.manager.invokedTopicCount) == 0
    }

    func testAsyncRewardsReturnsCachedValueWithoutWaitingForRefresh() async throws {
        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])
        await self.provider.warm()

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards?.reward?.virtualCurrency?.amount) == 10
        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
    }

    func testAsyncRewardsFetchesConfigurationWhenCacheIsEmpty() async throws {
        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards?.reward?.virtualCurrency?.amount) == 10
        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
        expect(self.manager.invokedTopicCount) == 2
        expect(self.manager.invokedEnsureBlobsDownloadedRefs) == [[String(repeating: "A", count: 32)]]
        expect(self.manager.invokedBlobDataParameters.count) == 1
    }

    func testAsyncRewardsWaitsForFetchWhenInitialConfigurationHasNotStarted() async throws {
        self.manager.stubbedHasCommittedConfig = false
        self.manager.shouldStoreTopicCompletion = true

        async let rewards = self.provider.rewards(forAdUnitId: "ad-unit")
        await expect(self.manager.invokedTopicCount).toEventually(equal(1))

        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
        ])
        self.manager.stubbedHasCommittedConfig = true
        let topic = try XCTUnwrap(self.manager.stubbedTopics[.adRewards])
        self.manager.completeStoredTopic(with: topic)

        let resolvedRewards = await rewards
        expect(resolvedRewards?.reward?.virtualCurrency?.amount) == 10
    }

    func testAsyncRewardsReturnsNilWhenConfigurationRemainsUnavailable() async {
        self.manager.stubbedHasCommittedConfig = false

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards).to(beNil())
        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
        expect(self.manager.invokedTopicCount) == 1
        expect(self.manager.invokedEnsureBlobsDownloadedRefs).to(beEmpty())
    }

    func testAsyncRewardsWithEmptyAdUnitIdentifierDoesNotFetchConfiguration() async {
        let rewards = await self.provider.rewards(forAdUnitId: "")

        expect(rewards).to(beNil())
        expect(self.manager.invokedCommittedTopicAfterInFlightRefreshCount) == 0
        expect(self.manager.invokedTopicCount) == 0
    }

    func testReturnsEntitlementDurationInSeconds() async throws {
        try self.stub(content: [
            "reward": [
                "type": "entitlement",
                "identifier": "premium",
                "duration_in_seconds": .int(90)
            ]
        ])

        await self.provider.warm()
        let maybeReward = await self.provider.rewards(forAdUnitId: "ad-unit")
        let reward = try XCTUnwrap(maybeReward)

        expect(reward.reward?.entitlement?.duration) == 90
    }

    func testUnsupportedIndividualRewardsArePreserved() async throws {
        try self.stub(content: [
            "reward": ["type": "future_reward"],
            "more_rewards": [
                ["type": "entitlement", "identifier": "premium", "duration_in_seconds": .int(0)],
                ["type": "virtual_currency", "code": "coins", "amount": 0]
            ]
        ])

        let maybeRewards = await self.provider.rewards(forAdUnitId: "ad-unit")
        let rewards = try XCTUnwrap(maybeRewards)

        expect(rewards.reward) == .unsupportedReward
        expect(rewards.moreRewards) == [.unsupportedReward, .unsupportedReward]
    }

    func testReturnsNilForMalformedAdUnitWithoutReloadingConfiguration() async throws {
        try self.stub(content: [
            "reward": ["type": "virtual_currency", "code": "coins", "amount": 10],
            "more_rewards": ["not": "an array"]
        ])

        let firstRewards = await self.provider.rewards(forAdUnitId: "ad-unit")
        let topicReadCount = self.manager.invokedTopicCount
        let blobReadCount = self.manager.invokedBlobDataParameters.count
        let blobDownloadCount = self.manager.invokedEnsureBlobsDownloadedRefs.count
        let secondRewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(firstRewards).to(beNil())
        expect(secondRewards).to(beNil())
        expect(self.manager.invokedTopicCount) == topicReadCount
        expect(self.manager.invokedBlobDataParameters.count) == blobReadCount
        expect(self.manager.invokedEnsureBlobsDownloadedRefs.count) == blobDownloadCount
    }

    func testMalformedAdUnitDoesNotHideValidAdUnits() async throws {
        try self.stub(adUnits: [
            "valid-ad-unit": [
                "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
            ],
            "malformed-ad-unit": [
                "reward": ["type": "virtual_currency", "code": "gems", "amount": 5],
                "more_rewards": ["not": "an array"]
            ]
        ])

        await self.provider.warm()

        let validRewards = await self.provider.rewards(forAdUnitId: "valid-ad-unit")
        let malformedRewards = await self.provider.rewards(forAdUnitId: "malformed-ad-unit")
        let absentRewards = await self.provider.rewards(forAdUnitId: "absent-ad-unit")

        expect(validRewards?.reward?.virtualCurrency?.amount) == 10
        expect(malformedRewards).to(beNil())
        expect(absentRewards) == .noConfiguredReward
    }

    func testUsesExactAdUnitIdentifierLookup() async throws {
        try self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])

        let rewards = await self.provider.rewards(forAdUnitId: "AD-UNIT")

        expect(rewards) == .noConfiguredReward
        expect(self.manager.invokedCachedBlobDataParameters.last?.topic) == .adRewards
        expect(self.manager.invokedCachedBlobDataParameters.last?.itemKey) == "default"
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

        expect(initial?.reward?.virtualCurrency?.amount) == 10
        expect(cached) == initial
    }

    func testIdentityBoundGenerationChangePreservesAppScopedCachedConfiguration() async throws {
        try self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])
        await self.provider.warm()

        // RemoteConfigManager advances its generation when identity-bound config is cleared. Ad rewards are app-scoped,
        // so the last valid rewards remain usable while the replacement configuration is unavailable.
        self.manager.configGeneration += 1
        self.manager.stubbedHasCommittedConfig = false
        self.manager.stubbedTopics[.adRewards] = nil
        await self.provider.warm()
        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards?.reward?.virtualCurrency?.amount) == 10
    }

    func testInvalidReplacementBlobPreservesCachedConfiguration() async throws {
        try self.stub(adUnits: [
            "malformed-replacement": [
                "reward": ["type": "virtual_currency", "code": "coins", "amount": 10]
            ],
            "valid-replacement": [
                "reward": ["type": "virtual_currency", "code": "gems", "amount": 5]
            ]
        ])
        await self.provider.warm()

        self.manager.configGeneration += 1
        try self.stub(adUnits: [
            "malformed-replacement": [
                "reward": ["type": "virtual_currency", "code": "coins", "amount": 20],
                "more_rewards": ["not": "an array"]
            ],
            "valid-replacement": [
                "reward": ["type": "virtual_currency", "code": "gems", "amount": 15]
            ]
        ])
        await self.provider.warm()
        let malformedRewards = await self.provider.rewards(forAdUnitId: "malformed-replacement")
        let validRewards = await self.provider.rewards(forAdUnitId: "valid-replacement")

        expect(malformedRewards?.reward?.virtualCurrency?.amount) == 10
        expect(validRewards?.reward?.virtualCurrency?.amount) == 15
    }

    func testTopicRemovalClearsCachedConfiguration() async throws {
        try self.stub(content: ["reward": ["type": "virtual_currency", "code": "coins", "amount": 10]])
        let initial = await self.provider.rewards(forAdUnitId: "ad-unit")
        expect(initial).toNot(beNil())

        self.manager.configGeneration += 1
        self.manager.stubbedTopics[.adRewards] = nil
        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards) == .noConfiguredReward
    }

    func testMissingPrimaryRewardReturnsNoConfiguredReward() async throws {
        try self.stub(content: ["more_rewards": []])

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards) == .noConfiguredReward
    }

    func testExplicitNullAndNoRewardAreNotUnsupportedRewards() async throws {
        for primary: AnyDecodable in [.null, ["type": "no_reward"]] {
            try self.stub(content: ["reward": primary])

            let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

            expect(rewards) == .noConfiguredReward
        }
    }

    func testAdditionalRewardsWithoutPrimaryRewardAreUnavailable() async throws {
        try self.stub(content: [
            "more_rewards": [
                ["type": "virtual_currency", "code": "coins", "amount": 10]
            ]
        ])

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards).to(beNil())
    }

    func testAbsentTopicInCommittedConfigReturnsNoConfiguredReward() async {
        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards) == .noConfiguredReward
    }

    func testUnavailableConfigReturnsNilRatherThanEmptyConfiguration() async {
        self.manager.stubbedHasCommittedConfig = false

        let rewards = await self.provider.rewards(forAdUnitId: "ad-unit")

        expect(rewards).to(beNil())
    }

    private func stub(content: [String: AnyDecodable], adUnitId: String = "ad-unit") throws {
        try self.stub(adUnits: [adUnitId: content])
    }

    private func stub(adUnits: [String: [String: AnyDecodable]]) throws {
        self.manager.stubbedTopics[.adRewards] = [
            "default": RemoteConfiguration.ConfigItem(blobRef: String(repeating: "A", count: 32), prefetch: true)
        ]
        self.manager.stubbedBlobData[.adRewards] = [
            "default": try JSONEncoder.default.encode(adUnits.mapValues(AnyDecodable.object))
        ]
    }

}
