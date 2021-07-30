//
//  NSDictionaryExtensionsTests.swift
//  PurchasesCoreSwiftTests
//
//  Created by Andrés Boedo on 9/28/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble

@testable import PurchasesCoreSwift

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
        let removed = testValues.removingNSNullValues()
        expect(removed.count) == expectedValues.count
        for (key, value) in removed {
            expect(value as? NSObject) == expectedValues[key] as? NSObject
        }
    }
    
    func testRemovingNSNullValuesReturnsEmptyIfOriginalIsEmpty() {
        let testValues: [String: Any] = [:]
        
        let removed = testValues.removingNSNullValues()
        expect(removed.count) == testValues.count
        for (key, value) in removed {
            expect(value as? NSObject) == testValues[key] as? NSObject
        }
    }
}
