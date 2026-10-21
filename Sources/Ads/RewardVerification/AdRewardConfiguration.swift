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

/// Rewards currently configured for a rewarded ad unit.
///
/// A `nil` result means configuration is unavailable. ``noConfiguredReward`` means configuration loaded successfully,
/// but the ad unit has no configured reward.
///
/// Use the primary configured reward to customize the prompt, falling back to generic copy when configuration is
/// unavailable or no reward is configured:
///
/// ```swift
/// guard let reward = await Purchases.shared.adRewards(forAdUnitId: adUnitID)?.reward else {
///     showPrompt("Watch an ad to continue")
///     return
/// }
///
/// if let currency = reward.virtualCurrency {
///     showPrompt("Watch an ad for \(currency.amount) \(currency.code)")
/// } else if let entitlement = reward.entitlement {
///     showPrompt("Watch an ad for \(format(entitlement.duration)) of access")
/// } else {
///     showPrompt("Watch an ad to continue")
/// }
/// ```
public struct ConfiguredAdRewards: Sendable, Equatable {

    private enum Storage: Sendable, Equatable {
        case rewards(
            reward: AdRewardConfiguration,
            moreRewards: [AdRewardConfiguration]
        )
        case noConfiguredReward
    }

    private let storage: Storage

    /// No RevenueCat reward is configured for this ad unit.
    public static let noConfiguredReward = ConfiguredAdRewards(storage: .noConfiguredReward)

    /// The primary configured reward, or `nil` when this value is ``noConfiguredReward``.
    public var reward: AdRewardConfiguration? {
        guard case let .rewards(reward, _) = self.storage else { return nil }
        return reward
    }

    /// Additional configured rewards granted alongside ``reward``.
    public var moreRewards: [AdRewardConfiguration] {
        guard case let .rewards(_, moreRewards) = self.storage else { return [] }
        return moreRewards
    }

    internal init(
        reward: AdRewardConfiguration,
        moreRewards: [AdRewardConfiguration]
    ) {
        self.storage = .rewards(reward: reward, moreRewards: moreRewards)
    }

    private init(storage: Storage) {
        self.storage = storage
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
    public let duration: TimeInterval

    internal init?(identifier: String, duration: TimeInterval) {
        guard !identifier.isEmpty, duration > 0 else { return nil }
        self.identifier = identifier
        self.duration = duration
    }

}
