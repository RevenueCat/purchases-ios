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

    #if os(iOS) || VISION_OS

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

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showStoreMessages(
        for types: Set<StoreMessageType> = Set(StoreMessageType.allCases),
        completion: @escaping () -> Void
    ) {
        _ = Task<Void, Never> {
            await self.showStoreMessages(for: types)
            completion()
        }
    }

    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @objc(showStoreMessagesWithCompletion:)
    func showStoreMessages(completion: @escaping () -> Void) {
        _ = Task<Void, Never> {
            await self.showStoreMessages(for: Set(StoreMessageType.allCases))
            completion()
        }
    }

    /**
     Calls `showStoreMessages(for:completion:)` with a set of store message types.
     
     - Parameter types: An `NSSet` containing items representing store message types.
       Each item should be either a `StoreMessageType` (backed by `NSNumber`) or an `NSNumber` 
       representing the raw value of a `StoreMessageType`.
     - Parameter completion: A closure called once store messages have been shown.
     
     If an item in `types` cannot be interpreted as a `StoreMessageType` raw value, it will be ignored.
     */
    @available(iOS 16.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @objc(showStoreMessagesForTypes:completion:)
    func showStoreMessages(forTypes types: NSSet, completion: @escaping () -> Void) {
        let storeMessageTypes = Set(
            types.compactMap { ($0 as? NSNumber)?.intValue }
                .compactMap { StoreMessageType(rawValue: $0) }
        )
        _ = Task<Void, Never> {
            await self.showStoreMessages(for: storeMessageTypes)
            completion()
        }
    }

    #endif

}
