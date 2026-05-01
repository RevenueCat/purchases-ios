//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VerifiedReward.swift
//
//  Created by Pol Miro on 23/04/2026.

import Foundation

/// Reward payload carried on a verified reward-verification outcome.
@_spi(Internal) public enum VerifiedReward: Sendable, Equatable {

    /// A virtual-currency reward.
    case virtualCurrency(VirtualCurrencyReward)

    /// Verified, but no reward was granted.
    case noReward

    /// Verified with a reward shape not modeled by this SDK version.
    case unsupportedReward
}
