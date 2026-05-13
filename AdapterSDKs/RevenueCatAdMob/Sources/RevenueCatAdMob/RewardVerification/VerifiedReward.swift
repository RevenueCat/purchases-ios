//
//  VerifiedReward.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

/// Reward payload returned after successful verification.
@_spi(Experimental) public struct VerifiedReward: Sendable, Equatable {

    /// Virtual-currency payload returned after successful verification.
    public struct VirtualCurrencyReward: Sendable, Equatable {
        /// Virtual currency identifier.
        public let code: String
        /// Granted amount (always greater than zero).
        public let amount: Int
    }

    private enum Storage: Equatable, Sendable {
        case virtualCurrency(VirtualCurrencyReward)
        case unsupportedReward
        case noReward
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Virtual currency line item. `amount` must be greater than zero.
    public static func virtualCurrency(code: String, amount: Int) -> VerifiedReward {
        if amount <= 0 {
            Logger.error(RewardVerificationStrings.invalid_virtual_currency_amount(amount: amount))
            assertionFailure(Self.Strings.virtualCurrencyAmountMustBeGreaterThanZero)
            return .unsupportedReward
        }

        let payload = VirtualCurrencyReward(code: code, amount: amount)
        return VerifiedReward(storage: .virtualCurrency(payload))
    }

    /// Verification succeeded with a reward type that is not currently modeled by this SDK.
    public static let unsupportedReward = VerifiedReward(storage: .unsupportedReward)

    /// Verification succeeded with no virtual-currency reward.
    public static let noReward = VerifiedReward(storage: .noReward)

    /// Non-`nil` when this value represents ``virtualCurrency(code:amount:)``.
    public var virtualCurrency: VirtualCurrencyReward? {
        guard case .virtualCurrency(let payload) = self.storage else { return nil }
        return payload
    }

    private enum Strings {
        static let virtualCurrencyAmountMustBeGreaterThanZero = "virtualCurrency amount must be greater than zero"
    }
}

#endif
