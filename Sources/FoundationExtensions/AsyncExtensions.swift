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

}
