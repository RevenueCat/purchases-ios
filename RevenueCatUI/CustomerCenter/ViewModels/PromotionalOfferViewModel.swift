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
import SwiftUI

import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class PromotionalOfferViewModel: ObservableObject {

    @Published
    private(set) var promotionalOfferData: PromotionalOfferData?
    @Published
    private(set) var error: Error?

    private var purchasesProvider: CustomerCenterPurchasesType
    private let loadPromotionalOfferUseCase: LoadPromotionalOfferUseCase

    internal var onPromotionalOfferSuccessfullyPurchased: (() -> Void)?

    init(
        promotionalOfferData: PromotionalOfferData?,
        purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases(),
        onPromotionalOfferSuccessfullyPurchased: (() -> Void)? = nil
    ) {
        self.promotionalOfferData = promotionalOfferData
        self.purchasesProvider = purchasesProvider
        self.loadPromotionalOfferUseCase = LoadPromotionalOfferUseCase()
        self.onPromotionalOfferSuccessfullyPurchased = onPromotionalOfferSuccessfullyPurchased
    }

    func purchasePromo() async {
        guard let promotionalOffer = self.promotionalOfferData?.promotionalOffer,
              let product = self.promotionalOfferData?.product else {
            Logger.warning(Strings.promo_offer_not_loaded)
            return
        }

        do {
            let result = try await self.purchasesProvider.purchase(
                product: product,
                promotionalOffer: promotionalOffer
            )

            // swiftlint:disable:next todo
            // TODO: do something with result
            Logger.debug("Purchased promotional offer: \(result)")
            self.onPromotionalOfferSuccessfullyPurchased?()
        } catch {
            self.error = error
        }
    }

    func loadPromo(promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer) async {
        let result = await loadPromotionalOfferUseCase.execute(promoOfferDetails: promoOfferDetails)
        switch result {
        case .success(let promotionalOfferData):
            self.promotionalOfferData = promotionalOfferData
        case .failure(let error):
            self.error = error
        }
    }

}

#endif
