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

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

/// Overload for `Nimble.waitUntil` with our default timeout
func waitUntil(
    timeout: DispatchTimeInterval = defaultTimeout,
    file: FileString = #file,
    line: UInt = #line,
    action: @escaping (@escaping () -> Void) -> Void
) {
    Nimble.waitUntil(timeout: timeout, file: file, line: line, action: action)
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
    timeout: DispatchTimeInterval = defaultTimeout,
    file: FileString = #file,
    line: UInt = #line,
    action: @escaping (@escaping @Sendable (Value?) -> Void) -> Void
) -> Value? {
    let result: Atomic<Value?> = nil

    waitUntil(timeout: timeout, file: file, line: line) { completed in
        action {
            result.value = $0
            completed()
        }
    }

    return result.value
}

/// Verifies that the given `async` condition becomes true after `timeout`,
/// checking every `pollInterval`.
// Note: a better approach would be using `XCTestExpectation` and `self.wait(for:timeout:)`
// but it doesn't seem to play well with async-await.
// Also `toEventually` (Quick nor Nimble) don't support `async`.
// Fix-me: remove once we can use Quick v6.x:
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
func asyncWait(
    description: String? = nil,
    timeout: DispatchTimeInterval = defaultTimeout,
    pollInterval: DispatchTimeInterval = defaultPollInterval,
    file: FileString = #fileID,
    line: UInt = #line,
    until condition: @Sendable () async -> Bool
) async throws {
    let start = Date()
    var foundCorrectValue = false

    func timedOut() -> Bool {
        return DispatchTimeInterval(Date().timeIntervalSince(start)) > timeout
    }

    repeat {
        foundCorrectValue = await condition()
        if !foundCorrectValue {
            try? await Task.sleep(nanoseconds: UInt64(pollInterval.nanoseconds))
        }
    } while !(foundCorrectValue || timedOut())

    expect(
        file: file,
        line: line,
        foundCorrectValue
    ).to(beTrue(), description: description)

    if !foundCorrectValue {
        struct ConditionFailedError: Error {}

        // Because this method is `async`, for some reason Swift is continuing execution of the test
        // despite the expectation failing, so we throw to ensure this doesn't happen
        // leading to an inconsistent state.
        throw ConditionFailedError()
    }
}

// Higher value required to avoid slow CI failing tests.
let defaultTimeout: DispatchTimeInterval = .seconds(2)
let defaultPollInterval: DispatchTimeInterval = AsyncDefaults.pollInterval
