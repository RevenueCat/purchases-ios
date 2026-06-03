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
        var introDiscount: SimulatedStoreProductDiscount?

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

            introDiscount = self.buildIntroductoryDiscount(
                trial: purchaseOption.trial,
                introPrice: purchaseOption.introPrice,
                baseCurrency: basePrice.currency,
                locale: locale
            )
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

    private func buildIntroductoryDiscount(
        trial: WebBillingProductsResponse.PricingPhase?,
        introPrice: WebBillingProductsResponse.PricingPhase?,
        baseCurrency: String,
        locale: Locale
    ) -> SimulatedStoreProductDiscount? {
        // Free trial takes precedence over a paid intro price when both phases are present.
        if let trial, let periodDuration = trial.periodDuration {
            guard let subscriptionPeriod = SubscriptionPeriod.from(iso8601: periodDuration) else {
                Logger.warn(Strings.offering.simulated_store_invalid_trial_period(
                    productId: self.identifier,
                    periodDuration: periodDuration
                ))
                return nil
            }
            let zeroPrice: Decimal = 0
            return SimulatedStoreProductDiscount(
                identifier: "$rc_free_trial",
                price: zeroPrice,
                localizedPriceString: formatPrice(zeroPrice, currencyCode: baseCurrency, locale: locale),
                paymentMode: .freeTrial,
                subscriptionPeriod: subscriptionPeriod,
                numberOfPeriods: trial.cycleCount,
                type: .introductory
            )
        }

        if let introPrice,
           let periodDuration = introPrice.periodDuration,
           let introPriceObj = introPrice.price {
            guard let subscriptionPeriod = SubscriptionPeriod.from(iso8601: periodDuration) else {
                Logger.warn(Strings.offering.simulated_store_invalid_intro_price_period(
                    productId: self.identifier,
                    periodDuration: periodDuration
                ))
                return nil
            }
            let decimalPrice = Decimal(Double(introPriceObj.amountMicros) / 1_000_000)
            return SimulatedStoreProductDiscount(
                identifier: "$rc_intro_price",
                price: decimalPrice,
                localizedPriceString: formatPrice(decimalPrice,
                                                  currencyCode: introPriceObj.currency,
                                                  locale: locale),
                paymentMode: .payAsYouGo,
                subscriptionPeriod: subscriptionPeriod,
                numberOfPeriods: introPrice.cycleCount,
                type: .introductory
            )
        }

        return nil
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
