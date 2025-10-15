//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ChecksumTests.swift
//
//  Created by Jacob Zivan Rakidzich on 10/3/25.

import Foundation
import RevenueCat
import XCTest

// swiftlint:disable line_length
final class ChecksumTests: TestCase {
    func test_checksumCalculation() {
        let data = "This is a test… give it your best.".data(using: .utf8).unsafelyUnwrapped
        let testCases = [
            (
                Checksum(algorithm: .md5, value: "60142a7d778a0216af5b627e1c67bca6"),
                #line as UInt
            ),
            (
                Checksum(algorithm: .sha256, value: "45ca18ea336e79d129b01a7ad51dedde2f160ec802067edd1ae162ff310ea8fb"),
                #line
            ),
            (
                Checksum(
                    algorithm: .sha384,
                    value: "bba3c72cbdd3e56ad7c5062f4cf0d20248ac92d4b3cb58e6bc860ffdd4d57b6e65ffcb1b5bee1ca5cabc1a08c3b989c1"
                ),
                #line
            ),
            (
                Checksum(
                    algorithm: .sha512,
                    value: "12374272ed45dc15ef9d226c37ac0376ba819271375f858d35b3e74353b8f9621b8fb45834280bfc13a8e92d5ca4fce3a2f0c02a1cf02b917f000441d125b0f3"
                ),
                #line
            )
        ]

        testCases.forEach { (expectedResult, line) in
            let result = Checksum.generate(from: data, with: expectedResult.algorithm)
            XCTAssertEqual(
                result,
                expectedResult,
                """
                    Checksum calculation failed for algorithm \(expectedResult.algorithm)
                    Expected \(expectedResult.value)
                    Got \(result.value)
                """,
                line: line
            )
        }
    }
}
