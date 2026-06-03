//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdReward+TestExtensions.swift
//
//  Created by Pol Miro on 30/05/2026.

import Foundation
@_spi(Experimental) @testable import RevenueCat

extension AdReward {

    /// Test-only convenience that builds a virtual-currency reward from a code and amount.
    /// Production code constructs rewards via ``VirtualCurrencyReward/init(code:amount:)`` directly.
    /// Falls back to ``unsupportedReward`` when the inputs are rejected.
    static func virtualCurrency(code: String, amount: Int) -> AdReward {
        guard let payload = VirtualCurrencyReward(code: code, amount: amount) else {
            return .unsupportedReward
        }
        return .virtualCurrency(payload)
    }

}
