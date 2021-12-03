//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionPeriodTests.swift
//
//  Created by Andrés Boedo on 3/12/21.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class SubscriptionPeriodTests: XCTestCase {

    func testFromSK1WorksCorrectly() throws {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *) else {
            throw XCTSkip("Required API is unavailable for this test")
        }

        var sk1Period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)
        var subscriptionPeriod = SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1Period)

        expect(subscriptionPeriod.value) == 1
        expect(subscriptionPeriod.unit) == .month

        sk1Period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .year)
        subscriptionPeriod = SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1Period)

        expect(subscriptionPeriod.value) == 3
        expect(subscriptionPeriod.unit) == .year

        sk1Period = SKProductSubscriptionPeriod(numberOfUnits: 5, unit: .week)
        subscriptionPeriod = SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1Period)

        expect(subscriptionPeriod.value) == 5
        expect(subscriptionPeriod.unit) == .week
    }

}
