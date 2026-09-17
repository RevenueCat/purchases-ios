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

    static func iOS184APIAvailableOrSkipTest() throws {
        guard #available(iOS 18.4, macOS 15.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS26APIAvailableOrSkipTest() throws {
        guard #available(iOS 26.0, tvOS 26.0, macOS 26.0, watchOS 26.0, visionOS 26.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS264APIAvailableOrSkipTest() throws {
        guard #available(iOS 26.4, tvOS 26.4, macOS 26.4, watchOS 26.4, visionOS 26.4, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func iOS27APIAvailableOrSkipTest() throws {
        guard #available(iOS 27.0, tvOS 27.0, macOS 27.0, watchOS 27.0, visionOS 27.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    /// Switching Storefronts is broken in iOS 27.0. This is confirmed by Apple and is documented as a known issue
    /// in the Xcode 27 release notes (184155259)
    static func switchingStorefrontWithSKTestWorksOrSkipTest() throws {
        if #available(iOS 27.0, tvOS 27.0, macOS 27.0, watchOS 27.0, *) {
            throw XCTSkip("Switching Storefronts with SKTest is known to be broken on these OS versions.")
        }
    }

    /// Opposite of `iOS15APIAvailableOrSkipTest`.
    static func iOS15APINotAvailableOrSkipTest() throws {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            throw XCTSkip("Test only for older devices")
        }
    }

    /// Opposite of `iOS16APIAvailableOrSkipTest`.
    static func iOS16APINotAvailableOrSkipTest() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Test only for older devices")
        }
    }

    /// Opposite of `iOS26APIAvailableOrSkipTest`.
    static func iOS26APINotAvailableOrSkipTest() throws {
        if #available(iOS 26.0, tvOS 26.0, macOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            throw XCTSkip("Test only for older devices")
        }
    }

    /// Opposite of `iOS264APIAvailableOrSkipTest`.
    static func iOS264APINotAvailableOrSkipTest() throws {
        if #available(iOS 26.4, tvOS 26.4, macOS 26.4, watchOS 26.4, visionOS 26.4, *) {
            throw XCTSkip("Test only for older devices")
        }
    }

    static func skipIfTVOrWatchOSOrMacOS() throws {
        #if os(watchOS) || os(tvOS) || os(macOS)
        throw XCTSkip("Test not for watchOS or tvOS or macOS")
        #endif
    }

    static func macOS15_2APIAvailableOrSkipTest() throws {
        guard #available(macOS 15.2, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
    }

    static func skipIfCompiler63OrLater() throws {
        /*
         Our `.logIn(...)` and `.identifyCurrentUser(...)` APIs pair a `StaticString` overload with a
         `@_disfavoredOverload String` one: we try to push developers to use the `String`-taking versions by
         marking the `StaticString` versions as deprecated, but favored by the typechecker, so that hardcoding
         an app user ID — which would identify every user as the same person — warns at compile time.

         Beginning with Xcode 26.4 beta 1 and compiler version 6.3.0.119.2, `@_disfavoredOverload` stopped
         steering string literals toward those `StaticString` overloads, so the warning is silently lost:
         `logging_in_with_static_string` is no longer logged and the tests asserting it fail.

         As of compiler 6.4 (Xcode 27.0) the attribute is still honored, but only for an unlabeled,
         closure-free call to a member:

         ```swift
         class Subject {
             func unlabeled(_ s: StaticString) -> String { "STATIC" }
             @_disfavoredOverload func unlabeled(_ s: String) -> String { "REGULAR" }

             func labeled(as s: StaticString) -> String { "STATIC" }
             @_disfavoredOverload func labeled(as s: String) -> String { "REGULAR" }
         }

         subject.unlabeled("literal")    // "STATIC"  — as intended
         subject.labeled(as: "literal")  // "REGULAR" — literal binds to the String overload
         ```

         It is also ignored when the call passes a closure, and when the overloads are global functions.
         Pairs whose `String` sibling is optional (`String?`) are unaffected: reaching `String?` from a
         literal costs an extra optional injection, so `StaticString` wins on conversion ranking regardless.

         The tests still gated here are the labeled and closure-taking APIs. Until we determine the correct
         way to deal with this, we'll leave the APIs in place but skip those tests.
         */
        #if compiler(>=6.3)
        throw XCTSkip("Unavailable on Swift 6.3 or later")
        #endif
    }
}
