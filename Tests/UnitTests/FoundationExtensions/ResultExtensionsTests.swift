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

class ResultOptionalSuccessInitTests: TestCase {

    private typealias Error = ResultExtensionsTests.Error

    func testInitWithValueAndNoError() {
        let result: Result<String?, Error> = Result("1", nil)
        expect(result) == .success("1")
    }

    func testInitWithErrorTakesPrecedenceOverValue() {
        let result: Result<String?, Error> = Result("1", .error1)
        expect(result) == .failure(.error1)
    }

    /// Without this overload, the missing value is promoted into a second layer of optionality,
    /// looks present, and the error is silently dropped as `.success(nil)`.
    func testInitWithNoValueAndErrorBecomesFailure() {
        let result: Result<String?, Error> = Result(nil, .error1)
        expect(result) == .failure(.error1)
    }

    /// Unlike the unconstrained initializer, an absent value is a valid success here.
    func testInitWithNoValueOrErrorSucceedsWithNil() {
        let result: Result<String?, Error> = Result(nil, nil)
        expect(result) == .success(nil)
    }

    /// The error is checked first, so unlike the unconstrained initializer it is always evaluated.
    func testErrorIsCreatedEvenIfValueIsProvided() {
        var errorCreated = false

        func createError() -> Error? {
            errorCreated = true
            return nil
        }

        let result: Result<String?, Error> = Result("1", createError())
        expect(result) == .success("1")
        expect(errorCreated) == true
    }

}

/// Covers `Result.init(_:_:)` where `Success` is inferred as part of an enclosing generic call
/// rather than from the argument alone, which is the shape in which `Success` can be inferred as
/// optional. A change in how the compiler resolves it is caught here rather than as a silently
/// dropped error at a call site.
class ResultInitNestedInferenceTests: TestCase {

    private typealias Error = ResultExtensionsTests.Error

    func testErrorIsThrownWhenNestedInContinuationReturningOptional() async throws {
        do {
            _ = try await self.asyncOptionalValue(nil, .error1)
            fail("Expected an error to be thrown")
        } catch {
            expect(error).to(matchError(Error.error1))
        }
    }

    func testValueIsReturnedWhenNestedInContinuationReturningOptional() async throws {
        let value = try await self.asyncOptionalValue("1", nil)
        expect(value) == "1"
    }

    /// An optional `Success` reaches the preserving initializer, for which this is a valid success,
    /// rather than the unwrapping initializer, which traps.
    func testNoValueOrErrorReturnsNilWhenNestedInContinuationReturningOptional() async throws {
        let value = try await self.asyncOptionalValue(nil, nil)
        expect(value).to(beNil())
    }

    func testErrorIsThrownWhenNestedInContinuationReturningNonOptional() async throws {
        do {
            _ = try await self.asyncValue(nil, .error1)
            fail("Expected an error to be thrown")
        } catch {
            expect(error).to(matchError(Error.error1))
        }
    }

    func testValueIsReturnedWhenNestedInContinuationReturningNonOptional() async throws {
        let value = try await self.asyncValue("1", nil)
        expect(value) == "1"
    }

    private func completionAPI(_ value: String?,
                               _ error: Error?,
                               completion: @escaping (String?, Error?) -> Void) {
        completion(value, error)
    }

    /// `Success` can be inferred as either `String` or `String?` here.
    private func asyncOptionalValue(_ value: String?, _ error: Error?) async throws -> String? {
        return try await withUnsafeThrowingContinuation { continuation in
            self.completionAPI(value, error) { value, error in
                continuation.resume(with: Result(value, error))
            }
        }
    }

    /// `Success` can only be inferred as `String`. This is the shape of most of the SDK's
    /// completion-handler-to-`async` wrappers.
    private func asyncValue(_ value: String?, _ error: Error?) async throws -> String {
        return try await withUnsafeThrowingContinuation { continuation in
            self.completionAPI(value, error) { value, error in
                continuation.resume(with: Result(value, error))
            }
        }
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
