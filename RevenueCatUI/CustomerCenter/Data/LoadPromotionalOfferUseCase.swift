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
//
//  LoadPromotionalOfferUseCase.swift
//
//  Copyright RevenueCat Inc. All Rights Reserved.
//  Licensed under the MIT License (https://opensource.org/licenses/MIT)
//  Created by Cesar de la Vega on 18/7/24.
//

import Foundation
@_spi(Internal) import RevenueCat

protocol LoadPromotionalOfferUseCaseType {
    func execute(
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer,
        forProductId productIdentifier: String?
    ) async -> Result<PromotionalOfferData, Error>
}

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class LoadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType {

    private let purchasesProvider: CustomerCenterPurchasesType

    init(purchasesProvider: CustomerCenterPurchasesType) {
        self.purchasesProvider = purchasesProvider
    }

    func execute(
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer,
        forProductId productIdentifier: String?
    ) async -> Result<PromotionalOfferData, Error> {
        do {
            guard let productIdentifier else {
                return .failure(CustomerCenterError.couldNotFindOfferForActiveProducts)
            }

            let subscribedProduct = try await getActiveSubscription(productIdentifier)

            let discountFinder = DiscountsHandler(purchasesProvider: self.purchasesProvider)
            let (discount, targetProduct) = try await discountFinder.findDiscount(
                for: subscribedProduct,
                promoOfferDetails: promoOfferDetails
            )

            let promotionalOffer = try await self.purchasesProvider.promotionalOffer(
                forProductDiscount: discount,
                product: targetProduct
            )

            return .success(PromotionalOfferData(
                promotionalOffer: promotionalOffer,
                product: targetProduct,
                promoOfferDetails: promoOfferDetails
            ))
        } catch {
            Logger.warning(Strings.error_fetching_promotional_offer(error))
            return .failure(CustomerCenterError.couldNotFindOfferForActiveProducts)
        }
    }

    private func getActiveSubscription(_ productId: String) async throws -> StoreProduct {
        guard let subscribedProduct = await self.purchasesProvider.products([productId]).first else {
            Logger.warning(Strings.could_not_offer_for_any_active_subscriptions)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }
        return subscribedProduct
    }

}

#endif
