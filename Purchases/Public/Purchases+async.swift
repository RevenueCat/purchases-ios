//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+async.swift
//
//  Created by Andrés Boedo on 24/11/21.

import Foundation
import StoreKit

/// This extension holds the biolerplate logic to convert methods with completion blocks into async / await syntax.
extension Purchases {

    @available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 8.0, *)
    func logInAsync(_ appUserID: String) async throws -> (CustomerInfo, Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            logIn(appUserID) { maybeCustomerInfo, created, maybeError in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = maybeCustomerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: (customerInfo, created))
            }
        }
    }

    @available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 8.0, *)
    func logOutAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            logOut { maybeCustomerInfo, maybeError in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = maybeCustomerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: customerInfo)
            }
        }
    }

    @available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 8.0, *)
    func offeringsAsync() async throws -> Offerings {
        return try await withCheckedThrowingContinuation { continuation in
            getOfferings { maybeOfferings, maybeError in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let offerings = maybeOfferings else {
                    fatalError("Expected non-nil result 'result' for nil error")
                }
                continuation.resume(returning: offerings)
            }
        }
    }

    @available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 8.0, *)
    func customerInfoAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            getCustomerInfo { maybeCustomerInfo, maybeError in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = maybeCustomerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: customerInfo)
            }
        }
    }

    @available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 8.0, *)
    func productsAsync(_ productIdentifiers: [String]) async -> [SKProduct] {
        return await withCheckedContinuation { continuation in
            getProducts(productIdentifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }


}
