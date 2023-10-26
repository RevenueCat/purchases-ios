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

    func testPricePerWeek() {
        let tests: [Test] = [
            .init(p(1, .day), 1, 7),
            .init(p(14, .day), 2, 1),
            .init(p(1, .week), 10, 10),
            .init(p(2, .week), 10, 5),
            .init(p(1, .month), 14.99, 3.74),
            .init(p(2, .month), 30, 3.75),
            .init(p(3, .month), 40, 3.33),
            .init(p(1, .year), 120, 2.3),
            .init(p(1, .year), 50, 0.95),
            .init(p(1, .year), 29.99, 0.57),
            .init(p(3, .year), 720, 4.6)
        ]

        for test in tests {
            let pricePerWeek = test.period.pricePerWeek(withTotalPrice: test.price) as NSDecimalNumber
            let result = Double(truncating: pricePerWeek)
            let expected = Double(truncating: test.expected as NSDecimalNumber)

            expect(
                line: test.line,
                result
            ).to(beCloseTo(expected),
                 description: "\(test.price) / \(test.period.debugDescription)")
        }
    }

    func testPricePerMonth() {
        let tests: [Test] = [
            .init(p(1, .day), 2, 60),
            .init(p(15, .day), 5, 10),
            .init(p(1, .week), 10, 40),
            .init(p(2, .week), 10, 20),
            .init(p(1, .month), 14.99, 14.99),
            .init(p(2, .month), 30, 15),
            .init(p(3, .month), 40, 13.33),
            .init(p(1, .year), 120, 10),
            .init(p(1, .year), 50, 4.16),
            .init(p(1, .year), 29.99, 2.49),
            .init(p(3, .year), 720, 20)
        ]

        for test in tests {
            let pricePerMonth = test.period.pricePerMonth(withTotalPrice: test.price) as NSDecimalNumber
            let result = Double(truncating: pricePerMonth)
            let expected = Double(truncating: test.expected as NSDecimalNumber)

            expect(
                line: test.line,
                result
            ).to(beCloseTo(expected),
                 description: "\(test.price) / \(test.period.debugDescription)")
        }
    }

    func testPricePerYear() {
        let tests: [Test] = [
            .init(p(1, .day), 1, 365),
            .init(p(1, .day), 2, 730),
            .init(p(15, .day), 5, 121.66),
            .init(p(1, .week), 10, 521.4),
            .init(p(2, .week), 10, 260.7),
            .init(p(1, .month), 14.99, 179.88),
            .init(p(1, .month), 5, 60),
            .init(p(2, .month), 30, 180),
            .init(p(3, .month), 40, 160),
            .init(p(1, .year), 120, 120),
            .init(p(1, .year), 29.99, 29.99),
            .init(p(2, .year), 50, 25),
            .init(p(3, .year), 720, 240)
        ]

        for test in tests {
            let pricePerYear = test.period.pricePerYear(withTotalPrice: test.price) as NSDecimalNumber
            let result = Double(truncating: pricePerYear)
            let expected = Double(truncating: test.expected as NSDecimalNumber)

            expect(
                line: test.line,
                result
            ).to(beCloseTo(expected),
                 description: "\(test.price) / \(test.period.debugDescription)")
        }
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
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
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

// MARK: -

private extension SubscriptionPeriodTests {

    func p(_ value: Int, _ unit: SubscriptionPeriod.Unit) -> SubscriptionPeriod {
        return .init(value: value, unit: unit)
    }

    struct Test {
        var period: SubscriptionPeriod
        var price: Decimal
        var expected: Decimal
        var line: UInt

        init(_ period: SubscriptionPeriod, _ price: Decimal, _ expected: Decimal, line: UInt = #line) {
            self.period = period
            self.price = price
            self.expected = expected
            self.line = line
        }
    }

}
