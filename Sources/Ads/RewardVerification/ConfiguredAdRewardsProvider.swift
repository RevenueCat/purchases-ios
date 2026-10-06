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

#if ENABLE_CONFIGURED_AD_REWARDS

final class ConfiguredAdRewardsProvider {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func rewards(forAdUnitId adUnitId: String) async -> ConfiguredAdRewards? {
        guard !adUnitId.isEmpty else {
            Logger.warn(AdsStrings.configured_ad_rewards_empty_ad_unit_id)
            return nil
        }

        guard let item = await self.manager.configItem(for: .adRewards, itemKey: adUnitId) else {
            if !(await self.manager.hasCommittedConfig()) {
                Logger.warn(AdsStrings.configured_ad_rewards_unavailable(adUnitID: adUnitId))
            }
            return nil
        }

        return Self.decode(item.content, adUnitId: adUnitId)
    }

    private static func decode(
        _ content: [String: AnyDecodable],
        adUnitId: String
    ) -> ConfiguredAdRewards? {
        guard let reward = content["reward"] else {
            Logger.warn(AdsStrings.configured_ad_rewards_invalid_payload(adUnitID: adUnitId))
            return nil
        }

        let moreRewards: [AnyDecodable]
        switch content["more_rewards"] {
        case nil:
            moreRewards = []
        case let .array(rewards):
            moreRewards = rewards
        default:
            Logger.warn(AdsStrings.configured_ad_rewards_invalid_payload(adUnitID: adUnitId))
            return nil
        }

        return ConfiguredAdRewards(
            configuredReward: Self.decodeReward(reward, adUnitId: adUnitId),
            moreRewards: moreRewards.map { Self.decodeReward($0, adUnitId: adUnitId) }
        )
    }

    private static func decodeReward(
        _ reward: AnyDecodable,
        adUnitId: String
    ) -> AdRewardConfiguration {
        guard case let .object(payload) = reward,
              case let .string(type)? = payload["type"] else {
            Logger.warn(AdsStrings.configured_ad_rewards_invalid_payload(adUnitID: adUnitId))
            return .unsupportedReward
        }

        switch type {
        case AdReward.Kind.virtualCurrency:
            guard case let .string(code)? = payload["code"],
                  case let .int(amount)? = payload["amount"],
                  let reward = VirtualCurrencyRewardConfiguration(code: code, amount: amount) else {
                Logger.warn(AdsStrings.configured_ad_rewards_invalid_payload(adUnitID: adUnitId))
                return .unsupportedReward
            }
            return .virtualCurrency(reward)

        case AdReward.Kind.entitlement:
            guard case let .string(identifier)? = payload["identifier"],
                  case let .string(rawDuration)? = payload["duration"],
                  let duration = Self.decodeDuration(rawDuration),
                  let reward = EntitlementRewardConfiguration(identifier: identifier, duration: duration) else {
                Logger.warn(AdsStrings.configured_ad_rewards_invalid_payload(adUnitID: adUnitId))
                return .unsupportedReward
            }
            return .entitlement(reward)

        default:
            Logger.warn(AdsStrings.unknown_reward_kind(rawValue: type))
            return .unsupportedReward
        }
    }

    private static func decodeDuration(_ rawValue: String) -> AdRewardDuration? {
        guard rawValue.range(
            of: #"^P(?:[1-9]\d*Y|[1-9]\d*M|[1-9]\d*W|[1-9]\d*D|T(?:[1-9]\d*H|[1-9]\d*M))$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil,
              let duration = ISODurationFormatter.parse(from: rawValue) else {
            return nil
        }

        let components: [(Int, AdRewardDuration.Unit)] = [
            (duration.years, .year),
            (duration.months, .month),
            (duration.weeks, .week),
            (duration.days, .day),
            (duration.hours, .hour),
            (duration.minutes, .minute)
        ]
        guard let component = components.first(where: { $0.0 > 0 }) else { return nil }
        return AdRewardDuration(value: component.0, unit: component.1)
    }

}

#endif
