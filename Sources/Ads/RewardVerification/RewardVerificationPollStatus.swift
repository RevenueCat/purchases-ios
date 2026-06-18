//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationPollStatus.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation

/// Result of a single ad reward verification status poll.
enum RewardVerificationPollStatus: Sendable, Equatable {

    /// Verified by the backend, with the primary `reward` plus any `moreRewards` (additional rewards
    /// only — `moreRewards` does not repeat `reward`).
    case verified(reward: AdReward, moreRewards: [AdReward])

    /// Verification has not yet completed; the caller should keep polling.
    case pending

    /// The reward postback was rejected by the backend.
    ///
    /// - Parameters:
    ///   - reason: Raw `failure_reason` wire value (e.g. `no_access`), or `nil` when the backend
    ///     didn't provide one. Kept as a string for forward compatibility.
    ///   - message: Human-readable cause provided by the backend, logged verbatim, or `nil`.
    case failed(reason: String?, message: String?)

    /// The backend returned an unrecognized status value.
    case unknown
}
