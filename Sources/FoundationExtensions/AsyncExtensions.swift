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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
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
        return try await withCheckedThrowingContinuation { continuation in
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
        return await withCheckedContinuation { continuation in
            @Sendable
            func complete(_ value: Value) {
                continuation.resume(with: .success(value))
            }

            method(complete)
        }
    }

}
