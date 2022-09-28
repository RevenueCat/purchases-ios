//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncExtensionsTests.swift
//
//  Created by Nacho Soto on 9/27/22.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class AsyncExtensionsTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()
    }

    func testPublicErrorResultReturningSuccess() {
        var result: Result<Int, PublicError>?
        let expected = Int.random(in: 0..<100)

        let completion: (Result<Int, PublicError>) -> Void = { result = $0 }

        Async.call(with: completion) {
            return expected
        }

        expect(result).toEventually(beSuccess())
        expect(result?.value) == expected
    }

    func testPublicErrorResultReturningError() {
        var result: Result<Int, PublicError>?
        let error = ErrorUtils.configurationError()
        let expected = error.asPublicError

        let completion: (Result<Int, PublicError>) -> Void = { result = $0 }

        Async.call(with: completion) {
            throw error
        }

        expect(result).toEventually(beFailure())
        expect(result?.error).to(matchError(expected))
    }

    func testPurchasesErrorResultReturningSuccess() {
        var result: Result<Int, PurchasesError>?
        let expected = Int.random(in: 0..<100)

        let completion: (Result<Int, PurchasesError>) -> Void = { result = $0 }

        Async.call(with: completion) {
            return expected
        }

        expect(result).toEventually(beSuccess())
        expect(result?.value) == expected
    }

    func testPurchasesErrorResultReturningError() {
        var result: Result<Int, PurchasesError>?
        let expected = ErrorUtils.configurationError()

        let completion: (Result<Int, PurchasesError>) -> Void = { result = $0 }

        Async.call(with: completion) {
            throw expected
        }

        expect(result).toEventually(beFailure())
        expect(result?.error).to(matchError(expected))
    }

    func testCallWithNoError() {
        var result: Int?
        let expected = Int.random(in: 0..<100)

        let completion: (Int) -> Void = { result = $0 }

        Async.call(with: completion) {
            return expected
        }

        expect(result).toEventually(equal(expected))
    }

}
