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

/// This extension holds the biolerplate logic to convert methods with completion blocks into async / await syntax.
extension Purchases {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func logInAsync(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            logIn(appUserID) { customerInfo, created, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: (customerInfo, created))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func logOutAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            logOut { customerInfo, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: customerInfo)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func offeringsAsync() async throws -> Offerings {
        return try await withCheckedThrowingContinuation { continuation in
            getOfferings { offerings, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let offerings = offerings else {
                    fatalError("Expected non-nil result 'result' for nil error")
                }
                continuation.resume(returning: offerings)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func customerInfoAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            getCustomerInfo { customerInfo, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: customerInfo)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func productsAsync(_ productIdentifiers: [String]) async -> [StoreProduct] {
        return await withCheckedContinuation { continuation in
            getProducts(productIdentifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchaseAsync(product: StoreProduct) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(product: product) { transaction, customerInfo, error, userCancelled in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchaseAsync(package: Package) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(package: package) { transaction, customerInfo, error, userCancelled in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchaseAsync(product: StoreProduct, discount: StoreProductDiscount) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(product: product,
                     discount: discount) { transaction, customerInfo, error, userCancelled in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func purchaseAsync(package: Package, discount: StoreProductDiscount) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(package: package,
                     discount: discount) { transaction, customerInfo, error, userCancelled in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }

                continuation.resume(returning: (transaction, customerInfo, userCancelled))
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func syncPurchasesAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            syncPurchases { customerInfo, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: customerInfo)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func restorePurchasesAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            restorePurchases { customerInfo, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let customerInfo = customerInfo else {
                    fatalError("Expected non-nil result 'customerInfo' for nil error")
                }
                continuation.resume(returning: customerInfo)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func checkTrialOrIntroductoryDiscountEligibilityAsync(_ productIdentifiers: [String]) async
    -> [String: IntroEligibility] {
        return await withCheckedContinuation { continuation in
            checkTrialOrIntroDiscountEligibility(productIdentifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
     func checkPromotionalDiscountEligibilityAsync(forProductDiscount discount: StoreProductDiscount,
                                                   product: StoreProduct) async throws -> PromotionalOfferEligibility {
         return try await withCheckedThrowingContinuation { continuation in
             checkPromotionalDiscountEligibility(forProductDiscount: discount, product: product) { isEligible, error in
                 if let error = error {
                     continuation.resume(throwing: error)
                     return
                 }
                 continuation.resume(returning: isEligible)
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
