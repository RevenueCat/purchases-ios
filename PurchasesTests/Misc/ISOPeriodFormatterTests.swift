//
//  ISOPeriodFormatterTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 5/26/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)
class ISOPeriodFormatterTests: XCTestCase {
        
    func testStringFromProductSubscriptionPeriodDay() {
        let formatter = Purchases.ISOPeriodFormatter()
        
        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .day)
        expect(formatter.string(from: period)) == "P1D"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .day)
        expect(formatter.string(from: period)) == "P10D"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .day)
        expect(formatter.string(from: period)) == "P3D"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .day)
        expect(formatter.string(from: period)) == "P8D"
    }

    func testStringFromProductSubscriptionPeriodMonth() {
        let formatter = Purchases.ISOPeriodFormatter()
        
        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)
        expect(formatter.string(from: period)) == "P1M"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .month)
        expect(formatter.string(from: period)) == "P10M"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .month)
        expect(formatter.string(from: period)) == "P3M"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .month)
        expect(formatter.string(from: period)) == "P8M"
    }
    
    func testStringFromProductSubscriptionPeriodWeek() {
        let formatter = Purchases.ISOPeriodFormatter()
        
        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .week)
        expect(formatter.string(from: period)) == "P1W"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .week)
        expect(formatter.string(from: period)) == "P10W"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .week)
        expect(formatter.string(from: period)) == "P3W"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .week)
        expect(formatter.string(from: period)) == "P8W"
    }
    
    func testStringFromProductSubscriptionPeriodYear() {
        let formatter = Purchases.ISOPeriodFormatter()
        
        var period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .year)
        expect(formatter.string(from: period)) == "P1Y"

        period = SKProductSubscriptionPeriod(numberOfUnits: 10, unit: .year)
        expect(formatter.string(from: period)) == "P10Y"

        period = SKProductSubscriptionPeriod(numberOfUnits: 3, unit: .year)
        expect(formatter.string(from: period)) == "P3Y"

        period = SKProductSubscriptionPeriod(numberOfUnits: 8, unit: .year)
        expect(formatter.string(from: period)) == "P8Y"
    }
}
