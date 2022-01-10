//
//  StoreProductAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import RevenueCat

var product: StoreProduct!
func checkStoreProductAPI() {
    let localizedDescription: String = product.localizedDescription
    let localizedTitle: String = product.localizedTitle
    let price: Decimal = product.price
    let localizedPriceString: String = product.localizedPriceString
    let productIdentifier: String = product.productIdentifier
    let isFamilyShareable: Bool = product.isFamilyShareable
    let subscriptionGroupIdentifier: String? = product.subscriptionGroupIdentifier
    let priceFormatter: NumberFormatter? = product.priceFormatter
    let subscriptionPeriod: SubscriptionPeriod? = product.subscriptionPeriod
    let introductoryPrice: StoreProductDiscount? = product.introductoryPrice
    let discounts: [StoreProductDiscount] = product.discounts

    let pricePerMonth: NSDecimalNumber? = product.pricePerMonth
    let localizedIntroductoryPriceString: String? = product.localizedIntroductoryPriceString
    let sk1Product: SK1Product? = product.sk1Product
    let sk2Product: SK2Product? = product.sk2Product

    print(
        product!,
        localizedDescription,
        localizedTitle,
        price,
        localizedPriceString,
        productIdentifier,
        isFamilyShareable,
        subscriptionGroupIdentifier!,
        priceFormatter!,
        subscriptionPeriod!,
        introductoryPrice!,
        discounts,
        pricePerMonth!,
        localizedIntroductoryPriceString!,
        sk1Product!,
        sk2Product!
    )
}
