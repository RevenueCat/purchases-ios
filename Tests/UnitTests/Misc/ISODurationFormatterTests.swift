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

import XCTest

@testable import RevenueCat

final class ISODurationFormatterTests: TestCase {

    func testParseFullDuration() {
        let durationString = "P1Y2M3W4DT5H6M7S"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse full duration")
            return
        }

        XCTAssertEqual(duration.years, 1)
        XCTAssertEqual(duration.months, 2)
        XCTAssertEqual(duration.weeks, 3)
        XCTAssertEqual(duration.days, 4)
        XCTAssertEqual(duration.hours, 5)
        XCTAssertEqual(duration.minutes, 6)
        XCTAssertEqual(duration.seconds, 7)
    }

    func testParseDaysOnly() {
        let durationString = "P10D"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse days-only duration")
            return
        }

        XCTAssertEqual(duration.years, 0)
        XCTAssertEqual(duration.months, 0)
        XCTAssertEqual(duration.weeks, 0)
        XCTAssertEqual(duration.days, 10)
        XCTAssertEqual(duration.hours, 0)
        XCTAssertEqual(duration.minutes, 0)
        XCTAssertEqual(duration.seconds, 0)
    }

    func testParseWeeksOnly() {
        let durationString = "P5W"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse weeks-only duration")
            return
        }

        XCTAssertEqual(duration.weeks, 5)
        XCTAssertEqual(duration.days, 0)
    }

    func testParseTimeOnly() {
        let durationString = "PT3H45M20S"
        guard let duration = ISODurationFormatter.parse(from: durationString) else {
            XCTFail("Failed to parse time-only duration")
            return
        }

        XCTAssertEqual(duration.hours, 3)
        XCTAssertEqual(duration.minutes, 45)
        XCTAssertEqual(duration.seconds, 20)
    }

    func testStringFromDuration() {
        let duration = ISODuration(years: 1, months: 2, weeks: 0, days: 4, hours: 5, minutes: 6, seconds: 7)
        let durationString = ISODurationFormatter.string(from: duration)

        XCTAssertEqual(durationString, "P1Y2M4DT5H6M7S", "String conversion is incorrect")
    }

    func testEmptyDuration() {
        let durationString = "P"
        let duration = ISODurationFormatter.parse(from: durationString)

        XCTAssertNotNil(duration, "Empty duration should be valid and return zero duration")
        XCTAssertEqual(duration?.years, 0)
        XCTAssertEqual(duration?.months, 0)
        XCTAssertEqual(duration?.days, 0)
        XCTAssertEqual(duration?.hours, 0)
        XCTAssertEqual(duration?.minutes, 0)
        XCTAssertEqual(duration?.seconds, 0)
    }

    func testInvalidDuration() {
        let durationString = "InvalidString"
        let duration = ISODurationFormatter.parse(from: durationString)
        XCTAssertNil(duration, "Invalid duration string should return nil")
    }
}
