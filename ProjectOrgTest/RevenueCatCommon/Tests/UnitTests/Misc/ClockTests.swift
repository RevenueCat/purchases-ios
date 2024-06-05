//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ClockTests.swift
//
//  Created by Nacho Soto on 8/16/23.

import Nimble
@testable import RevenueCat
import XCTest

class ClockTests: TestCase {

    private var startDate: Date!
    private var startTime: DispatchTime!
    private var clock: TestClock!

    override func setUp() {
        super.setUp()

        self.startDate = Date()
        self.startTime = .now()

        self.clock = .init(now: self.startDate, currentTime: self.startTime)
    }

    func testDurationSinceDispatchTimeWithNoTime() {
        expect(self.clock.durationSince(self.startTime)).to(beCloseTo(0))
    }

    func testDurationSinceDispatchTime() {
        self.clock.advance(by: .seconds(5))
        expect(self.clock.durationSince(self.startTime)).to(beCloseTo(5))

        self.clock.advance(by: .seconds(-10))
        expect(self.clock.durationSince(self.startTime)).to(beCloseTo(-5))
    }

    func testDurationSinceDateWithNoTime() {
        expect(self.clock.durationSince(self.startDate)).to(beCloseTo(0))
    }

    func testDurationSinceDate() {
        self.clock.advance(by: .seconds(5))
        expect(self.clock.durationSince(self.startDate)).to(beCloseTo(5))

        self.clock.advance(by: .seconds(-10))
        expect(self.clock.durationSince(self.startDate)).to(beCloseTo(-5))
    }

}
