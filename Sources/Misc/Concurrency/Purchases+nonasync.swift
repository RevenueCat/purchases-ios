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
        Async.call(with: completion) {
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
        Async.call(with: completion) {
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
        Async.call(with: completion) {
            try await self.beginRefundRequestForActiveEntitlement()
        }
    }

    #endif

}
