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

class SubscriptionPeriodTests: TestCase {

    func testFromSK1WorksCorrectly() throws {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *) else {
            throw XCTSkip("Required API is unavailable for this test")
        }

        var sk1Period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)
        var subscriptionPeriod = try XCTUnwrap(SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1Period))

        expect(subscriptionPeriod.value) == 1
        expect(subscriptionPeriod.unit) == .month

        sk1Period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .year)
        subscriptionPeriod = try XCTUnwrap(SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1Period))

        expect(subscriptionPeriod.value) == 3
        expect(subscriptionPeriod.unit) == .year

        sk1Period = SKProductSubscriptionPeriod(numberOfUnits: 5, unit: .week)
        subscriptionPeriod = try XCTUnwrap(SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1Period))

        expect(subscriptionPeriod.value) == 5
        expect(subscriptionPeriod.unit) == .week
    }

    // Note: can't test creation from `StoreKit.Product.SubscriptionPeriod` because it has no public constructors.

    func testPricePerMonth() {
        let expectations: [(period: SubscriptionPeriod, price: Decimal, expected: Decimal)] = [
            (p(1, .day), 2, 60),
            (p(15, .day), 5, 10),
            (p(1, .week), 10, 40),
            (p(2, .week), 10, 20),
            (p(1, .month), 14.99, 14.99),
            (p(2, .month), 30, 15),
            (p(3, .month), 40, 13.33),
            (p(1, .year), 120, 10),
            (p(1, .year), 50, 4.16),
            (p(1, .year), 29.99, 2.49),
            (p(3, .year), 720, 20)
        ]

        for expectation in expectations {
            let pricePerMonth = expectation.period.pricePerMonth(withTotalPrice: expectation.price) as NSDecimalNumber
            let result = Double(truncating: pricePerMonth)
            let expected = Double(truncating: expectation.expected as NSDecimalNumber)

            expect(result).to(beCloseTo(expected),
                              description: "\(expectation.price) / \(expectation.period.debugDescription)")
        }
    }

    private func p(_ value: Int, _ unit: SubscriptionPeriod.Unit) -> SubscriptionPeriod {
        return .init(value: value, unit: unit)
    }

    func testFromSK1PeriodNormalizes() throws {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *) else {
            throw XCTSkip("Required API is unavailable for this test")
        }

        let expectations: [(
            inputValue: Int, inputUnit: SKProduct.PeriodUnit,
            expectedValue: Int, expectedUnit: SubscriptionPeriod.Unit
        )] = [
            // Test day simplification
            (1, .day, 1, .day),
            (7, .day, 1, .week),
            (1, .month, 1, .month),
            (12, .month, 1, .year)
        ]

        for expectation in expectations {
            let sk1SubscriptionPeriod = SKProductSubscriptionPeriod(
                numberOfUnits: expectation.inputValue,
                unit: expectation.inputUnit
            )
            let normalizedPeriod = SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1SubscriptionPeriod)
            let expected = SubscriptionPeriod(
                value: expectation.expectedValue,
                unit: expectation.expectedUnit
            )

            expect(normalizedPeriod).to(
                equal(expected),
                description: """
                    Expected \(sk1SubscriptionPeriod.testDescription) to become \(expected.debugDescription).
                    """
            )
        }
    }

    /// Necessary since SKProductSubscriptionPeriod.debugDescription & SKProductSubscriptionPeriod.description
    /// return the object's address in memory.
    @available(iOS 11.2, *)
    private func description(for skProductSubscriptionPeriod: SKProductSubscriptionPeriod) -> String {

        let periodUnit: String
        switch skProductSubscriptionPeriod.unit {
        case .day:
            periodUnit = "days"
        case .week:
            periodUnit = "weeks"
        case .month:
            periodUnit = "months"
        case .year:
            periodUnit = "years"
        @unknown default:
            periodUnit = "unknown"
        }

        return "SKProductSubscriptionPeriod: \(skProductSubscriptionPeriod.numberOfUnits) \(periodUnit)"
    }

}

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
extension SKProductSubscriptionPeriod {

    internal var testDescription: String {
        let periodUnit: String

        switch self.unit {
        case .day:
            periodUnit = "days"
        case .week:
            periodUnit = "weeks"
        case .month:
            periodUnit = "months"
        case .year:
            periodUnit = "years"
        @unknown default:
            periodUnit = "unknown"
        }

        return "SKProductSubscriptionPeriod: \(numberOfUnits) \(periodUnit)"
    }

}
