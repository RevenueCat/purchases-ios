//
//  RewardVerificationResult.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) import RevenueCat

/// Result delivered to the app after reward verification polling for a presented rewarded ad.
@_spi(Experimental) public struct RewardVerificationResult: Sendable, Equatable {

    private enum Storage: Equatable, Sendable {
        case verified(AdReward)
        case failed
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Server verification succeeded for this ad’s transaction.
    internal static func verified(_ reward: AdReward) -> RewardVerificationResult {
        RewardVerificationResult(storage: .verified(reward))
    }

    /// Verification did not complete successfully (rejected, exhausted polling, error, etc.).
    internal static let failed = RewardVerificationResult(storage: .failed)

    /// Non-`nil` when verification succeeded.
    public var verifiedReward: AdReward? {
        guard case .verified(let reward) = self.storage else { return nil }
        return reward
    }

    /// Whether this result is ``failed``.
    public var isFailed: Bool {
        if case .failed = self.storage { return true }
        return false
    }
}

#endif
