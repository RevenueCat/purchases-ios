//
//  TestStoreProductAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 6/26/23.
//

import Foundation
import RevenueCat

// swiftlint:disable syntactic_sugar

private var testProduct: TestStoreProduct!

func checkTestStoreProductAPI() {
    // Getters
    let localizedTitle: String = testProduct.localizedTitle
    let price: Decimal = testProduct.price
    let localizedPriceString: String = testProduct.localizedPriceString
    let productIdentifier: String = testProduct.productIdentifier
    let productType: StoreProduct.ProductType = testProduct.productType
    let localizedDescription: String = testProduct.localizedDescription
    let subscriptionGroupIdentifier: String? = testProduct.subscriptionGroupIdentifier
    let subscriptionPeriod: SubscriptionPeriod? = testProduct.subscriptionPeriod
    let isFamilyShareable: Bool = testProduct.isFamilyShareable
    let introductoryDiscount: StoreProductDiscount? = testProduct.introductoryDiscount
    let discounts: [StoreProductDiscount] = testProduct.discounts
    let locale: Locale = testProduct.locale

    // Setters
    testProduct.localizedTitle = localizedTitle
    testProduct.price = price
    testProduct.localizedPriceString = localizedPriceString
    testProduct.productIdentifier = productIdentifier
    testProduct.productType = productType
    testProduct.localizedDescription = localizedDescription
    testProduct.subscriptionGroupIdentifier = subscriptionGroupIdentifier
    testProduct.subscriptionPeriod = subscriptionPeriod
    testProduct.isFamilyShareable = isFamilyShareable
    testProduct.introductoryDiscount = introductoryDiscount
    testProduct.discounts = discounts
    testProduct.locale = locale

    let _: StoreProduct = testProduct.toStoreProduct()
}

private func checkStoreProductCreation(discount: TestStoreProductDiscount) {
    _ = TestStoreProduct(
        localizedTitle: "",
        price: 3.99,
        localizedPriceString: "",
        productIdentifier: "",
        productType: .autoRenewableSubscription,
        localizedDescription: ""
    )

    _ = TestStoreProduct(
        localizedTitle: "",
        price: 1.99,
        localizedPriceString: "",
        productIdentifier: "",
        productType: .autoRenewableSubscription,
        localizedDescription: "",
        subscriptionGroupIdentifier: Optional<String>.some(""),
        subscriptionPeriod: Optional<SubscriptionPeriod>.some(.init(value: 1, unit: .day)),
        isFamilyShareable: true,
        introductoryDiscount: Optional<TestStoreProductDiscount>.some(discount),
        discounts: [discount],
        locale: Locale.current
    )
}
