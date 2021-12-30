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

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func logInAsync(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
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

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func productsAsync(_ productIdentifiers: [String]) async -> [SKProduct] {
        return await withCheckedContinuation { continuation in
            getProducts(productIdentifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func purchaseAsync(product: SKProduct) async throws ->
    // swiftlint:disable:next large_tuple
    (transaction: SKPaymentTransaction, customerInfo: CustomerInfo, userCancelled: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(product: product) { maybeTransaction, maybeCustomerInfo, maybeError, userCancelled in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = maybeCustomerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                guard let transaction = maybeTransaction else {
                    fatalError("Expected non-nil result 'transaction' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func purchaseAsync(package: Package) async throws ->
    // swiftlint:disable:next large_tuple
    (transaction: SKPaymentTransaction, customerInfo: CustomerInfo, userCancelled: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(package: package) { maybeTransaction, maybeCustomerInfo, maybeError, userCancelled in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = maybeCustomerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                guard let transaction = maybeTransaction else {
                    fatalError("Expected non-nil result 'transaction' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func purchaseAsync(product: SKProduct, discount: SKPaymentDiscount) async throws ->
    // swiftlint:disable:next large_tuple
    (transaction: SKPaymentTransaction, customerInfo: CustomerInfo, userCancelled: Bool) {

        return try await withCheckedThrowingContinuation { continuation in
            purchase(product: product,
                     discount: discount) { maybeTransaction, maybeCustomerInfo, maybeError, userCancelled in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = maybeCustomerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                guard let transaction = maybeTransaction else {
                    fatalError("Expected non-nil result 'transaction' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func purchaseAsync(package: Package, discount: SKPaymentDiscount) async throws ->
    // swiftlint:disable:next large_tuple
    (transaction: SKPaymentTransaction, customerInfo: CustomerInfo, userCancelled: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(package: package,
                     discount: discount) { maybeTransaction, maybeCustomerInfo, maybeError, userCancelled in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = maybeCustomerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                guard let transaction = maybeTransaction else {
                    fatalError("Expected non-nil result 'transaction' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func syncPurchasesAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            syncPurchases { maybeCustomerInfo, maybeError in
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

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func restoreTransactionsAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            restoreTransactions { maybeCustomerInfo, maybeError in
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

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func checkTrialOrIntroductoryPriceEligibilityAsync(_ productIdentifiers: [String]) async
    -> [String: IntroEligibility] {
        return await withCheckedContinuation { continuation in
            checkTrialOrIntroductoryPriceEligibility(productIdentifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func paymentDiscountAsync(forProductDiscount discount: SKProductDiscount,
                              product: SKProduct) async throws -> SKPaymentDiscount {
        return try await withCheckedThrowingContinuation { continuation in
            paymentDiscount(forProductDiscount: discount, product: product) { maybeDiscount, maybeError in
                if let error = maybeError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let discount = maybeDiscount else {
                    fatalError("Expected non-nil 'discount' for nil error")
                }
                continuation.resume(returning: discount)
            }
        }
    }

#if os(iOS) || os(macOS)

    @available(iOS 13.0, macOS 10.15, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscriptionsAsync() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            showManageSubscriptions { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

#endif

}
