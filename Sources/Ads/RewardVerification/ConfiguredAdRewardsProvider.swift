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

final class ConfiguredAdRewardsProvider {

    private enum AdUnitRewards {
        case available(ConfiguredAdRewards)
        case unavailable
    }

    private typealias RewardsByAdUnitID = [String: AdUnitRewards]

    private enum Resolution {
        case available(RewardsByAdUnitID)
        case removed
        case unavailable
    }

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func rewards(forAdUnitId adUnitId: String) async -> ConfiguredAdRewards? {
        guard !adUnitId.isEmpty else {
            Logger.warn(AdsStrings.configured_ad_rewards_empty_ad_unit_id)
            return nil
        }

        let resolution: Resolution
        do {
            resolution = try await self.manager.readConsistent {
                return await self.resolveConfiguration()
            } ?? .unavailable
        } catch {
            resolution = .unavailable
        }

        switch resolution {
        case let .available(rewards):
            guard let adUnitRewards = rewards[adUnitId] else {
                return .noConfiguredReward
            }

            switch adUnitRewards {
            case let .available(rewards):
                return rewards
            case .unavailable:
                Logger.warn(AdsStrings.configured_ad_rewards_invalid_ad_unit(adUnitID: adUnitId))
                return nil
            }
        case .removed:
            return .noConfiguredReward
        case .unavailable:
            Logger.warn(AdsStrings.configured_ad_rewards_unavailable(adUnitID: adUnitId))
            return nil
        }
    }

    private func resolveConfiguration() async -> Resolution {
        let topic = await self.manager.awaitTopicAndPrefetchBlobsReady(.adRewards)
        guard let topic else {
            return await self.manager.hasCommittedConfig() ? .removed : .unavailable
        }

        guard topic[Self.blobItemKey]?.blobRef != nil else {
            return .unavailable
        }

        let data = await self.manager.blobData(
            for: .adRewards,
            itemKey: Self.blobItemKey
        )
        guard let data else { return .unavailable }

        do {
            return .available(try Self.decodeConfiguration(data))
        } catch {
            Logger.warn(AdsStrings.configured_ad_rewards_invalid_blob(error: error))
            return .unavailable
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

        let decodedMoreRewards = moreRewards.compactMap(Self.decodeReward)
        guard let reward = Self.decodeReward(payload["reward"]) else {
            guard decodedMoreRewards.isEmpty else { return .unavailable }
            return .available(.noConfiguredReward)
        }

        return .available(
            ConfiguredAdRewards(
                reward: reward,
                moreRewards: decodedMoreRewards
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
                  let reward = VirtualCurrencyRewardConfiguration(code: code, amount: amount) else {
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
