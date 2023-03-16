//
// Created by RevenueCat on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class DateExtensionsTests: TestCase {

    func testMillisecondsSince1970ConvertsCorrectlyWithCurrentTime() {
        let date = Date()
        expect(date.millisecondsSince1970) == UInt64(date.timeIntervalSince1970 * 1000)
    }

    func testMillisecondsSince1970ConvertsCorrectlyWithFixedTime() {
        let secondsSince1970: TimeInterval = 1619555571.0
        let millisecondsSince1970UInt64: UInt64 = 1619555571000
        let date = Date(timeIntervalSince1970: secondsSince1970)
        expect(date.millisecondsSince1970) == millisecondsSince1970UInt64
    }

    func testMillisecondsSince1970() {
        let date = Date()
        expect(Date(millisecondsSince1970: date.millisecondsSince1970)).to(beCloseTo(date, within: 0.01))
    }

}
