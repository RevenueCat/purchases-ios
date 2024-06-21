//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferViewModel.swift
//
//
//  Created by Cesar de la Vega on 17/6/24.
//

import Foundation
import RevenueCat

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class PromotionalOfferViewModel: ObservableObject {

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo

    @Published
    var product: StoreProduct?
    @Published
    var promotionalOffer: PromotionalOffer?
    @Published
    var transaction: StoreTransaction?

    private var customerInfoFetcher: CustomerInfoFetcher

    convenience init() {
        self.init(product: nil, promotionalOffer: nil)
    }

    convenience init(product: StoreProduct?,
                     promotionalOffer: PromotionalOffer?) {
        self.init(product: product,
                  promotionalOffer: promotionalOffer,
                  customerInfoFetcher: {
            guard Purchases.isConfigured else {
                throw PaywallError.purchasesNotConfigured
            }

            return try await Purchases.shared.customerInfo()
        })
    }

    // @PublicForExternalTesting
    init(product: StoreProduct?,
         promotionalOffer: PromotionalOffer?,
         customerInfoFetcher: @escaping CustomerInfoFetcher) {
        self.product = product
        self.promotionalOffer = promotionalOffer
        self.customerInfoFetcher = customerInfoFetcher
    }

    func purchasePromo() async {
        guard let promotionalOffer = self.promotionalOffer,
              let product = self.product else {
            print("Promotional offer not loaded")
            return
        }
        do {
            let purchase = try await Purchases.shared.purchase(product: product, promotionalOffer: promotionalOffer)
            self.transaction = purchase.transaction
        } catch {
            print("Error purchasing product with promotional offer: \(error)")
        }
    }

    func loadPromo(promotionalOfferId: String) async {
        do {
            let customerInfo = try await self.customerInfoFetcher()
            let activeSubscriptionProductIds = customerInfo.activeSubscriptions

            guard let appStoreSubscription = customerInfo.entitlements.active.first(where: {
                $0.value.store == .appStore
            }) else {
                print("No active App Store subscriptions found")
                return
            }

            let productId = appStoreSubscription.value.productIdentifier
            let products = await Purchases.shared.products([productId])
            guard let product = products.first(where: { product in
                product.discounts.contains { $0.offerIdentifier == promotionalOfferId }
            }) else {
                print("No active product found with the given promotional offer ID")
                return
            }

            self.product = product

            if let discount = product.discounts.first(where: { $0.offerIdentifier == promotionalOfferId }) {
                do {
                    let promotionalOffer = try await Purchases.shared.promotionalOffer(forProductDiscount: discount,
                                                                                       product: product)
                    self.promotionalOffer = promotionalOffer
                } catch {
                    print("Error fetching promotional offer")
                    return
                }
            }
        } catch {
            print("Error fetching promotional offer for active product: \(error)")
            return
        }
    }

}

#endif
