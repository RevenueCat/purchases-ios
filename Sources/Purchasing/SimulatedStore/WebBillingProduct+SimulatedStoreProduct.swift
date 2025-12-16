//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBillingProduct+SimulatedStoreProduct.swift
//
//  Created by Antonio Pallares on 25/7/25.

import Foundation

extension WebBillingProductsResponse.Product {

    // Lazily instantiated
    private static var _priceFormatterProvider: PriceFormatterProvider?
    private static var priceFormatterProvider: PriceFormatterProvider {
        if let priceFormatterProvider = self._priceFormatterProvider {
            return priceFormatterProvider
        } else {
            let provider = PriceFormatterProvider()
            self._priceFormatterProvider = provider
            return provider
        }
    }

    func convertToStoreProduct(locale: Locale = .autoupdatingCurrent) throws -> StoreProduct {
        guard let purchaseOption = self.purchaseOption else {
            throw ErrorUtils.productNotAvailableForPurchaseError(
                withMessage: "No purchase option found for product \(self.identifier)"
            )
        }

        let price: WebBillingProductsResponse.Price
        var period: SubscriptionPeriod?
        let introDiscount: SimulatedStoreProductDiscount? = nil // Not supported in Simulated Store products for now

        if let basePrice = purchaseOption.basePrice {
            price = basePrice
        } else {
            guard let basePhase = purchaseOption.base,
                  let basePrice = basePhase.price else {
                throw ErrorUtils.productNotAvailableForPurchaseError(
                    withMessage: "No base price found for product \(self.identifier). " +
                    "Base price is required for test subscription products"
                )
            }

            price = basePrice
            if let periodDuration = basePhase.periodDuration {
                period = SubscriptionPeriod.from(iso8601: periodDuration)
            }
        }

        let decimalPrice = Decimal(Double(price.amountMicros) / 1_000_000)
        let localizedPriceString = formatPrice(decimalPrice, currencyCode: price.currency, locale: locale)

        let simulatedStoreProduct = SimulatedStoreProduct(localizedTitle: self.title,
                                                          price: decimalPrice,
                                                          currencyCode: price.currency,
                                                          localizedPriceString: localizedPriceString,
                                                          productIdentifier: self.identifier,
                                                          productType: self.productType.storeProductType,
                                                          localizedDescription: self.description ?? "",
                                                          subscriptionPeriod: period,
                                                          introductoryDiscount: introDiscount,
                                                          locale: locale)
        return simulatedStoreProduct.toStoreProduct()
    }

    private var purchaseOption: WebBillingProductsResponse.PurchaseOption? {
        if let defaultPurchaseOptionId = self.defaultPurchaseOptionId,
        let defaultPurchaseOption = self.purchaseOptions[defaultPurchaseOptionId] {
            return defaultPurchaseOption
        } else {
            return self.purchaseOptions.first?.value
        }
    }

    private func formatPrice(_ price: Decimal, currencyCode: String, locale: Locale) -> String {
        let formatter = Self.priceFormatterProvider.priceFormatterForWebProducts(withCurrencyCode: currencyCode,
                                                                                 locale: locale)
        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

}

private extension WebBillingProductsResponse.ProductType {

    var storeProductType: StoreProduct.ProductType {
        switch self {
        case .consumable:
            return .consumable
        case .nonConsumable:
            return .nonConsumable
        case .subscription:
            return .autoRenewableSubscription
        case .unknown:
            return .autoRenewableSubscription
        }
    }

}
