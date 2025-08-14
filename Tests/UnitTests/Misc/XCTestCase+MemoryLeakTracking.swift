//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  XCTestCase+MemoryLeakTracking.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import XCTest

extension XCTestCase {
    /// Create an object, track it for memory leaks, and assign use it in your test function
    /// - Parameters:
    ///   - file: The file the test is run in
    ///   - line: The line the test is calling this function from
    ///   - value: The object that should be deallocated by the time the test function done executing.
    /// - Returns: The initilized object that is being tracked for memory leaks
    ///
    /// > Tip: Pass in the construction of the object you want to track.
    /// >
    /// > ```swift
    /// > // ✅
    /// > let myObject = createAndTrackMemoryLeaks(MyObject())
    /// > ```
    /// > Instead of
    /// > ```swift
    /// > // ❌
    /// > let myObject = MyObject()
    /// > _ = createAndTrackMemoryLeaks(myObject)
    /// > ```
    ///
    @MainActor
    func createAndTrackForMemoryLeak<T: AnyObject>(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ value: @autoclosure () -> T
    ) -> T {
        let value = value()
        trackForMemoryLeak(file: file, line: line, value)
        return value
    }

    /// Automatically check if an object is properly deallocated
    /// - Parameters:
    ///   - file: The file the test is run in
    ///   - line: The line the test is calling this function from
    ///   - value: The object that should be deallocated by the time the test function done executing
    ///
    /// > Note: addTeardownBlock is main actor isolated, In swift 6,
    /// > passing value through from a nonisolated scope is an error
    /// > To prevent that—while allowing non-sendable types to be passed in—this function is
    /// > run on the main actor
    @MainActor
    func trackForMemoryLeak<T: AnyObject>(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ value: T
    ) {
        addTeardownBlock { [weak value] in
            XCTAssertNil(
                value,
                "Memory leak detected. \(String(describing: value)) should have been deallocated",
                file: file,
                line: line
            )
        }
    }
}
