//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationResult.swift
//

import Foundation

/// Result delivered to the app after reward verification polling for a presented rewarded ad.
@_spi(Experimental) public struct RewardVerificationResult: Sendable, Equatable {

    private enum Storage: Equatable, Sendable {
        case verified(reward: AdReward, moreRewards: [AdReward])
        case failed
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Server verification succeeded for this ad's transaction.
    ///
    /// `moreRewards` carries any *additional* rewards granted alongside the primary `reward`; it does
    /// not repeat `reward` and is empty in the common single-reward case.
    @_spi(Internal) public static func verified(
        _ reward: AdReward,
        moreRewards: [AdReward] = []
    ) -> RewardVerificationResult {
        RewardVerificationResult(storage: .verified(reward: reward, moreRewards: moreRewards))
    }

    /// Verification did not complete successfully (rejected, exhausted polling, error, etc.).
    public static let failed = RewardVerificationResult(storage: .failed)

    /// Non-`nil` when verification succeeded. The primary reward granted for this ad.
    public var verifiedReward: AdReward? {
        guard case .verified(let reward, _) = self.storage else { return nil }
        return reward
    }

    /// Additional rewards granted alongside ``verifiedReward``. Does not repeat ``verifiedReward``;
    /// empty when verification failed or only a single reward was granted.
    public var moreRewards: [AdReward] {
        guard case .verified(_, let moreRewards) = self.storage else { return [] }
        return moreRewards
    }

    /// `true` when verification did not complete successfully.
    var failed: Bool {
        guard case .failed = self.storage else { return false }
        return true
    }
}
