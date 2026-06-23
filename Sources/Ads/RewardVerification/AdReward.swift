//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdReward.swift
//
//  Created by Pol Miro on 27/05/2026.

import Foundation

/// Reward payload describing the outcome of a verified rewarded ad.
///
/// Inspect the received reward by checking ``virtualCurrency`` / ``entitlement`` or comparing against
/// ``noReward`` / ``unsupportedReward``:
///
/// ```swift
/// if let virtualCurrency = adReward.virtualCurrency {
///     // Reward is a virtual-currency line item.
/// } else if let entitlement = adReward.entitlement {
///     // Reward is a temporary entitlement grant.
/// } else if adReward == .noReward {
///     // Verification succeeded but no reward was granted.
/// } else if adReward == .unsupportedReward {
///     // Verification succeeded with a reward shape the SDK does not currently model.
/// }
/// ```
@_spi(Experimental) public struct AdReward: Sendable, Equatable {

    private enum Storage: Sendable, Equatable {
        case virtualCurrency(VirtualCurrencyReward)
        case entitlement(EntitlementReward)
        case noReward
        case unsupportedReward
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Reward is a virtual-currency line item with a code and amount.
    internal static func virtualCurrency(_ payload: VirtualCurrencyReward) -> AdReward {
        AdReward(storage: .virtualCurrency(payload))
    }

    /// Reward is a temporary entitlement grant with an identifier and expiration.
    internal static func entitlement(_ payload: EntitlementReward) -> AdReward {
        AdReward(storage: .entitlement(payload))
    }

    /// Verification succeeded but no reward was granted.
    public static let noReward = AdReward(storage: .noReward)

    /// Verification succeeded with a reward shape that the SDK does not currently model.
    public static let unsupportedReward = AdReward(storage: .unsupportedReward)

    /// Non-`nil` when this reward represents ``virtualCurrency(_:)``.
    public var virtualCurrency: VirtualCurrencyReward? {
        guard case .virtualCurrency(let payload) = self.storage else { return nil }
        return payload
    }

    /// Non-`nil` when this reward represents an ``EntitlementReward``.
    public var entitlement: EntitlementReward? {
        guard case .entitlement(let payload) = self.storage else { return nil }
        return payload
    }

    /// Stable raw value used for wire encoding and ObjC interop.
    internal var kindRawValue: String {
        switch self.storage {
        case .virtualCurrency: return Self.Kind.virtualCurrency
        case .entitlement: return Self.Kind.entitlement
        case .noReward: return Self.Kind.noReward
        case .unsupportedReward: return Self.Kind.unsupportedReward
        }
    }

    internal enum Kind {
        static let virtualCurrency = "virtual_currency"
        static let entitlement = "entitlement"
        static let noReward = "no_reward"
        static let unsupportedReward = "unsupported_reward"
    }
}

// MARK: - Wire encoding

extension AdReward {

    /// Encodes flat into the parent's container so the backend wire schema is unchanged
    /// while the kind→wire mapping stays local to ``AdReward``.
    internal func encode<K: CodingKey>(
        into container: inout KeyedEncodingContainer<K>,
        typeKey: K,
        codeKey: K,
        amountKey: K
    ) throws {
        try container.encode(self.kindRawValue, forKey: typeKey)
        try container.encodeIfPresent(self.virtualCurrency?.code, forKey: codeKey)
        try container.encodeIfPresent(self.virtualCurrency?.amount, forKey: amountKey)
    }

    /// Unknown kinds and malformed payloads log a warning and fall back to ``unsupportedReward``
    /// — backend wire data not matching the schema is not a programming bug.
    internal static func decode<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        typeKey: K,
        codeKey: K,
        amountKey: K
    ) throws -> AdReward {
        let kindRawValue = try container.decode(String.self, forKey: typeKey)
        let code = try container.decodeIfPresent(String.self, forKey: codeKey)
        let amount = try container.decodeIfPresent(Int.self, forKey: amountKey)
        switch kindRawValue {
        case Kind.virtualCurrency:
            guard let code, let amount,
                  let payload = VirtualCurrencyReward(code: code, amount: amount) else {
                Logger.warn(AdsStrings.invalid_virtual_currency_payload(code: code, amount: amount))
                return .unsupportedReward
            }
            return .virtualCurrency(payload)
        case Kind.noReward:
            return .noReward
        case Kind.unsupportedReward:
            return .unsupportedReward
        default:
            Logger.warn(AdsStrings.unknown_reward_kind(rawValue: kindRawValue))
            return .unsupportedReward
        }
    }
}
