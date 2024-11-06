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

    static func iOS14APIAvailableOrSkipTest() throws {
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS14_3APIAvailableOrSkipTest() throws {
        guard #available(iOS 14.3, tvOS 14.3, macOS 11.1, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS15APIAvailableOrSkipTest() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS16APIAvailableOrSkipTest() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS17APIAvailableOrSkipTest() throws {
        guard #available(iOS 17.0, tvOS 17.0, macOS 14.0, watchOS 10.0, visionOS 1.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS18APIAvailableOrSkipTest() throws {
        guard #available(iOS 18.0, tvOS 18.0, macOS 15.0, watchOS 11.0, visionOS 2.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    /// Opposite of `iOS15APIAvailableOrSkipTest`.
    static func iOS15APINotAvailableOrSkipTest() throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            throw XCTSkip("Test only for older devices")
        }
    }

    static func skipIfTVOrWatchOSOrMacOS() throws {
        #if os(watchOS) || os(tvOS) || os(macOS)
        throw XCTSkip("Test not for watchOS or tvOS or macOS")
        #endif
    }

}
