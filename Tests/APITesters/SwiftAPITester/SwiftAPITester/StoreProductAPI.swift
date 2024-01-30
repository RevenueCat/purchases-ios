//
//  StoreProductAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import Foundation
import RevenueCat

var product: StoreProduct!

func checkStoreProductAPI() {
    let _: StoreProduct.ProductCategory = product.productCategory
    let _: StoreProduct.ProductType = product.productType
    let _: String = product.localizedDescription
    let _: String = product.localizedTitle
    let _: String? = product.currencyCode
    let _: Decimal = product.price
    // This is mainly for Objective-C
    let _: NSDecimalNumber = product.priceDecimalNumber
    let _: String = product.localizedPriceString
    let _: String? = product.localizedPricePerWeek
    let _: String? = product.localizedPricePerMonth
    let _: String? = product.localizedPricePerYear

    let _: String = product.productIdentifier
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
        let _: Bool = product.isFamilyShareable
    }
    let _: String? = product.subscriptionGroupIdentifier
    let _: NumberFormatter? = product.priceFormatter
    let _: SubscriptionPeriod? = product.subscriptionPeriod
    let _: StoreProductDiscount? = product.introductoryDiscount
    let _: NSDecimalNumber? = product.pricePerWeek
    let _: NSDecimalNumber? = product.pricePerMonth
    let _: NSDecimalNumber? = product.pricePerYear
    let _: [StoreProductDiscount] = product.discounts

    let _: String? = product.localizedIntroductoryPriceString
    let _: SK1Product? = product.sk1Product

    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let _: SK2Product? = product.sk2Product
    }

    _ = Task<Void, Never> {
        await checkStoreProductAsyncAPI()
    }
}

func checkConstructors() {
    let sk1Product: SK1Product! = nil
    _ = StoreProduct(sk1Product: sk1Product!)

    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let sk2Product: SK2Product! = nil
        _ = StoreProduct(sk2Product: sk2Product!)
    }
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

func checkStoreProductAsyncAPI() async {
    let _: [PromotionalOffer] = await product.eligiblePromotionalOffers()
}

@available(*, deprecated) // Ignore deprecation warnings
func checkDeprecatedAsyncAPI() async {
    let _: [PromotionalOffer] = await product.getEligiblePromotionalOffers()
}
