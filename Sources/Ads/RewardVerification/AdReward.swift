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
/// Inspect the received reward by checking ``virtualCurrency`` or comparing against
/// ``noReward`` / ``unsupportedReward``:
///
/// ```swift
/// if let virtualCurrency = adReward.virtualCurrency {
///     // Reward is a virtual-currency line item.
/// } else if adReward == .noReward {
///     // Verification succeeded but no reward was granted.
/// } else if adReward == .unsupportedReward {
///     // Verification succeeded with a reward shape the SDK does not currently model.
/// }
/// ```
@_spi(Experimental) public struct AdReward: Sendable, Equatable {

    private enum Storage: Sendable, Equatable {
        case virtualCurrency(VirtualCurrencyReward)
        case noReward
        case unsupportedReward
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Reward is a virtual-currency line item with a code and amount.
    @_spi(Internal) public static func virtualCurrency(_ payload: VirtualCurrencyReward) -> AdReward {
        AdReward(storage: .virtualCurrency(payload))
    }

    /// Reward is a virtual-currency line item with the given code and amount. `amount` must be greater than zero.
    @_spi(Internal) public static func virtualCurrency(code: String, amount: Int) -> AdReward {
        if amount <= 0 {
            Logger.error(AdsStrings.invalid_virtual_currency_amount(amount: amount))
            assertionFailure(Self.Strings.virtualCurrencyAmountMustBeGreaterThanZero)
            return .unsupportedReward
        }
        return AdReward(storage: .virtualCurrency(VirtualCurrencyReward(code: code, amount: amount)))
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

    /// Stable raw value used for wire encoding and ObjC interop.
    @_spi(Internal) public var kindRawValue: String {
        switch self.storage {
        case .virtualCurrency: return Self.Kind.virtualCurrency
        case .noReward: return Self.Kind.noReward
        case .unsupportedReward: return Self.Kind.unsupportedReward
        }
    }

    internal enum Kind {
        static let virtualCurrency = "virtual_currency"
        static let noReward = "no_reward"
        static let unsupportedReward = "unsupported_reward"
    }

    private enum Strings {
        static let virtualCurrencyAmountMustBeGreaterThanZero = "virtualCurrency amount must be greater than zero"
    }
}
