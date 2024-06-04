//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OperatorExtensionsTests.swift
//
//  Created by Nacho Soto on 5/23/22.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class OperatorExtensionsAsyncNilCoalescingTests: TestCase { // swiftlint:disable:this type_name

    func testReturnsInput() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let input: Bool? = true
        let result = await input ??? (await self.provider())

        expect(result) == true
    }

    func testDoesNotThrowIfInputIsNotNil() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let input: Bool? = true
        let result = try await input ??? (try await self.throwError())

        expect(result) == true
    }

    func testReturnsDefaultValue() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let input: Bool? = nil
        let result = await input ??? (await self.provider())

        expect(result) == false
    }

    func testThrowsError() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        let input: Bool? = nil
        do {
            _ = try await input ??? (await self.throwError())
            fail("Expected error")
        } catch { }
    }

    // MARK: -

    private func provider() async -> Bool {
        return false
    }

    private func throwError() async throws -> Bool {
        enum Error: Swift.Error {
            case error1
        }

        throw Error.error1
    }

}
