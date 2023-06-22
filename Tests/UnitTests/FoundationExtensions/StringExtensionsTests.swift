//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StringExtensionsTests.swift
//
//  Created by Nacho Soto on 6/10/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class StringExtensionsTests: TestCase {

    func testROT13() {
        let mangledTrackingClassName = "NGGenpxvatZnantre"
        let mangledAuthStatusPropertyName = "genpxvatNhgubevmngvbaFgnghf"

        expect(mangledTrackingClassName.rot13()) == "ATTrackingManager"
        expect(mangledAuthStatusPropertyName.rot13()) == "trackingAuthorizationStatus"
    }

    func testCountOccurrences() {
        expect("".countOccurences(of: " ")) == 0
        expect("1".countOccurences(of: "2")) == 0
        expect("1".countOccurences(of: "1")) == 1
        expect("12345".countOccurences(of: "1")) == 1
        expect("1234512345".countOccurences(of: "1")) == 2
        expect("123\n123".countOccurences(of: "\n")) == 1
        expect("123\n123\n".countOccurences(of: "\n")) == 2
    }

}
