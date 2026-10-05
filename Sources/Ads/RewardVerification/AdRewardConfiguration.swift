//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdRewardConfiguration.swift
//

import Foundation

#if ENABLE_CONFIGURED_AD_REWARDS

/// Rewards currently configured for a rewarded ad unit.
public struct ConfiguredAdRewards: Sendable, Equatable {

    /// The primary configured reward.
    public let configuredReward: AdRewardConfiguration

    /// Additional configured rewards granted alongside ``configuredReward``.
    public let moreRewards: [AdRewardConfiguration]

    internal init(
        configuredReward: AdRewardConfiguration,
        moreRewards: [AdRewardConfiguration] = []
    ) {
        self.configuredReward = configuredReward
        self.moreRewards = moreRewards
    }

}

/// A reward currently configured for a rewarded ad unit.
///
/// Inspect the reward by checking ``virtualCurrency`` or ``entitlement``. A reward shape that the
/// SDK does not currently model is represented by ``unsupportedReward``.
public struct AdRewardConfiguration: Sendable, Equatable {

    private enum Storage: Sendable, Equatable {
        case virtualCurrency(VirtualCurrencyRewardConfiguration)
        case entitlement(EntitlementRewardConfiguration)
        case unsupportedReward
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// The configured virtual-currency reward, if present.
    public var virtualCurrency: VirtualCurrencyRewardConfiguration? {
        guard case .virtualCurrency(let reward) = self.storage else { return nil }
        return reward
    }

    /// The configured entitlement reward, if present.
    public var entitlement: EntitlementRewardConfiguration? {
        guard case .entitlement(let reward) = self.storage else { return nil }
        return reward
    }

    /// A configured reward shape that the SDK does not currently model.
    public static let unsupportedReward = AdRewardConfiguration(storage: .unsupportedReward)

    internal static func virtualCurrency(_ reward: VirtualCurrencyRewardConfiguration) -> Self {
        return .init(storage: .virtualCurrency(reward))
    }

    internal static func entitlement(_ reward: EntitlementRewardConfiguration) -> Self {
        return .init(storage: .entitlement(reward))
    }

}

/// A virtual-currency reward currently configured for a rewarded ad unit.
public struct VirtualCurrencyRewardConfiguration: Sendable, Equatable {

    /// The reward type identifier (e.g. `"coins"`, `"gems"`).
    public let code: String

    /// The configured reward amount.
    public let amount: Int

    internal init?(code: String, amount: Int) {
        guard !code.isEmpty, amount > 0 else { return nil }
        self.code = code
        self.amount = amount
    }

}

/// An entitlement reward currently configured for a rewarded ad unit.
public struct EntitlementRewardConfiguration: Sendable, Equatable {

    /// The entitlement identifier.
    public let identifier: String

    /// The duration for which the entitlement will be granted.
    public let duration: AdRewardDuration

    internal init?(identifier: String, duration: AdRewardDuration) {
        guard !identifier.isEmpty else { return nil }
        self.identifier = identifier
        self.duration = duration
    }

}

/// A configured rewarded-ad entitlement duration.
public struct AdRewardDuration: Sendable, Equatable {

    /// The number of duration units.
    public let value: Int

    /// The unit in which the duration is expressed.
    public let unit: Unit

    internal init?(value: Int, unit: Unit) {
        guard value > 0 else { return nil }
        self.value = value
        self.unit = unit
    }

    /// A unit used to express a configured rewarded-ad entitlement duration.
    public struct Unit: Sendable, Equatable, Hashable {

        /// The raw string representation of this unit.
        public let rawValue: String

        /// A duration expressed in minutes.
        public static let minute = Unit(rawValue: "minute")

        /// A duration expressed in hours.
        public static let hour = Unit(rawValue: "hour")

        /// A duration expressed in days.
        public static let day = Unit(rawValue: "day")

        /// A duration expressed in weeks.
        public static let week = Unit(rawValue: "week")

        /// A duration expressed in months.
        public static let month = Unit(rawValue: "month")

        /// A duration expressed in years.
        public static let year = Unit(rawValue: "year")

        internal init(rawValue: String) {
            self.rawValue = rawValue
        }

    }

}

#endif
