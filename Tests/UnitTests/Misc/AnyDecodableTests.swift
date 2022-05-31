//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AnyDecodableTests.swift
//
//  Created by Nacho Soto on 5/11/22.

import Nimble
import SnapshotTesting
import XCTest

@testable import RevenueCat

class AnyDecodableTests: TestCase {

    func testNull() throws {
        expect(try AnyDecodable.decode("{\"key\": null}")) == ["key": .null]
    }

    func testEmptyDictionary() throws {
        expect(try AnyDecodable.decode("{}")) == [:]
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
        let expected: AnyDecodable = [
            "1": "string",
            "2": 1,
            "3": 4.815162342,
            "4": false,
            "5": [:],
            "6": [],
            "7": nil
        ]

        expect(try AnyDecodable.decode(json)) == expected
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
        let expected: AnyDecodable = [
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

        expect(try AnyDecodable.decode(json)) == expected
    }

    func testEmptyArray() throws {
        expect(try AnyDecodable.decode("[]")) == []
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
        let expected: AnyDecodable = [
            "string",
            2,
            3.6,
            false,
            [:],
            [],
            .null
        ]

        expect(try AnyDecodable.decode(json)) == expected
    }

    func testStringAsAny() {
        expect(AnyDecodable.string("test").asAny as? String) == "test"
    }

    func testIntAsAny() {
        expect(AnyDecodable.int(5).asAny as? Int) == 5
    }

    func testDoubleAsAny() {
        expect(AnyDecodable.double(3.14).asAny as? Double) == 3.14
    }

    func testBoolAsAny() {
        expect(AnyDecodable.bool(true).asAny as? Bool) == true
    }

    func testNilAsAny() {
        expect(AnyDecodable.null.asAny as? NSNull) == NSNull()
    }

    func testObjectAsAny() {
        let object: [String: String] = [
            "key_1": "1",
            "key_2": "2"
        ]
        let decodable: AnyDecodable = .object(object.mapValues(AnyDecodable.string))

        expect(decodable.asAny as? [String: String]) == object
    }

    func testArrayAsAny() {
        let array: [String] = ["1", "2", "3"]
        let decodable: AnyDecodable = .array(array.map(AnyDecodable.string))

        expect(decodable.asAny as? [String]) == array
    }

}
