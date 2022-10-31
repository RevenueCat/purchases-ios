//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SetExtensionsTests.swift
//
//  Created by Nacho Soto on 12/15/21.

import Nimble
import XCTest

@testable import RevenueCat

class SetExtensionsTests: TestCase {

    func testCreatingDictionaryWithEmptySet() {
        expect(Set<String>().dictionaryWithValues { $0 }) == [:]
    }

    func testCreatingDictionaryWithOneItem() {
        let keys: Set<String> = ["1"]

        expect(keys.dictionaryWithValues { Int($0)! }) == [
            "1": 1
        ]
    }

    func testCreatingDictionaryWithMultipleValues() {
        let keys: Set<String> = ["1", "2", "3"]

        expect(keys.dictionaryWithValues { Int($0)! + 1 }) == [
            "1": 2,
            "2": 3,
            "3": 4
        ]
    }

    func testAddingTwoSets() {
        let set1: Set<String> = ["1", "2"]
        let set2: Set<String> = ["3", "2"]

        expect(set1 + set2) == ["1", "2", "3"]
    }

    func testSetUnion() {
        var set1: Set<String> = ["1", "2"]
        let set2: Set<String> = ["3", "2"]

        set1 += set2

        expect(set1) == ["1", "2", "3"]
    }

}
