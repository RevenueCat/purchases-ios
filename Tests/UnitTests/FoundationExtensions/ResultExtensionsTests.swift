//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ResultExtensionsTests.swift
//
//  Created by Nacho Soto on 3/8/22.

import Nimble
import XCTest

@testable import RevenueCat

class ResultExtensionsTests: TestCase {

    func testValue() {
        expect(Data.success("test").value) == "test"
        expect(Data.failure(.error1).value).to(beNil())
    }

    func testError() {
        expect(Data.success("test").error).to(beNil())
        expect(Data.failure(.error1).error) == .error1
    }

    func testInitWithValueAndNoError() {
        expect(Data("1", nil)) == .success("1")
    }

    func testInitWithValueAndErrorBecomesSuccess() {
        expect(Data("1", .error1)) == .success("1")
    }

    func testInitWithError() {
        expect(Data(nil, .error1)) == .failure(.error1)
    }

    func testErrorIsNotCreatedIfValueIsProvided() {
        var errorCreated = false

        func createError() -> Error {
            errorCreated = true
            return .error1
        }

        let result = Data("1", createError())
        expect(result) == .success("1")
        expect(errorCreated) == false
    }

    #if !os(watchOS)
    func testInitWithNoValueOrError() {
        expect {
            _ = Data(nil, nil)
        }.to(throwAssertion())
    }
    #endif

    func testVoidValueInitWithNoError() {
        expect(Result<Void, Error>(nil)).to(beSuccess())
    }

    func testVoidValueInitWithError() {
        expect(Result<Void, Error>(.error1)).to(beFailure {
            expect($0).to(matchError(Error.error1))
        })
    }

    func testInitWithThrowingAsyncBlockReturningValue() async throws {
        let expectedValue: Int = .random(in: 0..<100)

        func asyncValue() async throws -> Int {
            return expectedValue
        }

        let result: Result<Int, Swift.Error> = await .init(catching: { try await asyncValue() })
        expect(result).to(beSuccess())
        expect(result.value) == expectedValue
    }

    func testInitWithThrowingAsyncBlockThrowingError() async throws {
        let expectedError: ErrorCode = .customerInfoError

        func asyncValue() async throws -> Int {
            throw expectedError
        }

        let result: Result<Int, Swift.Error> = await .init(catching: { try await asyncValue() })
        expect(result).to(beFailure())
        expect(result.error).to(matchError(expectedError))
    }

}

class ResultAsOptionalResultTest: TestCase {

    private typealias Data = Result<String?, ResultExtensionsTests.Error>
    private typealias OptionalData = Result<String, ResultExtensionsTests.Error>?

    func testWithData() {
        expect(Data.success("test").asOptionalResult) == OptionalData.some(.success("test"))
    }

    func testWithNoData() {
        expect(Data.success(.none).asOptionalResult).to(beNil())
    }

    func testWithError() {
        expect(Data.failure(.error1).asOptionalResult) == OptionalData.some(.failure(.error1))
    }

}

private extension ResultExtensionsTests {

    enum Error: Swift.Error {

        case error1

    }

    typealias Data = Result<String, Error>

}
