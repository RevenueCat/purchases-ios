//
//  StoreProductAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import RevenueCat

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
    let isFamilyShareable: Bool = product.isFamilyShareable
    let subscriptionGroupIdentifier: String? = product.subscriptionGroupIdentifier
    let priceFormatter: NumberFormatter? = product.priceFormatter
    let subscriptionPeriod: SubscriptionPeriod? = product.subscriptionPeriod
    let introductoryPrice: StoreProductDiscount? = product.introductoryDiscount
    let discounts: [StoreProductDiscount] = product.discounts

    let pricePerMonth: NSDecimalNumber? = product.pricePerMonth
    let localizedIntroductoryPriceString: String? = product.localizedIntroductoryPriceString
    let sk1Product: SK1Product? = product.sk1Product
    let sk2Product: SK2Product? = product.sk2Product

    if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
        _ = Task.init {
            await checkStoreProductAsyncAPI()
        }
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

func checkConstructors() {
    let sk1Product: SK1Product! = nil
    let sk2Product: SK2Product! = nil

    _ = StoreProduct(sk1Product: sk1Product!)
    _ = StoreProduct(sk2Product: sk2Product!)
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
