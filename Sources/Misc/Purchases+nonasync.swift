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

/// This extension holds the biolerplate logic to convert async methods to completion blocks APIs.
/// Because `async` APIs are implicitly available in Objective-C, these can be Swift only.
public extension Purchases {

    #if os(iOS)
    /**
     * Presents a refund request sheet in the current window scene for
     * the latest transaction associated with the `productID`
     *
     * - Parameter productID: The `productID` to begin a refund request for.
     * - Parameter completion: A completion block that is called when the ``RefundRequestStatus`` is returned.
     * Keep in mind the status could be ``RefundRequestStatus/userCancelled``
     * If the request was unsuccessful, no active entitlements could be found for the user,
     * or multiple active entitlements were found for the user, an `Error` will be thrown.
     */
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(
        forProduct productID: String,
        completion: @escaping (Result<RefundRequestStatus, Error>) -> Void
    ) {
        call(with: completion) {
            try await self.beginRefundRequest(forProduct: productID)
        }
    }

    /**
     * Presents a refund request sheet in the current window scene for
     * the latest transaction associated with the entitlement ID.
     *
     * - Parameter entitlementID: The entitlementID to begin a refund request for.
     * - Parameter completion: A completion block that is called when the ``RefundRequestStatus`` is returned.
     * Keep in mind the status could be ``RefundRequestStatus/userCancelled``
     * If the request was unsuccessful, no active entitlements could be found for the user,
     * or multiple active entitlements were found for the user, an `Error` will be thrown.
     */
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(
        forEntitlement entitlementID: String,
        completion: @escaping (Result<RefundRequestStatus, Error>) -> Void
    ) {
        call(with: completion) {
            try await self.beginRefundRequest(forEntitlement: entitlementID)
        }
    }

    /**
     * Presents a refund request sheet in the current window scene for
     * the latest transaction associated with the active entitlement.
     *
     * - Parameter completion: A completion block that is called when the ``RefundRequestStatus`` is returned.
     * Keep in mind the status could be ``RefundRequestStatus/userCancelled``
     * If the request was unsuccessful, no active entitlements could be found for the user,
     * or multiple active entitlements were found for the user, an `Error` will be thrown.
     *
     * - Important: This method should only be used if your user can only
     * have a single active entitlement at a given time.
     * If a user could have more than one entitlement at a time, use ``beginRefundRequest(forEntitlement:)`` instead.
     */
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequestForActiveEntitlement(
        completion: @escaping (Result<RefundRequestStatus, Error>) -> Void
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
    with completion: @escaping (Result<T, Error>) -> Void,
    asyncMethod method: @escaping () async throws -> T
) {
    _ = Task {
        do {
            completion(.success(try await method()))
        } catch {
            completion(.failure(error))
        }
    }
}
