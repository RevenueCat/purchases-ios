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
            let customerInfo = try await self.purchasesProvider.customerInfo()

            guard let productIdentifier = customerInfo.earliestExpiringAppStoreEntitlement()?.productIdentifier,
                  let subscribedProduct = await self.purchasesProvider.products([productIdentifier]).first else {
                Logger.warning(Strings.could_not_offer_for_any_active_subscriptions)
                return .failure(CustomerCenterError.couldNotFindSubscriptionInformation)
            }

            guard let discount = subscribedProduct.discounts.first(where: {
                $0.offerIdentifier == promoOfferDetails.iosOfferId
            }) else {
                let message =
                Strings.could_not_offer_for_active_subscriptions(promoOfferDetails.iosOfferId, productIdentifier)
                Logger.debug(message)
                return .failure(CustomerCenterError.couldNotFindSubscriptionInformation)
            }

            let promotionalOffer = try await self.purchasesProvider.promotionalOffer(forProductDiscount: discount,
                                                                                     product: subscribedProduct)
            let promotionalOfferData = PromotionalOfferData(promotionalOffer: promotionalOffer,
                                                            product: subscribedProduct,
                                                            promoOfferDetails: promoOfferDetails)
            return .success(promotionalOfferData)
        } catch {
            Logger.warning(Strings.error_fetching_promotional_offer(error))
            return .failure(CustomerCenterError.couldNotFindOfferForActiveProducts)
        }
    }

}

#endif
