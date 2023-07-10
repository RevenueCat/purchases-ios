//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyCodableEncodableTests.swift
//
//  Created by Nacho Soto on 3/2/22.

import Nimble
import SnapshotTesting
import XCTest

@testable import RevenueCat

class AnyCodableEncodableTests: TestCase {

    func testEmptyDictionary() {
        let empty: [String: Any] = [:]

        assertSnapshot(matching: AnyCodable(empty), as: .json)
    }

    func testHomogenousDictionary() {
        let dictionary: [String: Any] = [
            "a": "1",
            "b": "2",
            "c": "3"
        ]

        assertSnapshot(matching: AnyCodable(dictionary), as: .json)
    }

    func testDictionaryWithDifferentValues() {
        let dictionary: [String: Any?] = [
            "a": 1,
            "b": true,
            "c": "3",
            "d": nil
        ]

        assertSnapshot(matching: AnyCodable(dictionary), as: .json)
    }

    func testNestedDictionary() {
        let dictionary: [String: Any?] = [
            "a": 1,
            "b": [
                "b1": false,
                "b2": [
                    "b21": 1,
                    "b22": URL(string: "https://google.com")!
                ] as [String: Any],
                "b3": [20.2, 19.99, 5],
                "b4": Date(timeIntervalSinceReferenceDate: 50000)
            ] as [String: Any],
            "c": "3",
            "d": nil
        ]

        assertSnapshot(
            matching: AnyCodable(dictionary),
            as: .json,
            // Formatting `Double`s changed in iOS 17
            testName: CurrentTestCaseTracker.osVersionAndTestName
        )
    }

    func testEncodingInvalidDataFails() {
        let dictionary: [String: Any?] = [
            "a": Double.infinity
        ]

        expect(try JSONEncoder().encode(AnyCodable(dictionary)))
            .to(throwError())
    }

    func testDecodingEncodable() throws {
        let dictionary: [String: String] = [
            "a": "1",
            "b": "2",
            "c": "3"
        ]

        let encoded = AnyCodable(dictionary as [String: Any])
        let decoded = try encoded.encodeAndDecode()
        let decodedValue = try XCTUnwrap(decoded.value as? [String: String])

        expect(decodedValue) == dictionary
    }

    func testDecodingNestedDictionary() throws {
        let dictionary = """
        {
            "a": "1",
            "b": "2",
            "c": {
                "a1": null,
                "b2": "test",
                "c3": {
                    "d": false
                },
                "d3": [1, 2, 3]
            }
        }
        """

        let value = try JSONDecoder.default.decode(AnyCodable.self, from: dictionary.asData)
        expect(try value.encodeAndDecode()) == value
    }

}
