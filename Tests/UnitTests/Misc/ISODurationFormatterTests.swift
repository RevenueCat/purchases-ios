//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ISODurationTests.swift
//
//  Created by Facundo Menzella on 10/2/25.

import Nimble
import XCTest

@testable import RevenueCat

final class ISODurationFormatterTests: TestCase {

    func testParseFullDuration() {
        let durationString = "P1Y2M3W4DT5H6M7S"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse full duration")
            return
        }

        expect(duration.years) == 1
        expect(duration.months) == 2
        expect(duration.weeks) == 3
        expect(duration.days) == 4
        expect(duration.hours) == 5
        expect(duration.minutes) == 6
        expect(duration.seconds) == 7
    }

    func testParseDaysOnly() {
        let durationString = "P10D"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse days-only duration")
            return
        }

        expect(duration.years) == 0
        expect(duration.months) == 0
        expect(duration.weeks) == 0
        expect(duration.days) == 10
        expect(duration.hours) == 0
        expect(duration.minutes) == 0
        expect(duration.seconds) == 0
    }

    func testParseWeeksOnly() {
        let durationString = "P5W"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse weeks-only duration")
            return
        }

        expect(duration.weeks) == 5
        expect(duration.years) == 0
        expect(duration.months) == 0
        expect(duration.hours) == 0
        expect(duration.minutes) == 0
        expect(duration.seconds) == 0
        expect(duration.days) == 0
    }

    func testParseTimeOnly() {
        let durationString = "PT3H45M20S"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse time-only duration")
            return
        }

        expect(duration.weeks) == 0
        expect(duration.years) == 0
        expect(duration.months) == 0
        expect(duration.hours) == 3
        expect(duration.minutes) == 45
        expect(duration.seconds) == 20
        expect(duration.days) == 0
    }

    func testStringFromDuration() {
        let duration = ISODuration(years: 1, months: 2, weeks: 0, days: 4, hours: 5, minutes: 6, seconds: 7)
        let durationString = ISODurationFormatter.string(from: duration)

        expect(durationString) == "P1Y2M4DT5H6M7S"
    }

    func testEmptyDuration() {
        let durationString = "P"
        let duration = ISODurationFormatter.parse(from: durationString)

        expect(duration).toNot(beNil())
        expect(duration?.years) == 0
        expect(duration?.months) == 0
        expect(duration?.days) == 0
        expect(duration?.hours) == 0
        expect(duration?.minutes) == 0
        expect(duration?.seconds) == 0
    }

    func testInvalidDuration() {
        let durationString = "InvalidString"
        expect(ISODurationFormatter.parse(from: durationString)).to(beNil())
    }
}
