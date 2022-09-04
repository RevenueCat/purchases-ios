//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AvailabilityChecks.swift
//
//  Created by Joshua Liebowitz on 12/2/21.

import Foundation
import XCTest

// Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
// Although the method isn't supposed to be called because of our @available marks in our subclasses,
// everything in those classes will still be called by XCTest, and it will cause errors.
enum AvailabilityChecks {

    static func iOS13APIAvailableOrSkipTest() throws {
        guard #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS14APIAvailableOrSkipTest() throws {
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS15APIAvailableOrSkipTest() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    /// Opposite of `iOS15APIAvailableOrSkipTest`.
    static func iOS15APINotAvailableOrSkipTest() throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            throw XCTSkip("Test only for older devices")
        }
    }

}
