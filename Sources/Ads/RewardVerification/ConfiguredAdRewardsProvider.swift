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

    private enum AdUnitRewards {
        case available(ConfiguredAdRewards)
        case unavailable
    }

    private typealias RewardsByAdUnitID = [String: AdUnitRewards]

    private enum ReadMode {
        case cachedOnly
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

    /// `ad_rewards` is app-scoped rather than subscriber-scoped, so this deliberately survives config-generation
    /// changes, including identity-bound cache clears. It keeps the last successfully decoded rewards until a newer
    /// valid configuration is ready, or until the topic is removed.
    private let cachedRewards: Atomic<CachedRewards?> = .init(nil)

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func remoteConfigEventReceived(_ event: RemoteConfigLifecycleEvent) {
        switch event {
        case .observerRegistered:
            Task { [weak self] in
                await self?.warm(mode: .cachedOnly)
            }
        case .committed:
            Task { [weak self] in
                await self?.warm(mode: .waitForInFlight)
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

        await self.warm(mode: .fetchIfNeeded)

        guard let rewards = self.cachedRewardsValue(forAdUnitId: adUnitId) else {
            Logger.warn(AdsStrings.configured_ad_rewards_unavailable(adUnitID: adUnitId))
            return nil
        }

        return rewards
    }

    func warm() async {
        await self.warm(mode: .cachedOnly)
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
        case .cachedOnly:
            topic = await self.manager.topic(.adRewards, policy: .cachedOnly)
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
        case .cachedOnly:
            data = await self.manager.blobData(
                for: .adRewards,
                itemKey: Self.blobItemKey,
                policy: .cachedOnly
            )
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
        guard let rewards = cached.rewards,
              let adUnitRewards = rewards[adUnitId] else {
            return .noConfiguredReward
        }

        switch adUnitRewards {
        case let .available(rewards):
            return rewards
        case .unavailable:
            return nil
        }
    }

    private func updateCache(with resolution: Resolution) {
        switch resolution {
        case let .available(generation, rewards):
            self.cachedRewards.modify { cached in
                guard generation >= (cached?.generation ?? Int.min) else { return }

                var updatedRewards = rewards
                for (adUnitID, adUnitRewards) in rewards {
                    guard case .unavailable = adUnitRewards,
                          case let .available(cachedAdUnitRewards)? = cached?.rewards?[adUnitID] else {
                        continue
                    }

                    updatedRewards[adUnitID] = .available(cachedAdUnitRewards)
                }

                cached = .init(generation: generation, rewards: updatedRewards)
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
        let payload = try JSONDecoder.default.decode([String: AnyDecodable].self, from: data)
        return payload.mapValues(Self.decodeAdUnitRewards)
    }

    private static func decodeAdUnitRewards(_ value: AnyDecodable) -> AdUnitRewards {
        guard case let .object(payload) = value else { return .unavailable }

        let moreRewards: [AnyDecodable]
        switch payload["more_rewards"] {
        case .none, .some(.null):
            moreRewards = []
        case let .some(.array(rewards)):
            moreRewards = rewards
        default:
            return .unavailable
        }

        guard let reward = Self.decodeReward(payload["reward"]) else {
            guard moreRewards.isEmpty else { return .unavailable }
            return .available(.noConfiguredReward)
        }

        return .available(
            ConfiguredAdRewards(
                reward: reward,
                moreRewards: moreRewards.compactMap(Self.decodeReward)
            )
        )
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
                    duration: TimeInterval(durationInSeconds)
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
