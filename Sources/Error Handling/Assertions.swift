//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Assertions.swift
//
//  Created by Nacho Soto on 5/16/23.

import Foundation

/// Equivalent to `assert`, but will only evaluate condition during RC tests.
/// - Note: this is a no-op in release builds.
@inline(__always)
func RCTestAssert(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    file: StaticString = #fileID,
    line: UInt = #line
) {
    #if DEBUG
    guard ProcessInfo.isRunningRevenueCatTests else { return }

    precondition(condition(), message(), file: file, line: line)
    #endif
}

@inline(__always)
func RCTestAssertNotMainThread(
    function: StaticString = #function,
    file: StaticString = #fileID,
    line: UInt = #line
) {
    #if DEBUG
    RCTestAssert(
        !Thread.isMainThread,
        "\(function) should not be called from the main thread",
        file: file,
        line: line
    )
    #endif
}
