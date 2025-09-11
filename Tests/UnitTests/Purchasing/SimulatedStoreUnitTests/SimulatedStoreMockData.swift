//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimulatedStoreMockData.swift
//
//  Created by Antonio Pallares on 28/7/25.

@testable import RevenueCat

enum SimulatedStoreMockData {

    private static let yearlyPricingPhase = WebBillingProductsResponse.PricingPhase(
        periodDuration: "P1Y",
        price: WebBillingProductsResponse.Price(amountMicros: 99_990_000,
                                                currency: "EUR"),
        cycleCount: 1
    )

    private static let monthlyPricingPhase = WebBillingProductsResponse.PricingPhase(
        periodDuration: "P1M",
        price: WebBillingProductsResponse.Price(amountMicros: 9_990_000,
                                                currency: "EUR"),
        cycleCount: 1
    )

    private static let oneTimePurchasePrice = WebBillingProductsResponse.Price(
        amountMicros: 199_900_000, currency: "GBP")

    private static let yearlyPurchaseOption = WebBillingProductsResponse.PurchaseOption(
        basePrice: .init(wrappedValue: nil),
        base: .init(wrappedValue: yearlyPricingPhase),
        trial: .init(wrappedValue: nil),
        introPrice: .init(wrappedValue: nil)
    )

    private static let monthlyPurchaseOption = WebBillingProductsResponse.PurchaseOption(
        basePrice: .init(wrappedValue: nil),
        base: .init(wrappedValue: monthlyPricingPhase),
        trial: .init(wrappedValue: nil),
        introPrice: .init(wrappedValue: nil)
    )

    private static let oneTimePurchaseOption = WebBillingProductsResponse.PurchaseOption(
        basePrice: .init(wrappedValue: oneTimePurchasePrice),
        base: .init(wrappedValue: nil),
        trial: .init(wrappedValue: nil),
        introPrice: .init(wrappedValue: nil)
    )

    /// Can be used to test errors when converting `WebBillingProductsResponse.Product` to `StoreProduct`.
    private static let noBasePricePurchaseOption = WebBillingProductsResponse.PurchaseOption(
        basePrice: .init(wrappedValue: nil),
        base: .init(wrappedValue: nil),
        trial: .init(wrappedValue: nil),
        introPrice: .init(wrappedValue: nil)
    )

    static let yearlyProduct = WebBillingProductsResponse.Product(
        identifier: "product_annual",
        productType: .subscription,
        title: "Test Yearly Subscription",
        description: "A test yearly subscription product",
        defaultPurchaseOptionId: "base_option",
        purchaseOptions: [
            "base_option": yearlyPurchaseOption
        ]
    )

    static let monthlyProduct = WebBillingProductsResponse.Product(
        identifier: "product_monthly",
        productType: .subscription,
        title: "Test Monthly Subscription",
        description: "A test monthly subscription product",
        defaultPurchaseOptionId: "base_option",
        purchaseOptions: [
            "base_option": monthlyPurchaseOption
        ]
    )

    static let lifetimeProduct = WebBillingProductsResponse.Product(
        identifier: "lifetime",
        productType: .nonConsumable,
        title: "Test Lifetime Product",
        description: "A test lifetime product",
        defaultPurchaseOptionId: "one_time_purchase",
        purchaseOptions: [
            "one_time_purchase": oneTimePurchaseOption
        ]
    )

    /// Can be used to test errors when converting `WebBillingProductsResponse.Product` to `StoreProduct`.
    static let productWithoutPurchaseOptions = WebBillingProductsResponse.Product(
        identifier: "product_no_purchase_options",
        productType: .subscription,
        title: "Test No Purchase Options",
        description: "A test product with no purchase options",
        defaultPurchaseOptionId: "inexistent_option",
        purchaseOptions: [:]
    )

    /// Can be used to test errors when converting `WebBillingProductsResponse.Product` to `StoreProduct`.
    static let productWithoutBasePrices = WebBillingProductsResponse.Product(
        identifier: "product_no_base_prices",
        productType: .subscription,
        title: "Test No Base Prices",
        description: "A test product with no base prices",
        defaultPurchaseOptionId: "no_base_prices_option",
        purchaseOptions: ["no_base_prices_option": noBasePricePurchaseOption]
    )

    static let yearlyAndMonthlyWebBillingProductsResponse = WebBillingProductsResponse(
        productDetails: [yearlyProduct, monthlyProduct]
    )

    /// Can be used to test errors when converting `WebBillingProductsResponse.Product` to `StoreProduct`.
    static let noPurchaseOptionsWebBillingProductsResponse = WebBillingProductsResponse(
        productDetails: [productWithoutPurchaseOptions]
    )

    /// Can be used to test errors when converting `WebBillingProductsResponse.Product` to `StoreProduct`.
    static let noBasePricesWebBillingProductsResponse = WebBillingProductsResponse(
        productDetails: [productWithoutBasePrices]
    )

}
