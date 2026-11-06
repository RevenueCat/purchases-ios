//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  XCTestCase+Extensions.swift
//
//  Created by Andrés Boedo on 9/16/21.

import Foundation
import Nimble
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

/// Similar to `XCTUnrap` but it allows an `async` closure.
@MainActor
func XCTAsyncUnwrap<T: Sendable>(
    _ expression: @autoclosure () async throws -> T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async throws -> T {
    let value = try await expression()

    return try XCTUnwrap(
        value,
        message(),
        file: file,
        line: line
    )
}

func requireWorkflowPrewarmingAvailability() throws {
    guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
        throw XCTSkip("Workflow prewarming requires iOS 15+")
    }
}

// `Nimble.throwAssertion` crashes when called from watchOS
// This avoids that by failing to compile instead.
@available(watchOS, unavailable)
func throwAssertion<Out>() -> Nimble.Predicate<Out> {
    return Nimble.throwAssertion()
}
