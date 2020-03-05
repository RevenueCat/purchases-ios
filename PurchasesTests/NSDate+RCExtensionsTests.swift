//
// Created by RevenueCat on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

import Purchases

class NSDateExtensionsTests: XCTestCase {
    func testMillisecondsSince1970() {
        let date = NSDate()
        expect(date.millisecondsSince1970()) == (UInt64)(date.timeIntervalSince1970 * 1000)
    }
}
