//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  String+ExtractNumberTests.swift
//
//  Created by Jacob Zivan Rakidzich on 12/3/25.

import Foundation
@_spi(Internal) import RevenueCat
import XCTest

final class ExtractNumberTests: TestCase {
    func testExtractNumber() {
        let testCases = [
            ("", nil, #line as UInt),
            ("1", 1, #line),
            ("1.01.1100", 1011100, #line),
            ("001.01.1100", 1011100, #line),
            ("-some_random*Text@-123.456.7890-snapshot", 1234567890, #line)
        ]

        testCases.forEach { (input, expectedOutput, line) in
            XCTAssertEqual(input.extractNumber(), expectedOutput, line: line)
        }
    }
}
