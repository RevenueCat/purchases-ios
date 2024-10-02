//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SemanticVersionTests.swift
//
//  Created by JayShortway on 09/08/2024.

import Nimble
@testable import RevenueCatUI
import XCTest

class SemanticVersionTests: TestCase {

    func testValidVersionString() {
        let testCases: [(string: String, major: UInt, minor: UInt, patch: UInt)] = [
            (string: "12.4503.2", major: 12, minor: 4503, patch: 2),
            (string: "12.4503", major: 12, minor: 4503, patch: 0),
            (string: "12", major: 12, minor: 0, patch: 0),
            (string: "12.0.1", major: 12, minor: 0, patch: 1),
            (string: "0.0.1", major: 0, minor: 0, patch: 1),
            (string: "0.1.0", major: 0, minor: 1, patch: 0),
            (string: "1.0.0", major: 1, minor: 0, patch: 0),
            (string: "0.0.0", major: 0, minor: 0, patch: 0),
            (string: "1.0", major: 1, minor: 0, patch: 0)
        ]
        for (string, major, minor, patch) in testCases {
            XCTContext.runActivity(
                named: "Should correctly parse version: '\(string)'"
            ) { _ in
                // swiftlint:disable:next force_try
                let actual = try! SemanticVersion(string)
                let expected = SemanticVersion(major: major, minor: minor, patch: patch)

                expect(actual) == expected
            }
        }
    }

    func testInvalidVersionString() {
        let testCases = [
            "12.4503.2.3",
            "-12.4503.2",
            "12.-4503.2",
            "12.4503.-2",
            "-12",
            "-12.-4503",
            "-12.-4503.-2",
            "12.4503.2 and some more text",
            "Some more text and 12.4503.2",
            "",
            "some.text.whoa",
            "sometextwhoa",
            "1.text.whoa"
        ]
        for (string) in testCases {
            _ = XCTContext.runActivity(
                named: "Should fail to parse version: '\(string)'"
            ) { _ in
                expect { try SemanticVersion(string) }
                    .to(throwError(SemanticVersionError.invalidVersionString(string)))
            }
        }
    }

}
