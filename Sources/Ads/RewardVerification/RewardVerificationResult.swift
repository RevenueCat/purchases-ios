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
        case verified(AdReward)
        case failed
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Server verification succeeded for this ad's transaction.
    @_spi(Internal) public static func verified(_ reward: AdReward) -> RewardVerificationResult {
        RewardVerificationResult(storage: .verified(reward))
    }

    /// Verification did not complete successfully (rejected, exhausted polling, error, etc.).
    public static let failed = RewardVerificationResult(storage: .failed)

    /// Non-`nil` when verification succeeded.
    public var verifiedReward: AdReward? {
        guard case .verified(let reward) = self.storage else { return nil }
        return reward
    }
}
