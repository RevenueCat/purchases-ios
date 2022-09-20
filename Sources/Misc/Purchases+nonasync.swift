//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+nonasync.swift
//
//  Created by Nacho Soto on 8/22/22.

import Foundation

// Docs inherited from `PurchasesSwiftType`.
// swiftlint:disable missing_docs

/// This extension holds the biolerplate logic to convert async methods to completion blocks APIs.
/// Because `async` APIs are implicitly available in Objective-C, these can be Swift only.
public extension Purchases {

    #if os(iOS)

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(
        forProduct productID: String,
        completion: @escaping (Result<RefundRequestStatus, PublicError>) -> Void
    ) {
        call(with: completion) {
            try await self.beginRefundRequest(forProduct: productID)
        }
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(
        forEntitlement entitlementID: String,
        completion: @escaping (Result<RefundRequestStatus, PublicError>) -> Void
    ) {
        call(with: completion) {
            try await self.beginRefundRequest(forEntitlement: entitlementID)
        }
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequestForActiveEntitlement(
        completion: @escaping (Result<RefundRequestStatus, PublicError>) -> Void
    ) {
        call(with: completion) {
            try await self.beginRefundRequestForActiveEntitlement()
        }
    }

    #endif

}

/// Invokes an `async throws` method and calls `completion` with the result.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private func call<T>(
    with completion: @escaping (Result<T, PublicError>) -> Void,
    asyncMethod method: @escaping () async throws -> T
) {
    _ = Task {
        do {
            completion(.success(try await method()))
        } catch {
            completion(.failure(ErrorUtils.purchasesError(withUntypedError: error).asPublicError))
        }
    }
}
