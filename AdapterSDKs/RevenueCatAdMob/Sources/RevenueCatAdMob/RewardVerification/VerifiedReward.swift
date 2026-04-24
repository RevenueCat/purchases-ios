//
//  VerifiedReward.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

/// Reward payload after a successful reward verification (non-`enum` surface for the adapter module).
@_spi(Experimental) public struct VerifiedReward: Sendable, Equatable {

    private enum Storage: Equatable, Sendable {
        case virtualCurrency(code: String, amount: Int)
        case unknown
        case none
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Virtual currency line item. `amount` must be greater than zero.
    public static func virtualCurrency(code: String, amount: Int) -> VerifiedReward {
        precondition(amount > 0, "virtualCurrency amount must be greater than zero")
        return VerifiedReward(storage: .virtualCurrency(code: code, amount: amount))
    }

    /// Verified reward shape is not modeled in this SDK version.
    public static let unknown = VerifiedReward(storage: .unknown)

    /// Verification succeeded with no virtual-currency reward.
    public static let none = VerifiedReward(storage: .none)

    /// Whether this value represents ``virtualCurrency(code:amount:)``.
    public var isVirtualCurrency: Bool {
        if case .virtualCurrency = self.storage { return true }
        return false
    }

    /// Whether this value is ``unknown``.
    public var isUnknown: Bool {
        if case .unknown = self.storage { return true }
        return false
    }

    /// Whether this value is ``none``.
    public var isNone: Bool {
        if case .none = self.storage { return true }
        return false
    }

    /// Non-`nil` when ``isVirtualCurrency`` is `true`.
    public var virtualCurrencyCode: String? {
        guard case .virtualCurrency(let code, _) = self.storage else { return nil }
        return code
    }

    /// Non-`nil` when ``isVirtualCurrency`` is `true` (always greater than zero).
    public var virtualCurrencyAmount: Int? {
        guard case .virtualCurrency(_, let amount) = self.storage else { return nil }
        return amount
    }
}

#endif
