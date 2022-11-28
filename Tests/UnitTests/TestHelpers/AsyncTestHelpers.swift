//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncTestHelpers.swift
//
//  Created by Nacho Soto on 11/14/22.

import Foundation

import Nimble

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
internal extension AsyncSequence {

    /// Returns the elements of the asynchronous sequence.
    func extractValues() async rethrows -> [Element] {
        return try await self.reduce(into: []) {
            $0.append($1)
        }
    }

}

/// Waits for `action` to be invoked, and returns the provided value, or `nil` on timeout.
/// Usage:
/// ```swift
/// let value: T? = waitUntilValue { completed in
///    asyncMethod { value in
///         completed(value)
///    }
/// }
/// ```
func waitUntilValue<Value>(
    timeout: DispatchTimeInterval = AsyncDefaults.timeout,
    file: FileString = #file,
    line: UInt = #line,
    action: @escaping (@escaping (Value?) -> Void) -> Void
) -> Value? {
    var value: Value?

    waitUntil(timeout: timeout, file: file, line: line) { completed in
        action {
            value = $0
            completed()
        }
    }

    return value
}
