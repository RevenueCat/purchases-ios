//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitWorkaroundsTests.swift
//
//  Created by Will Taylor on 5/20/22.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class StoreKitWorkaroundsTests: TestCase {

    func testSimplifyValueAndUnits() {
        let expectations: [(
            inputValue: Int, inputUnit: SubscriptionPeriod.Unit,
            expectedValue: Int, expectedUnit: SubscriptionPeriod.Unit
        )] = [
            // Test day simplification
            (1, .day, 1, .day),
            (7, .day, 1, .week),
            (14, .day, 2, .week),
            (21, .day, 3, .week),
            (28, .day, 4, .week),
            (30, .day, 30, .day),
            (56, .day, 8, .week),
            (112, .day, 16, .week),
            (356, .day, 356, .day),
            (712, .day, 712, .day),
            // Test week simplification
            (1, .week, 1, .week),
            (4, .week, 4, .week),
            (24, .week, 24, .week),
            (52, .week, 52, .week),
            (104, .week, 104, .week),
            // Test month simplification
            (1, .month, 1, .month),
            (12, .month, 1, .year),
            (24, .month, 2, .year),
            // Ensure year inputs return the same value
            (1, .year, 1, .year),
            (2, .year, 2, .year)
        ]

        for expectation in expectations {
            let period = SubscriptionPeriod(
                value: expectation.inputValue,
                unit: expectation.inputUnit
            )
            let normalized = period.normalized()
            let expected = SubscriptionPeriod(
                value: expectation.expectedValue,
                unit: expectation.expectedUnit
            )

            expect(normalized).to(
                equal(expected),
                description: "Expected \(period.debugDescription) to become \(expected.debugDescription)."
            )
        }
    }

}
