//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStoreMockData.swift
//
//  Created by Antonio Pallares on 28/7/25.

@testable import RevenueCat

enum TestStoreMockData {

    private static let yearlyPricingPhase = WebProductsResponse.PricingPhase(
        periodDuration: "P1Y",
        price: WebProductsResponse.Price(amountMicros: 99_990_000,
                                         currency: "EUR"),
        cycleCount: 1
    )

    private static let monthlyPricingPhase = WebProductsResponse.PricingPhase(
        periodDuration: "P1M",
        price: WebProductsResponse.Price(amountMicros: 9_990_000,
                                         currency: "EUR"),
        cycleCount: 1
    )

    private static let yearlyPurchaseOption = WebProductsResponse.PurchaseOption(
        basePrice: .init(wrappedValue: nil),
        base: .init(wrappedValue: yearlyPricingPhase),
        trial: .init(wrappedValue: nil),
        introPrice: .init(wrappedValue: nil)
    )

    private static let monthlyPurchaseOption = WebProductsResponse.PurchaseOption(
        basePrice: .init(wrappedValue: nil),
        base: .init(wrappedValue: monthlyPricingPhase),
        trial: .init(wrappedValue: nil),
        introPrice: .init(wrappedValue: nil)
    )

    /// Can be used to test errors when converting `WebProductsResponse.Product` to `StoreProduct`.
    private static let noBasePricePurchaseOption = WebProductsResponse.PurchaseOption(
        basePrice: .init(wrappedValue: nil),
        base: .init(wrappedValue: nil),
        trial: .init(wrappedValue: nil),
        introPrice: .init(wrappedValue: nil)
    )

    static let yearlyProduct = WebProductsResponse.Product(
        identifier: "product_annual",
        productType: .subscription,
        title: "Test Yearly Subscription",
        description: "A test yearly subscription product",
        defaultPurchaseOptionId: "base_option",
        purchaseOptions: [
            "base_option": yearlyPurchaseOption
        ]
    )

    static let monthlyProduct = WebProductsResponse.Product(
        identifier: "product_monthly",
        productType: .subscription,
        title: "Test Monthly Subscription",
        description: "A test monthly subscription product",
        defaultPurchaseOptionId: "base_option",
        purchaseOptions: [
            "base_option": monthlyPurchaseOption
        ]
    )

    /// Can be used to test errors when converting `WebProductsResponse.Product` to `StoreProduct`.
    static let productWithoutPurchaseOptions = WebProductsResponse.Product(
        identifier: "product_no_purchase_options",
        productType: .subscription,
        title: "Test No Purchase Options",
        description: "A test product with no purchase options",
        defaultPurchaseOptionId: "inexistent_option",
        purchaseOptions: [:]
    )

    /// Can be used to test errors when converting `WebProductsResponse.Product` to `StoreProduct`.
    static let productWithoutBasePrices = WebProductsResponse.Product(
        identifier: "product_no_base_prices",
        productType: .subscription,
        title: "Test No Base Prices",
        description: "A test product with no base prices",
        defaultPurchaseOptionId: "no_base_prices_option",
        purchaseOptions: ["no_base_prices_option": noBasePricePurchaseOption]
    )

    static let yearlyAndMonthlyWebProductsResponse = WebProductsResponse(
        productDetails: [yearlyProduct, monthlyProduct]
    )

    /// Can be used to test errors when converting `WebProductsResponse.Product` to `StoreProduct`.
    static let noPurchaseOptionsWebProductsResponse = WebProductsResponse(
        productDetails: [productWithoutPurchaseOptions]
    )

    /// Can be used to test errors when converting `WebProductsResponse.Product` to `StoreProduct`.
    static let noBasePricesWebProductsResponse = WebProductsResponse(
        productDetails: [productWithoutBasePrices]
    )

}
