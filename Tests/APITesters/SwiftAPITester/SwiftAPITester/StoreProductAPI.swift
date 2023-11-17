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
    let _: String = product.productIdentifier
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
        let _: Bool = product.isFamilyShareable
    }
    if #available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *) {
        let _: String? = product.subscriptionGroupIdentifier
    }
    let _: NumberFormatter? = product.priceFormatter
    if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *) {
        let _: SubscriptionPeriod? = product.subscriptionPeriod
        let _: StoreProductDiscount? = product.introductoryDiscount
        let _: NSDecimalNumber? = product.pricePerWeek
        let _: NSDecimalNumber? = product.pricePerMonth
        let _: NSDecimalNumber? = product.pricePerYear
    }
    if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *) {
        let _: [StoreProductDiscount] = product.discounts
    }

    let _: String? = product.localizedIntroductoryPriceString
    let _: SK1Product? = product.sk1Product

    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let _: SK2Product? = product.sk2Product
    }

    if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
        _ = Task<Void, Never> {
            await checkStoreProductAsyncAPI()
        }
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
func checkStoreProductAsyncAPI() async {
    let _: [PromotionalOffer] = await product.eligiblePromotionalOffers()
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
@available(*, deprecated) // Ignore deprecation warnings
func checkDeprecatedAsyncAPI() async {
    let _: [PromotionalOffer] = await product.getEligiblePromotionalOffers()
}
