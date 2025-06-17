//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferEligibilityContext.swift
//
//  Created by Josh Holtz on 6/16/25.

import Combine
import RevenueCat
import StoreKit

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PromotionalOfferEligibilityContext: ObservableObject {

    typealias ProductID = String

    enum Status: Equatable {
        case unknown
        case ineligible
        case unsignedEligible
        case signedEligible(PromotionalOffer)
    }

    @Published
    private(set) var cache: [ProductID: Status] = [:]

    func computeEligibility(for packageInfos: [PaywallState.PackageInfo]) async {
        await self.checkUnsignedEligibility(packageInfos: packageInfos)
        await self.checkSignedEligibility(packageInfos: packageInfos)
    }

    /// Checks eligibility only for packages currently marked as `.unknown`,
    /// and updates the cache with `.ineligible` or `.unsignedEligible`.
    private func checkUnsignedEligibility(packageInfos: [PaywallState.PackageInfo]) async {
        // 1. Collect current entitlements (active subscriptions)
        var activeEntitlements: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                activeEntitlements.insert(transaction.productID)
            }
        }

        // 2. For each package, check eligibility only if its status is `.unknown`
        for packageInfo in packageInfos {
            let productID = packageInfo.package.storeProduct.productIdentifier

            if cache[productID] != .unknown {
                continue
            }

            if activeEntitlements.contains(productID) {
                cache[productID] = .ineligible
                continue
            }

            if let latest = await StoreKit.Transaction.latest(for: productID),
               case .verified(let transaction) = latest {

                if let expirationDate = transaction.expirationDate {
                    cache[productID] = expirationDate < Date() ? .unsignedEligible : .ineligible
                } else {
                    cache[productID] = .ineligible
                }
            } else {
                cache[productID] = .ineligible
            }
        }
    }

    /// Attempts to create signed promotional offers for packages that are eligible.
    private func checkSignedEligibility(packageInfos: [PaywallState.PackageInfo]) async {
        for packageInfo in packageInfos {
            let storeProduct = packageInfo.package.storeProduct
            if let productCode = packageInfo.promotionalOfferProductCode,
               let discount = storeProduct.discounts.first(where: { $0.offerIdentifier == productCode }) {

                do {
                    let promoOffer = try await Purchases.shared.promotionalOffer(
                        forProductDiscount: discount,
                        product: storeProduct
                    )
                    cache[storeProduct.productIdentifier] = .signedEligible(promoOffer)
                } catch {
                    // Not eligible or signing failed — leave status unchanged
                    print("Signed offer creation failed for \(storeProduct.productIdentifier): \(error)")
                }
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PromotionalOfferEligibilityContext {

    /// Returns whether a user is likely eligible for a given package's offer.
    func isMostLikelyEligible(for package: Package?) -> Bool {
        guard let package else {
            return false
        }

        let status = cache[package.storeProduct.productIdentifier] ?? .unknown

        switch status {
        case .unknown, .ineligible:
            return false
        case .unsignedEligible, .signedEligible:
            return true
        }
    }

    /// Returns the signed promotional offer, if one was successfully generated.
    func get(for package: Package?) -> PromotionalOffer? {
        guard let package else {
            return nil
        }

        let status = cache[package.storeProduct.productIdentifier] ?? .unknown

        switch status {
        case .signedEligible(let promoOffer):
            return promoOffer
        default:
            return nil
        }
    }
}

#endif
