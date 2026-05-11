//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyReward.swift
//
//  Created by Pol Miro on 23/04/2026.

import Foundation

/// A virtual-currency reward granted by an ad network after a successful reward verification.
@_spi(Internal) public struct VirtualCurrencyReward: Sendable, Equatable {

    /// The reward type identifier (e.g. `"coins"`, `"gems"`).
    public let code: String

    /// The reward amount.
    public let amount: Int

    /// Creates a virtual-currency reward.
    public init(code: String, amount: Int) {
        self.code = code
        self.amount = amount
    }
}
