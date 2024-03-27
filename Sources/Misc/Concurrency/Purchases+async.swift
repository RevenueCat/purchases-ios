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
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
extension Purchases {

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

    func logInAsync(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            logIn(appUserID) { customerInfo, created, error in
                continuation.resume(with: Result(customerInfo, error)
                                        .map { ($0, created) })
            }
        }
    }

    func logOutAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            logOut { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            }
        }
    }

    #endif

    func offeringsAsync(fetchPolicy: OfferingsManager.FetchPolicy) async throws -> Offerings {
        return try await withCheckedThrowingContinuation { continuation in
            self.getOfferings(fetchPolicy: fetchPolicy) { offerings, error in
                continuation.resume(with: Result(offerings, error))
            }
        }
    }

    func productsAsync(_ productIdentifiers: [String]) async -> [StoreProduct] {
        return await withCheckedContinuation { continuation in
            getProducts(productIdentifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func purchaseAsync(product: StoreProduct) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(product: product) { transaction, customerInfo, error, userCancelled in
                continuation.resume(with: Result(customerInfo, error)
                                        .map { PurchaseResultData(transaction, $0, userCancelled) })
            }
        }
    }

    func purchaseAsync(package: Package) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(package: package) { transaction, customerInfo, error, userCancelled in
                continuation.resume(with: Result(customerInfo, error)
                                        .map { PurchaseResultData(transaction, $0, userCancelled) })
            }
        }
    }

    func restorePurchasesAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            self.restorePurchases { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            }
        }
    }

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

    func syncPurchasesAsync() async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            syncPurchases { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            }
        }
    }

    func purchaseAsync(product: StoreProduct, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(product: product,
                     promotionalOffer: promotionalOffer) { transaction, customerInfo, error, userCancelled in
                continuation.resume(with: Result(customerInfo, error)
                                        .map { PurchaseResultData(transaction, $0, userCancelled) })
            }
        }
    }

    func purchaseAsync(package: Package, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        return try await withCheckedThrowingContinuation { continuation in
            purchase(package: package,
                     promotionalOffer: promotionalOffer) { transaction, customerInfo, error, userCancelled in
                continuation.resume(with: Result(customerInfo, error)
                                        .map { PurchaseResultData(transaction, $0, userCancelled) })
            }
        }
    }

    func customerInfoAsync(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo {
        return try await withCheckedThrowingContinuation { continuation in
            getCustomerInfo(fetchPolicy: fetchPolicy) { customerInfo, error in
                continuation.resume(with: Result(customerInfo, error))
            }
        }
    }

    func checkTrialOrIntroductoryDiscountEligibilityAsync(_ product: StoreProduct) async
    -> IntroEligibilityStatus {
        return await withCheckedContinuation { continuation in
            checkTrialOrIntroDiscountEligibility(product: product) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func checkTrialOrIntroductoryDiscountEligibilityAsync(_ productIdentifiers: [String]) async
    -> [String: IntroEligibility] {
        return await withCheckedContinuation { continuation in
            checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func promotionalOfferAsync(forProductDiscounts discounts: [StoreProductDiscount],
                               product: StoreProduct) async throws -> PromotionalOffer {
        return try await withCheckedThrowingContinuation { continuation in
            self.getPromotionalOffer(forProductDiscounts: discounts, product: product) { offer, error in
                continuation.resume(with: Result(offer, error))
             }
         }
     }

    func eligiblePromotionalOffersAsync(forProduct product: StoreProduct) async -> [PromotionalOffer] {
        let discounts = product.discounts

        // TODO:  use all of these

        return await withTaskGroup(of: Optional<PromotionalOffer>.self) { group in
            for discount in discounts {
                group.addTask {
                    do {
                        return try await self.promotionalOffer(
                            forProductDiscount: discount,
                            product: product
                        )
                    } catch RCErrorCode.ineligibleError {
                        return nil
                    } catch {
                        Logger.error(
                            Strings.eligibility.check_eligibility_failed(
                                productIdentifier: product.productIdentifier,
                                error: error
                            )
                        )
                        return nil
                    }
                }
            }

            var result: [PromotionalOffer] = []

            for await offer in group {
                if let offer = offer {
                    result.append(offer)
                }
            }

            return result
        }
    }

    #endif

#if os(iOS) || os(macOS) || VISION_OS

    @available(iOS 13.0, macOS 10.15, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscriptionsAsync() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            showManageSubscriptions { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

#endif

}
