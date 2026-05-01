//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VerifiedRewardTests.swift
//
//  Created by Pol Miro on 21/04/2026.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class VerifiedRewardTests: TestCase {

    func testVirtualCurrencyCarriesAssociatedReward() {
        let reward = VirtualCurrencyReward(code: "coins", amount: 5)
        let value: VerifiedReward = .virtualCurrency(reward)

        guard case .virtualCurrency(let captured) = value else {
            return XCTFail("Expected .virtualCurrency, got \(value)")
        }
        expect(captured) == reward
    }

}
