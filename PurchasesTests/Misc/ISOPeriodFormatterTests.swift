//
//  ISOPeriodFormatterTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 5/26/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ISOPeriodFormatterTests: XCTestCase {
    
    func testStringFromProductSubscriptionPeriodDay() throws {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *) else {
            throw XCTSkip()
        }

        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .day)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P1D"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .day)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P10D"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .day)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P3D"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .day)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P8D"
    }
    
    func testStringFromProductSubscriptionPeriodMonth() throws {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *) else {
            throw XCTSkip()
        }

        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P1M"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .month)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P10M"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .month)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P3M"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .month)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P8M"
    }

    func testStringFromProductSubscriptionPeriodWeek() throws {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *) else {
            throw XCTSkip()
        }

        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .week)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P1W"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .week)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P10W"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .week)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P3W"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .week)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P8W"
    }
    
    func testStringFromProductSubscriptionPeriodYear() throws {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *) else {
            throw XCTSkip()
        }

        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .year)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P1Y"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .year)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P10Y"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .year)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P3Y"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .year)
        expect(ISOPeriodFormatter.string(fromProductSubscriptionPeriod: period)) == "P8Y"
    }
}
