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

/// Result of a single ad reward verification status poll. Returned by
/// `Purchases.pollRewardVerificationStatus(clientTransactionID:)` and consumed by
/// RC-shipped ad adapters (e.g. `RevenueCatAdMob`).
@_spi(Internal) public enum RewardVerificationPollStatus: Sendable {
    /// The ad network's reward postback was received and verified by the backend.
    case verified

    /// The ad network's reward postback has not yet arrived (or is still being processed).
    /// The caller is expected to keep polling until the status becomes terminal
    /// or the caller's own retry budget is exhausted.
    case pending

    /// The ad network's reward postback was received but rejected by the backend.
    case failed

    /// The backend returned an unrecognized status value.
    case unknown
}
