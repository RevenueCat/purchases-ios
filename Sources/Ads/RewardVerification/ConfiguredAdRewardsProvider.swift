//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConfiguredAdRewardsProvider.swift
//

import Foundation

final class ConfiguredAdRewardsProvider: RemoteConfigLifecycleObserver {

    private typealias RewardsByAdUnitID = [String: ConfiguredAdRewards]

    private enum ReadMode {
        case fetchIfNeeded
        case waitForInFlight
    }

    private enum Resolution {
        case available(generation: Int, rewards: RewardsByAdUnitID)
        case removed(generation: Int)
        case unavailable
    }

    private struct CachedRewards {
        let generation: Int
        let rewards: RewardsByAdUnitID?
    }

    private let manager: RemoteConfigManagerType

    /// Keeps the last successfully decoded rewards until a newer valid configuration is ready,
    /// or until the topic is removed.
    private let cachedRewards: Atomic<CachedRewards?> = .init(nil)

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func remoteConfigEventReceived(_ event: RemoteConfigLifecycleEvent) {
        switch event {
        case .observerRegistered, .committed:
            Task { [weak self] in
                await self?.warm()
            }
        case .refreshFinished:
            break
        }
    }

    func cachedRewards(forAdUnitId adUnitId: String) -> ConfiguredAdRewards? {
        guard !adUnitId.isEmpty else {
            Logger.warn(AdsStrings.configured_ad_rewards_empty_ad_unit_id)
            return nil
        }

        guard let rewards = self.cachedRewardsValue(forAdUnitId: adUnitId) else {
            Logger.warn(AdsStrings.configured_ad_rewards_unavailable(adUnitID: adUnitId))
            return nil
        }

        return rewards
    }

    func rewards(forAdUnitId adUnitId: String) async -> ConfiguredAdRewards? {
        guard !adUnitId.isEmpty else {
            Logger.warn(AdsStrings.configured_ad_rewards_empty_ad_unit_id)
            return nil
        }

        if let rewards = self.cachedRewardsValue(forAdUnitId: adUnitId) {
            return rewards
        }

        await self.warm(mode: .waitForInFlight)

        guard let rewards = self.cachedRewardsValue(forAdUnitId: adUnitId) else {
            Logger.warn(AdsStrings.configured_ad_rewards_unavailable(adUnitID: adUnitId))
            return nil
        }

        return rewards
    }

    func warm() async {
        await self.warm(mode: .fetchIfNeeded)
    }

    private func warm(mode: ReadMode) async {
        let resolution: Resolution
        do {
            resolution = try await self.manager.readConsistent {
                return await self.resolveConfiguration(mode: mode)
            } ?? .unavailable
        } catch {
            resolution = .unavailable
        }

        self.updateCache(with: resolution)
    }

    private func resolveConfiguration(mode: ReadMode) async -> Resolution {
        let generation = self.manager.configGeneration
        let topic: RemoteConfiguration.ConfigTopic?
        switch mode {
        case .fetchIfNeeded:
            topic = await self.manager.awaitTopicAndPrefetchBlobsReady(.adRewards)
        case .waitForInFlight:
            topic = await self.manager.committedTopicAfterInFlightRefresh(.adRewards)
        }

        guard let topic else {
            return await self.manager.hasCommittedConfig() ? .removed(generation: generation) : .unavailable
        }

        guard let blobRef = topic[Self.blobItemKey]?.blobRef else {
            return .unavailable
        }

        let data: Data?
        switch mode {
        case .fetchIfNeeded:
            data = await self.manager.blobData(for: .adRewards, itemKey: Self.blobItemKey)
        case .waitForInFlight:
            _ = await self.manager.ensureBlobsDownloaded([blobRef])
            data = await self.manager.blobData(
                for: .adRewards,
                itemKey: Self.blobItemKey,
                policy: .cachedOnly
            )
        }

        guard let data else { return .unavailable }

        do {
            return .available(
                generation: generation,
                rewards: try Self.decodeConfiguration(data)
            )
        } catch {
            Logger.warn(AdsStrings.configured_ad_rewards_invalid_blob(error: error))
            return .unavailable
        }
    }

    private func cachedRewardsValue(forAdUnitId adUnitId: String) -> ConfiguredAdRewards? {
        guard let cached = self.cachedRewards.value else { return nil }
        return cached.rewards?[adUnitId] ?? ConfiguredAdRewards(reward: nil, moreRewards: [])
    }

    private func updateCache(with resolution: Resolution) {
        switch resolution {
        case let .available(generation, rewards):
            self.cachedRewards.modify { cached in
                guard generation >= (cached?.generation ?? Int.min) else { return }
                cached = .init(generation: generation, rewards: rewards)
            }
        case let .removed(generation):
            self.cachedRewards.modify { cached in
                guard generation >= (cached?.generation ?? Int.min) else { return }
                cached = .init(generation: generation, rewards: nil)
            }
        case .unavailable:
            break
        }
    }

    private static func decodeConfiguration(_ data: Data) throws -> RewardsByAdUnitID {
        let payload = try JSONDecoder.default.decode([String: WireConfiguredAdRewards].self, from: data)
        return payload.mapValues { rewards in
            ConfiguredAdRewards(
                reward: Self.decodeReward(rewards.reward),
                moreRewards: (rewards.moreRewards ?? []).compactMap(Self.decodeReward)
            )
        }
    }

    private static func decodeReward(_ reward: AnyDecodable?) -> AdRewardConfiguration? {
        guard let reward else { return nil }
        if case .null = reward { return nil }
        guard case let .object(payload) = reward,
              case let .string(type)? = payload["type"] else {
            return .unsupportedReward
        }

        switch type {
        case AdReward.Kind.noReward:
            return nil

        case AdReward.Kind.virtualCurrency:
            guard case let .string(code)? = payload["code"],
                  case let .int(amount)? = payload["amount"],
                  let reward = VirtualCurrencyReward(code: code, amount: amount) else {
                return .unsupportedReward
            }
            return .virtualCurrency(reward)

        case AdReward.Kind.entitlement:
            guard case let .string(identifier)? = payload["identifier"],
                  case let .int(durationInSeconds)? = payload["duration_in_seconds"],
                  let reward = EntitlementRewardConfiguration(
                    identifier: identifier,
                    durationInSeconds: TimeInterval(durationInSeconds)
                  ) else {
                return .unsupportedReward
            }
            return .entitlement(reward)

        default:
            Logger.warn(AdsStrings.unknown_reward_kind(rawValue: type))
            return .unsupportedReward
        }
    }

    private static let blobItemKey = "default"

}

extension ConfiguredAdRewardsProvider: @unchecked Sendable {}

private struct WireConfiguredAdRewards: Decodable {

    let reward: AnyDecodable?
    let moreRewards: [AnyDecodable]?

}
