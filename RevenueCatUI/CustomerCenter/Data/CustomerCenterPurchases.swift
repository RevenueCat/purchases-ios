//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPurchases.swift
//
//  Created by Cesar de la Vega on 18/7/24.

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class CustomerCenterPurchases: CustomerCenterPurchasesType {

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        await Purchases.shared.products(productIdentifiers)
    }

    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer {
        try await Purchases.shared.promotionalOffer(forProductDiscount: discount,
                                                    product: product)
    }

    func purchase(
        product: StoreProduct,
        promotionalOffer: PromotionalOffer
    ) async throws -> PurchaseResultData {
        try await Purchases.shared.purchase(
            product: product,
            promotionalOffer: promotionalOffer
        )
    }
}
