//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LoadPromotionalOfferUseCase.swift
//
//  Created by Cesar de la Vega on 18/7/24.

import Foundation
import RevenueCat

protocol LoadPromotionalOfferUseCaseType {

    func execute(
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) async -> Result<PromotionalOfferData, Error>

}

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class LoadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType {

    private let purchasesProvider: CustomerCenterPurchasesType

    init(purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases()) {
        self.purchasesProvider = purchasesProvider
    }

    func execute(
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) async -> Result<PromotionalOfferData, Error> {
        do {
            let customerInfo = try await self.purchasesProvider.customerInfo(fetchPolicy: .default)

            let subscribedProduct = try await getActiveSubscription(customerInfo)
            let discount = try findDiscount(for: subscribedProduct,
                                            productIdentifier: subscribedProduct.productIdentifier,
                                            promoOfferDetails: promoOfferDetails)

            let promotionalOffer = try await self.purchasesProvider.promotionalOffer(
                forProductDiscount: discount,
                product: subscribedProduct
            )
            return .success(PromotionalOfferData(
                promotionalOffer: promotionalOffer,
                product: subscribedProduct,
                promoOfferDetails: promoOfferDetails
            ))
        } catch {
            Logger.warning(Strings.error_fetching_promotional_offer(error))
            return .failure(CustomerCenterError.couldNotFindOfferForActiveProducts)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension LoadPromotionalOfferUseCase {

    private func getActiveSubscription(_ customerInfo: CustomerInfo) async throws -> StoreProduct {
        guard let productIdentifier = customerInfo.earliestExpiringAppStoreEntitlement()?.productIdentifier,
              let subscribedProduct = await self.purchasesProvider.products([productIdentifier]).first else {
            Logger.warning(Strings.could_not_offer_for_any_active_subscriptions)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }
        return subscribedProduct
    }

    private func findDiscount(
        for product: StoreProduct,
        productIdentifier: String,
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) throws -> StoreProductDiscount {
        let discount = !promoOfferDetails.productMapping.isEmpty
            ? findMappedDiscount(for: product,
                                 productIdentifier: productIdentifier,
                                 promoOfferDetails: promoOfferDetails)
            : findLegacyDiscount(for: product, promoOfferDetails: promoOfferDetails)

        guard let discount = discount else {
            logDiscountError(productIdentifier: productIdentifier, promoOfferDetails: promoOfferDetails)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        return discount
    }

    private func findMappedDiscount(
        for product: StoreProduct,
        productIdentifier: String,
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer
    ) -> StoreProductDiscount? {
        product.discounts.first { $0.offerIdentifier == promoOfferDetails.productMapping[productIdentifier] }
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
        return product.discounts.first { $0.offerIdentifier?.hasSuffix("_\(promoOfferDetails.iosOfferId)") == true }
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
