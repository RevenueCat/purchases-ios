//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointIdentifierValidatorTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(CheckpointsInternal) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointIdentifierValidatorTests: TestCase {

    func testValidCheckpointIdentifiers() {
        let validIdentifiers = [
            "a",
            "Z",
            "checkout",
            "checkout_123",
            "checkout-complete",
            "A-1_b",
            "a" + String(repeating: "1", count: CheckpointIdentifierValidator.maxLength - 1)
        ]

        for identifier in validIdentifiers {
            XCTAssertTrue(
                CheckpointIdentifierValidator.isValid(identifier),
                "Expected '\(identifier)' to be valid"
            )
        }
    }

    func testInvalidCheckpointIdentifiers() {
        let invalidIdentifiers = [
            "",
            "1checkout",
            "_checkout",
            "-checkout",
            "check out",
            " checkout",
            "checkout ",
            "checkout\n",
            "check.out",
            "chéckout",
            "checkout😀",
            "a" + String(repeating: "1", count: CheckpointIdentifierValidator.maxLength)
        ]

        for identifier in invalidIdentifiers {
            XCTAssertFalse(
                CheckpointIdentifierValidator.isValid(identifier),
                "Expected '\(identifier)' to be invalid"
            )
        }
    }

}
