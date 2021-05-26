//
//  NSDictionaryExtensionsTests.swift
//  PurchasesCoreSwiftTests
//
//  Created by Andrés Boedo on 9/28/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble

@testable import Purchases

class NSDictionaryExtensionsTests: XCTestCase {
    func testRemovingNSNullValuesFiltersCorrectly() {
        let testValues: NSDictionary = [
            "instrument": "guitar",
            "type": 1,
            "volume": NSNull()
        ]
        let expectedValues: NSDictionary = [
            "instrument": "guitar",
            "type": 1
        ]
        
        expect(testValues.rc_removingNSNullValues() as NSDictionary) == expectedValues
    }
    
    func testRemovingNSNullValuesReturnsEmptyIfOriginalIsEmpty() {
        let testValues = NSDictionary()
        
        expect(testValues.rc_removingNSNullValues() as NSDictionary) == testValues
    }
}
