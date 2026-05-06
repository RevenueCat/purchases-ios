//
//  VerifiedReward.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

/// Reward payload after a successful reward verification (non-`enum` surface for the adapter module).
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
        case unknown
        case noReward
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Virtual currency line item. `amount` must be greater than zero.
    public static func virtualCurrency(code: String, amount: Int) -> VerifiedReward {
        precondition(amount > 0, "virtualCurrency amount must be greater than zero")
        let payload = VirtualCurrencyReward(code: code, amount: amount)
        return VerifiedReward(storage: .virtualCurrency(payload))
    }

    /// Verified reward shape is not modeled in this SDK version.
    public static let unknown = VerifiedReward(storage: .unknown)

    /// Verification succeeded with no virtual-currency reward.
    public static let noReward = VerifiedReward(storage: .noReward)

    /// Whether this value is ``unknown``.
    public var isUnknown: Bool {
        if case .unknown = self.storage { return true }
        return false
    }

    /// Whether this value is ``noReward``.
    public var isNone: Bool {
        if case .noReward = self.storage { return true }
        return false
    }

    /// Non-`nil` when this value represents ``virtualCurrency(code:amount:)``.
    public var virtualCurrency: VirtualCurrencyReward? {
        guard case .virtualCurrency(let payload) = self.storage else { return nil }
        return payload
    }
}

#endif
