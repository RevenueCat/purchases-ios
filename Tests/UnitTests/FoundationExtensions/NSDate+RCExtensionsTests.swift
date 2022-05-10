//
// Created by RevenueCat on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class NSDateExtensionsTests: TestCase {
    func testMillisecondsSince1970ConvertsCorrectlyWithCurrentTime() {
        let date = NSDate()
        expect(date.millisecondsSince1970AsUInt64()) == (UInt64)(date.timeIntervalSince1970 * 1000)
    }

    func testMillisecondsSince1970ConvertsCorrectlyWithFixedTime() {
        let secondsSince1970: TimeInterval = 1619555571.0
        let millisecondsSince1970UInt64: UInt64 = 1619555571000
        let date = NSDate(timeIntervalSince1970: secondsSince1970)
        expect(date.millisecondsSince1970AsUInt64()) == millisecondsSince1970UInt64
    }
}
