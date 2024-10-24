//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ISO8601DateFormatterTests.swift
//
//  Created by Paweł Czerwiński on 6/28/24.

import Nimble
@testable import ReceiptParser
import XCTest

class ISO8601DateFormatterTests: XCTestCase {

    private let someValidDates: [(text: String, date: Date)] = [
        ("2018-11-13T16:46:31Z", Date(timeIntervalSince1970: 1542127591.0)),
        ("2020-07-22T17:39:08Z", Date(timeIntervalSince1970: 1595439548.0)),
        ("2020-07-14T21:47:57Z", Date(timeIntervalSince1970: 1594763277.0)),
        ("2020-07-22T17:39:06Z", Date(timeIntervalSince1970: 1595439546.0)),
        ("2022-09-14T01:47:57Z", Date(timeIntervalSince1970: 1663120077.0)),
        ("2022-09-14T01:47:07Z", Date(timeIntervalSince1970: 1663120027.0))
    ]

    private let someInvalidlyParsedDates: [(text: String, date: Date)] = [
        ("2022-09-31T01:47:57Z", Date(timeIntervalSince1970: 1664588877.0)), // September has only 30 days
        ("2022-02-29T12:47:57Z", Date(timeIntervalSince1970: 1646138877.0)), // In 2022 February had 28 days not 29
        ("2022-02-30T12:47:57Z", Date(timeIntervalSince1970: 1646225277.0)), // In 2022 February had 28 days not 30
        ("2022-02-31T01:47:57Z", Date(timeIntervalSince1970: 1646272077.0)), // In 2022 February had 28 days not 31
        ("2016-02-30T01:47:57Z", Date(timeIntervalSince1970: 1456796877.0)), // In 2016 February had 29 days not 30
        ("2016-02-31T01:47:57Z", Date(timeIntervalSince1970: 1456883277.0)), // In 2016 February had 29 days not 31
        ("2022-09-14T24:47:07Z", Date(timeIntervalSince1970: 1663202827.0))  // Too high hour
    ]

    private let someInvalidDates: [String] = [
        "2022-13-14T24:47:07Z", // invalid month
        "2022-12-32T24:47:07Z", // invalid day
        "2022-09-14T25:47:07Z", // invalid hour
        "2022-09-14T23:61:07Z", // invalid minutes
        "2022-09-14T23:60:07Z", // invalid minutes
        "2022-09-14T12:47:60Z", // invalid seconds
        "2022-09-14T12:47:72Z"  // invalid seconds
    ]

    func testParseStandardDates() {
        for (dateString, expectedResult) in someValidDates {
            expect(ISO8601DateFormatter.default.date(from: dateString)) == expectedResult
        }
    }

    func testParseInvalidDatesThatForSomeReasonWorks() {
        for (dateString, observedResult) in someInvalidlyParsedDates {
            expect(ISO8601DateFormatter.default.date(from: dateString)) == observedResult
        }
    }

    func testParseInvalidDates() {
        for dateString in someInvalidDates {
            expect(ISO8601DateFormatter.default.date(from: dateString)).to(beNil())
        }
    }

    func testConsistencyWithRawBitsParser() {
        let allDates = someValidDates.map { $0.text } +
                       someInvalidlyParsedDates.map { $0.text } +
                       someInvalidDates

        for dateString in allDates {
            do {
                let data = try XCTUnwrap(dateString.data(using: .ascii))
                let rawBits = ArraySlice(data)
                XCTAssertEqual(ISO8601DateFormatter.default.date(from: dateString), rawBits.toDate())
            } catch {
                fail("Unexpected error for \(dateString), error: \(error)")
            }
        }
    }

}
