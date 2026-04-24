//
//  RewardVerificationResult.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

/// Result delivered to the app after reward verification polling for a presented rewarded ad.
///
/// This type is only for the presentation callback. The adapter’s internal polling pipeline uses
/// a separate `Outcome` type (`RewardVerification.Outcome`) before mapping to this value.
@_spi(Experimental) public struct RewardVerificationResult: Sendable, Equatable {

    private enum Storage: Equatable, Sendable {
        case verified(VerifiedReward)
        case failed
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Server verification succeeded for this ad’s transaction.
    public static func verified(_ reward: VerifiedReward) -> RewardVerificationResult {
        RewardVerificationResult(storage: .verified(reward))
    }

    /// Verification did not complete successfully (rejected, exhausted polling, error, etc.).
    public static let failed = RewardVerificationResult(storage: .failed)

    /// Non-`nil` when verification succeeded.
    public var verifiedReward: VerifiedReward? {
        guard case .verified(let reward) = self.storage else { return nil }
        return reward
    }

    /// Whether this result is ``verified(_:)``.
    public var isVerified: Bool {
        self.verifiedReward != nil
    }

    /// Whether this result is ``failed``.
    public var isFailed: Bool {
        if case .failed = self.storage { return true }
        return false
    }
}

#endif
