//
//  StoreProductAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import Foundation
import RevenueCat_CustomEntitlementComputation

var product: StoreProduct!

func checkStoreProductAPI() {
    let category: StoreProduct.ProductCategory = product.productCategory
    let productType: StoreProduct.ProductType = product.productType
    let localizedDescription: String = product.localizedDescription
    let localizedTitle: String = product.localizedTitle
    let currencyCode: String? = product.currencyCode
    let price: Decimal = product.price
    // This is mainly for Objective-C
    let decimalPrice: NSDecimalNumber = product.priceDecimalNumber
    let localizedPriceString: String = product.localizedPriceString
    let productIdentifier: String = product.productIdentifier
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
        let isFamilyShareable: Bool = product.isFamilyShareable
        print(isFamilyShareable)
    }
    let subscriptionGroupIdentifier: String? = product.subscriptionGroupIdentifier
    let priceFormatter: NumberFormatter? = product.priceFormatter
    let subscriptionPeriod: SubscriptionPeriod? = product.subscriptionPeriod
    let introductoryPrice: StoreProductDiscount? = product.introductoryDiscount
    let discounts: [StoreProductDiscount] = product.discounts

    let pricePerMonth: NSDecimalNumber? = product.pricePerMonth
    let localizedIntroductoryPriceString: String? = product.localizedIntroductoryPriceString
    let sk1Product: SK1Product? = product.sk1Product
    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let sk2Product: SK2Product? = product.sk2Product
        print(sk2Product!)
    }

    print(
        product!,
        category,
        productType,
        localizedDescription,
        localizedTitle,
        currencyCode!,
        price,
        decimalPrice,
        localizedPriceString,
        productIdentifier,
        subscriptionGroupIdentifier!,
        priceFormatter!,
        subscriptionPeriod!,
        introductoryPrice!,
        discounts,
        pricePerMonth!,
        localizedIntroductoryPriceString!,
        sk1Product!
    )
}

func checkConstructors() {
    let sk1Product: SK1Product! = nil
    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let sk2Product: SK2Product! = nil
        _ = StoreProduct(sk2Product: sk2Product!)
    }

    _ = StoreProduct(sk1Product: sk1Product!)
}

func checkProductCategory(_ category: StoreProduct.ProductCategory) {
    switch category {
    case .subscription: break
    case .nonSubscription: break
    @unknown default: break
    }
}

func checkProductType(_ type: StoreProduct.ProductType) {
    switch type {
    case .consumable: break
    case .nonConsumable: break
    case .nonRenewableSubscription: break
    case .autoRenewableSubscription: break
    @unknown default: break
    }
}
