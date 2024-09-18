//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncExtensions.swift
//
//  Created by Nacho Soto on 9/27/22.

import Foundation

internal enum Async {

    /// Invokes an `async throws` method and calls `completion` with the result.
    /// Ensures that the returned error is `PublicError`.
    ///
    /// Example:
    /// ```swift
    /// Async.call(with: completion) {
    ///     return try await asynchronousMethod()
    /// }
    /// ```
    static func call<T>(
        with completion: @escaping (Result<T, PublicError>) -> Void,
        asyncMethod method: @escaping () async throws -> T
    ) {
        _ = Task<Void, Never> {
            do {
                completion(.success(try await method()))
            } catch {
                completion(.failure(ErrorUtils.purchasesError(withUntypedError: error).asPublicError))
            }
        }
    }

    /// Invokes an `async throws` method and calls `completion` with the result.
    /// Ensures that the returned error is `PurchasesError`.
    ///
    /// Example:
    /// ```swift
    /// Async.call(with: completion) {
    ///     return try await asynchronousMethod()
    /// }
    /// ```
    static func call<T>(
        with completion: @escaping (Result<T, PurchasesError>) -> Void,
        asyncMethod method: @escaping () async throws -> T
    ) {
        _ = Task<Void, Never> {
            do {
                completion(.success(try await method()))
            } catch {
                completion(.failure(ErrorUtils.purchasesError(withUntypedError: error)))
            }
        }
    }

    /// Invokes an `async` non-throwing method and calls `completion` with the result.
    static func call<T>(
        with completion: @escaping (T) -> Void,
        asyncMethod method: @escaping () async -> T
    ) {
        _ = Task<Void, Never> {
            completion(await method())
        }
    }

    /// Invokes a completion-block based API and returns the `throw`ing method `async`hronously.
    ///
    /// Example:
    /// ```swift
    /// let result = try await Async.call { completion in
    ///     completionBlockAPI(completion)
    /// }
    /// ```
    static func call<Value, Error: Swift.Error>(
        method: (@escaping @Sendable (Result<Value, Error>) -> Void) -> Void
    ) async throws -> Value {
        return try await withUnsafeThrowingContinuation { continuation in
            @Sendable
            func complete(_ result: Result<Value, Error>) {
                continuation.resume(with: result)
            }

            method(complete)
        }
    }

    /// Invokes a completion-block based API and returns the method `async`hronously.
    ///
    /// Example:
    /// ```swift
    /// let result = await Async.call { completion in
    ///     completionBlockAPI(completion)
    /// }
    /// ```
    static func call<Value>(
        method: (@escaping @Sendable (Value) -> Void) -> Void
    ) async -> Value {
        // Note: We're using UnsafeContinuation instead of Checked because
        // of a crash in iOS 18.0 devices when CheckedContinuations are used.
        // See: https://github.com/RevenueCat/purchases-ios/issues/4177
        return await withUnsafeContinuation { continuation in
            @Sendable
            func complete(_ value: Value) {
                continuation.resume(with: .success(value))
            }

            method(complete)
        }
    }

    /// Runs the given block `maximumRetries` times at most, at `pollInterval` times until the
    /// block returns a tuple where the first argument `shouldRetry` is false, and the second is the expected value.
    /// After the maximum retries, returns the last seen value.
    ///
    /// Example:
    /// ```swift
    /// let receipt = await Async.retry {
    ///     let receipt = fetchReceipt()
    ///     if receipt.contains(transaction) {
    ///         return (shouldRetry: false, receipt)
    ///     } else {
    ///         return (shouldRetry: true, receipt)
    ///     }
    /// }
    /// ```
    static func retry<T>(
        maximumRetries: Int = 5,
        pollInterval: DispatchTimeInterval = .milliseconds(300),
        until value: @Sendable () async -> (shouldRetry: Bool, result: T)
    ) async -> T {
        var lastValue: T
        var retries = 0

        repeat {
            retries += 1
            let (shouldRetry, result) = await value()
            if shouldRetry {
                lastValue = result
                try? await Task.sleep(nanoseconds: UInt64(pollInterval.nanoseconds))
            } else {
                return result
            }
        } while !(retries > maximumRetries)

        return lastValue
    }

}

internal extension AsyncSequence {

    /// Returns the elements of the asynchronous sequence.
    func extractValues() async rethrows -> [Element] {
        return try await self.reduce(into: []) {
            $0.append($1)
        }
    }

}

internal extension AsyncSequence {

    func toAsyncStream() -> AsyncStream<Element> {
        var asyncIterator = self.makeAsyncIterator()
        return AsyncStream<Element> {
            try? await asyncIterator.next()
        }
    }

}
