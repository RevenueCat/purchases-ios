//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyCodableDecodableTests.swift
//
//  Created by Nacho Soto on 5/11/22.

import Nimble
import SnapshotTesting
import XCTest

@testable import RevenueCat

class AnyCodableDecodableTests: TestCase {

    func testNull() throws {
        let value = try XCTUnwrap(AnyCodable.decode("{\"key\": null}").value as? [String: Any])
        expect(value["key"] as? NSNull) === NSNull()
    }

    func testEmptyDictionary() throws {
        expect(try AnyCodable.decode("{}").value as? [String: String]) == [:]
    }

    func testDictionary() throws {
        let json = """
        {
            "1": "string",
            "2": 1,
            "3": 4.815162342,
            "4": false,
            "5": {},
            "6": [],
            "7": null
        }
        """
        let expected: AnyCodable = [
            "1": "string",
            "2": 1,
            "3": 4.815162342,
            "4": false,
            "5": [:],
            "6": [],
            "7": nil
        ]

        expect(try AnyCodable.decode(json)) == expected
    }

    func testNestedDictionary() throws {
        let json = """
        {
            "1": {
                "a": "string",
                "b": 2,
                "c": 3.6,
                "d": true,
                "e": [
                    {
                        "test": "data"
                    }
                ],
                "f": null
            }
        }
        """
        let expected: AnyCodable = [
            "1": [
                "a": "string",
                "b": 2,
                "c": 3.6,
                "d": true,
                "e": [
                    ["test": "data"]
                ],
                "f": nil
            ]
        ]

        expect(try AnyCodable.decode(json)) == expected
    }

    func testIsValidDictionary() throws {
        let dictionary = [
            "request_date": "2018-10-19T02:40:36Z",
            "request_date_ms": Int64(1563379533946),
            "another_key": [
                "original_app_user_id": "app_user_id",
                "entitlement": [
                    "expires_date": nil,
                    "product_identifier": "onetime_purchase",
                    "purchase_date": "1990-08-30T02:40:36Z"
                ]
            ] as [String: Any]
        ] as [String: Any]

        let codable: AnyCodable = try JSONDecoder.default.decode(dictionary: dictionary)
        let decoded = try XCTUnwrap(codable.value as? [String: Any])

        expect(JSONSerialization.isValidJSONObject(decoded))
            .to(
                beTrue(),
                description: "Not valid JSON: \(decoded)"
            )
    }

    func testEmptyArray() throws {
        expect(try AnyCodable.decode("[]")) == []
    }

    func testArray() throws {
        let json = """
        [
            "string",
            2,
            3.6,
            false,
            {},
            [],
            null
        ]
        """
        let expected: AnyCodable = [
            "string",
            2,
            3.6,
            false,
            [:],
            [],
            nil
        ]

        expect(try AnyCodable.decode(json)) == expected
    }

    func testStringValue() {
        expect(AnyCodable("test").value as? String) == "test"
    }

    func testIntValue() {
        expect(AnyCodable(5).value as? Int) == 5
    }

    func testDoubleValue() {
        expect(AnyCodable(3.14).value as? Double) == 3.14
    }

    func testBoolValue() {
        expect(AnyCodable(true).value as? Bool) == true
    }

    func testNilValue() {
        expect(AnyCodable(nil).value as? NSNull) === NSNull()
    }

    func testObjectValue() {
        let object: [String: String] = [
            "key_1": "1",
            "key_2": "2"
        ]
        let decodable: AnyCodable = .init(object)

        expect(decodable.value as? [String: String]) == object
    }

    func testArrayValue() {
        let array: [String] = ["1", "2", "3"]
        let decodable: AnyCodable = .init(array)

        expect(decodable.value as? [String]) == array
    }

}
