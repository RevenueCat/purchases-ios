//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiscountsHandler.swift
//
//  Created by Facundo Menzella on 14/5/25.

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DiscountsHandler {

    private let purchasesProvider: CustomerCenterPurchasesType

    init(purchasesProvider: CustomerCenterPurchasesType) {
        self.purchasesProvider = purchasesProvider
    }

    func findDiscount(
        for activeProduct: StoreProduct,
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) async throws -> (StoreProductDiscount, StoreProduct) {
        let productIdentifier = activeProduct.productIdentifier
        // First try cross-product promotions if available
        if let crossProductPromotion = promoOfferDetails.crossProductPromotions[productIdentifier] {
            let (discount, targetProduct) = try await findCrossProductDiscount(
                for: crossProductPromotion,
                productIdentifier: productIdentifier
            )
            return (discount, targetProduct)
        }

        // Fall back to existing logic if no cross-product promotions
        let discount = !promoOfferDetails.productMapping.isEmpty
            ? findMappedDiscount(for: activeProduct,
                                 productIdentifier: productIdentifier,
                                 promoOfferDetails: promoOfferDetails)
            : findLegacyDiscount(for: activeProduct, promoOfferDetails: promoOfferDetails)

        guard let discount = discount else {
            logDiscountError(productIdentifier: productIdentifier, promoOfferDetails: promoOfferDetails)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        return (discount, activeProduct)
    }

    // MARK: - Private helpers

    private func findCrossProductDiscount(
        for crossProductPromotion: CustomerCenterConfigData.HelpPath.PromotionalOffer.CrossProductPromotion,
        productIdentifier: String
    ) async throws -> (StoreProductDiscount, StoreProduct) {
        let targetProducts = await self.purchasesProvider.products([crossProductPromotion.targetProductId])
        guard let targetProduct = targetProducts.first else {
            Logger.warning(Strings.could_not_find_target_product(
                crossProductPromotion.targetProductId,
                productIdentifier
            ))
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        guard let discount = targetProduct.discounts.first(where: {
            $0.offerIdentifier == crossProductPromotion.storeOfferIdentifier
        }) else {
            Logger.warning(Strings.could_not_find_discount_for_target_product(
                crossProductPromotion.storeOfferIdentifier,
                targetProduct.productIdentifier
            ))
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        return (discount, targetProduct)
    }

    private func findMappedDiscount(
        for product: StoreProduct,
        productIdentifier: String,
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) -> StoreProductDiscount? {
        product.discounts.first {
            $0.offerIdentifier == promoOfferDetails.productMapping[productIdentifier]
        }
    }

    private func findLegacyDiscount(
        for product: StoreProduct,
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) -> StoreProductDiscount? {
        // Try exact match first
        if let exactMatch = product.discounts.first(where: {
            $0.offerIdentifier == promoOfferDetails.iosOfferId
        }) {
            return exactMatch
        }

        // Fall back to suffix matching
        return product.discounts.first {
            $0.offerIdentifier?.hasSuffix("_\(promoOfferDetails.iosOfferId)") == true
        }
    }

    private func logDiscountError(
        productIdentifier: String,
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) {
        let message = !promoOfferDetails.productMapping.isEmpty
            ? Strings.could_not_offer_for_active_subscriptions(
                promoOfferDetails.productMapping[productIdentifier] ?? "nil",
                productIdentifier
            )
            : Strings.could_not_offer_for_active_subscriptions(
                promoOfferDetails.iosOfferId,
                productIdentifier
            )
        Logger.debug(message)
    }

}

#endif
