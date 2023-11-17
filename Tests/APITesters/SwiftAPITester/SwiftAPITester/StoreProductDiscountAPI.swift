//
//  PromotionalOfferAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import Foundation
import RevenueCat

var discount: StoreProductDiscount!

func checkStoreProductDiscountAPI() {
    let offerIdentifier: String? = discount.offerIdentifier
    let currentyCode: String? = discount.currencyCode
    let price: Decimal = discount.price
    // This is mainly for Objective-C
    let decimalPrice: NSDecimalNumber = discount.priceDecimalNumber
    let localizedPriceString: String = discount.localizedPriceString
    let paymentMode: StoreProductDiscount.PaymentMode = discount.paymentMode
    let priceFormatter: NumberFormatter? = product.priceFormatter
    let subscriptionPeriod: SubscriptionPeriod = discount.subscriptionPeriod

    if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *) {
        let _: SK1ProductDiscount = discount.sk1Discount!
    }

    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        let _: SK2ProductDiscount = discount.sk2Discount!
    }

    print(
        offerIdentifier!,
        currentyCode!,
        price,
        decimalPrice,
        localizedPriceString,
        paymentMode,
        priceFormatter!,
        subscriptionPeriod
    )
}

var mode: StoreProductDiscount.PaymentMode!

func checkPaymentModeEnum() {
    switch mode! {
    case
            .payAsYouGo,
            .payUpFront,
            .freeTrial:
        break

    @unknown default: fatalError()
    }
}

var type: StoreProductDiscount.DiscountType!

func checkTypeEnum() {
    switch type! {
    case
            .introductory,
            .promotional:
        break

    @unknown default: fatalError()
    }
}
