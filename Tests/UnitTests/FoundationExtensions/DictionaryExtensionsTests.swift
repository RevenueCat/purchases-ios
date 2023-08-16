//
//  NSDictionaryExtensionsTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 9/28/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class DictionaryExtensionsTests: TestCase {

    func testRemovingNSNullValuesFiltersCorrectly() {
        let testValues: [String: Any] = [
            "instrument": "guitar",
            "type": 1,
            "volume": NSNull()
        ]
        let expectedValues: [String: Any] = [
            "instrument": "guitar",
            "type": 1
        ]

        let obtainedValues = testValues.removingNSNullValues()

        expect(obtainedValues.count) == expectedValues.count
        for (key, value) in obtainedValues {
            expect(value as? NSObject) == expectedValues[key] as? NSObject
        }
    }

    func testRemovingNSNullValuesReturnsEmptyIfOriginalIsEmpty() {
        let testValues: [String: Any] = [:]

        let obtainedValues = testValues.removingNSNullValues()

        expect(obtainedValues.count) == testValues.count
        for (key, value) in obtainedValues {
            expect(value as? NSObject) == testValues[key] as? NSObject
        }
    }

}

class DictionaryExtensionsMergingTests: TestCase {

    func testMergingStrategyKeepOriginalValue() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "1", "b": "1", "c": "2"]

        let obtainedDict = dict.merging(dict2, strategy: .keepOriginalValue)

        expect(obtainedDict).to(haveCount(expectedDict.keys.count))
        expect(obtainedDict) == expectedDict
    }

    func testMergingStrategyOverwriteValue() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        let obtainedDict = dict.merging(dict2, strategy: .overwriteValue)

        expect(obtainedDict).to(haveCount(expectedDict.keys.count))
        expect(obtainedDict) == expectedDict
    }

    func testMergingDefaultStrategy() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        let obtainedDict = dict.merging(dict2)

        expect(obtainedDict).to(haveCount(expectedDict.keys.count))
        expect(obtainedDict) == expectedDict
    }

    func testMergeStrategyKeepOriginalValue() {
        var dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "1", "b": "1", "c": "2"]

        dict.merge(dict2, strategy: .keepOriginalValue)

        expect(dict).to(haveCount(expectedDict.keys.count))
        expect(dict) == expectedDict
    }

    func testMergeStrategyOverwriteValue() {
        var dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        dict.merge(dict2, strategy: .overwriteValue)

        expect(dict).to(haveCount(expectedDict.keys.count))
        expect(dict) == expectedDict
    }

    func testMergeDefaultStrategy() {
        var dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        dict.merge(dict2)

        expect(dict).to(haveCount(expectedDict.keys.count))
        expect(dict) == expectedDict
    }

    func testMergingDictionariesByOperatorPlus() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        let obtainedDict = dict + dict2

        expect(obtainedDict).to(haveCount(expectedDict.keys.count))
        expect(obtainedDict) == expectedDict
    }

    func testAddEntriesToDictionaryWithOperatorPlusAddsValuesCorrectly() {
        var original = ["a": "1", "b": "1"]
        let addedValues = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        original += addedValues

        expect(original).to(haveCount(expectedDict.keys.count))
        expect(original) == expectedDict
    }

}

// swiftlint:disable:next type_name
class DictionaryExtensionsDictionaryWithKeysTests: TestCase {

    func testCreatingDictionaryWithNoValues() {
        expect([String]().dictionaryWithKeys { $0 }) == [:]
    }

    func testCreatingDictionaryAllowingDuplicateKeysWithNoValues() {
        expect([String]().dictionaryAllowingDuplicateKeys { $0 }) == [:]
    }

    func testCreatingDictionaryWithOneItem() {
        let values = ["1"]

        expect(values.dictionaryWithKeys { Int($0)! }) == [
            1: "1"
        ]
    }

    func testCreatingDictionaryWithMultipleValues() {
        let values = ["1", "2", "3"]

        expect(values.dictionaryWithKeys { Int($0)! + 1 }) == [
            2: "1",
            3: "2",
            4: "3"
        ]
    }

    func testCreatingDictionaryWithDuplicateKeys() {
        let values = ["1", "2", "3", "2"]

        expect(values.dictionaryAllowingDuplicateKeys { Int($0)! }) == [
            1: "1",
            2: "2",
            3: "3"
        ]
    }

}

class DictionaryExtensionsMapKeysTests: TestCase {

    private typealias Input = [Int: Int]
    private typealias Output = [String: Int]

    private let transformer: (Int) -> String = { String($0) }

    func testMapEmptyDictionary() {
        expect(Input().mapKeys(self.transformer)) == [:]
    }

    func testMapDictionaryWithOneKey() {
        expect([1: "test"].mapKeys(self.transformer)) == [
            "1": "test"
        ]
    }

    func testMapDictionary() {
        let input: Input = [
            1: 1,
            2: 2,
            3: 3
        ]
        expect(input.mapKeys(self.transformer)) == [
            "1": 1,
            "2": 2,
            "3": 3
        ]
    }

    func testMapKeysWithOverlappingKeys() {
        let input: [String: Int] = [
            "a1": 1,
            "a2": 2,
            "b3": 3
        ]

        let output = input.mapKeys { String($0.prefix(1)) }
        expect(output).to(haveCount(2))
        expect(output["b"]) == 3
        expect(output["a"]).to(satisfyAnyOf(
            equal(1),
            equal(2)
        ))
    }

    func testCompactMapEmptyDictionary() {
        expect(Input().compactMapKeys(self.transformer)) == [:]
    }

    func testCompactMapDictionaryWithOneKey() {
        expect([1: "test"].compactMapKeys(self.transformer)) == [
            "1": "test"
        ]
    }

    func testCompactMapDictionaryResultingInEmptyDictionary() {
        expect([1: "test"].compactMapKeys { _ in Optional<String>.none }).to(beEmpty())
    }

    func testCompactMapKeys() {
        let input: [Int: Int] = [
            1: 1,
            2: 2,
            3: 3,
            4: 4,
            5: 5
        ]

        let output = input.compactMapKeys {
            $0.isMultiple(of: 2)
                ? String($0)
                : nil
        }
        expect(output) == [
            "2": 2,
            "4": 4
        ]
    }

}

class DictionaryExtensionsRemoveTests: TestCase {

    private typealias Dict = [String: Int]

    func testRemoveNothingFromEmptyDictionary() {
        var dict = Dict()
        let count = dict.removeAll { _ in false }

        expect(dict).to(beEmpty())
        expect(count) == 0
    }

    func testRemoveAllFromEmptyDictionary() {
        var dict = Dict()
        let count = dict.removeAll { _ in true }

        expect(dict).to(beEmpty())
        expect(count) == 0
    }

    func testKeepOneElement() {
        var dict = ["1": 1]
        let count = dict.removeAll { _ in false }

        expect(dict) == ["1": 1]
        expect(count) == 0
    }

    func testRemoveOneElement() {
        var dict = ["1": 1]
        let count = dict.removeAll { _ in true }

        expect(dict).to(beEmpty())
        expect(count) == 1
    }

    func testRemoveSomeElements() {
        var dict = ["1": 1, "2": 2, "3": 3]
        let count = dict.removeAll { $0.isMultiple(of: 2) }

        expect(dict) == ["1": 1, "3": 3]
        expect(count) == 1
    }

    func testRemoveAllElements() {
        var dict = ["1": 1, "2": 2, "3": 3]
        let count = dict.removeAll { _ in true }

        expect(dict).to(beEmpty())
        expect(count) == 3
    }

}
