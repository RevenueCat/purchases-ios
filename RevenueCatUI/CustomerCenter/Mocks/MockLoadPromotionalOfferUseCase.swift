//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockLoadPromotionalOfferUseCase.swift
//
//  Created by Cesar de la Vega on 10/2/25.

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class MockLoadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType {

    var offerToLoadPromoFor: RevenueCat.CustomerCenterConfigData.HelpPath.PromotionalOffer?

    var mockedProduct: StoreProduct?
    var mockedPromotionalOffer: PromotionalOffer?
    var mockedPromoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer?

    func execute(
        promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer,
        forProductId: String?
    ) async -> Result<PromotionalOfferData, Error> {
        self.offerToLoadPromoFor = promoOfferDetails
        if let mockedProduct = mockedProduct,
           let mockedPromotionalOffer = mockedPromotionalOffer,
           let mockedPromoOfferDetails = mockedPromoOfferDetails {
            return .success(PromotionalOfferData(promotionalOffer: mockedPromotionalOffer,
                                                 product: mockedProduct,
                                                 promoOfferDetails: mockedPromoOfferDetails))
        } else {
            return .failure(CustomerCenterError.couldNotFindOfferForActiveProducts)
        }

    }

}
