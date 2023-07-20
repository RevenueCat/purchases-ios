//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyEncodableTests.swift
//
//  Created by Nacho Soto on 3/2/22.

import Nimble
import XCTest

@testable import RevenueCat

class AnyEncodableTests: TestCase {

    func testEmptyDictionary() {
        let empty: [String: Any] = [:]

        assertSnapshot(matching: AnyEncodable(empty), as: .json)
    }

    func testHomogenousDictionary() {
        let dictionary: [String: Any] = [
            "a": "1",
            "b": "2",
            "c": "3"
        ]

        assertSnapshot(matching: AnyEncodable(dictionary), as: .json)
    }

    func testDictionaryWithDifferentValues() {
        let dictionary: [String: Any?] = [
            "a": 1,
            "b": true,
            "c": "3",
            "d": nil
        ]

        assertSnapshot(matching: AnyEncodable(dictionary), as: .json)
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
            matching: AnyEncodable(dictionary),
            as: .json,
            // Formatting `Double`s changed in iOS 17
            testName: CurrentTestCaseTracker.osVersionAndTestName
        )
    }

    func testEncodingInvalidDataFails() {
        let dictionary: [String: Any?] = [
            "a": Double.infinity
        ]

        expect(try JSONEncoder().encode(AnyEncodable(dictionary)))
            .to(throwError())
    }

    func testDecodingEncodable() throws {
        let dictionary: [String: String] = [
            "a": "1",
            "b": "2",
            "c": "3"
        ]

        let encoded = AnyEncodable(dictionary as [String: Any])
        let decoded = try encoded.encodeAndDecode()
        let decodedValue = try XCTUnwrap(decoded.value as? [String: String])

        expect(decodedValue) == dictionary
    }

}
