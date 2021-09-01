//
//  NSDictionaryExtensionsTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 9/28/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble

@testable import RevenueCat

class DictionaryExtensionsTests: XCTestCase {

    func testRemovingNSNullValuesFiltersCorrectly() {
        let testValues: [String : Any] = [
            "instrument": "guitar",
            "type": 1,
            "volume": NSNull()
        ]
        let expectedValues: [String : Any] = [
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

    func testMergeDictionariesWithMergeStrategyKeepOriginalValue() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "1", "b": "1", "c": "2"]

        let obtainedDict = dict.merging(dict2, strategy: .keepOriginalValue)

        expect(obtainedDict.keys.count).to(equal(expectedDict.keys.count))
        expect(obtainedDict).to(equal(expectedDict))
    }

    func testMergeDictionariesWithMergeStrategyOverwriteValue() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        let obtainedDict = dict.merging(dict2, strategy: .overwriteValue)

        expect(obtainedDict.keys.count).to(equal(expectedDict.keys.count))
        expect(obtainedDict).to(equal(expectedDict))
    }

    func testMergeDictionariesWithDefaultMergeStrategy() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        let obtainedDict = dict.merging(dict2)

        expect(obtainedDict.keys.count).to(equal(expectedDict.keys.count))
        expect(obtainedDict).to(equal(expectedDict))
    }

    func testMergeDictionariesByOperatorPlus() {
        let dict = ["a": "1", "b": "1"]
        let dict2 = ["a": "2", "b": "2", "c": "2"]
        let expectedDict = ["a": "2", "b": "2", "c": "2"]

        let obtainedDict = dict + dict2

        expect(obtainedDict.keys.count).to(equal(expectedDict.keys.count))
        expect(obtainedDict).to(equal(expectedDict))
    }

}
