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

class AsyncExtensionsTests: TestCase {

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

    func testConversionToAsyncWithResultSuccess() async throws {
        let expected = Int.random(in: 0..<100)

        let result = try await Async.call { (completion: (Result<Int, NSError>) -> Void) in
            completion(.success(expected))
        }

        expect(result) == expected
    }

    func testConversionToAsyncWithResultFailure() async throws {
        enum Error: Swift.Error {
            case error1
        }

        do {
            let _: Int = try await Async.call { completion in
                completion(.failure(Error.error1))
            }
            fail("Expected error")
        } catch {
            expect(error).to(matchError(Error.error1))
        }
    }

    func testConversionToAsyncWithValue() async {
        let expected = Int.random(in: 0..<100)

        let result = await Async.call { (completion: (Int) -> Void) in
            completion(expected)
        }

        expect(result) == expected
    }

    func testExtractValuesFromEmptyAsyncSequence() async {
        let result = await MockAsyncSequence<Int>(with: []).extractValues()

        expect(result) == []
    }

    func testExtractValuesFromAsyncSequenceWithOneElement() async {
        let elements = [1]
        let result = await MockAsyncSequence(with: elements).extractValues()

        expect(result) == elements
    }

    func testExtractValuesFromAsyncSequence() async {
        let elements = [1, 2, 3]
        let result = await MockAsyncSequence(with: elements).extractValues()

        expect(result) == elements
    }

}
