//
//  PromotionalOfferAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

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

    let sk1Discount: SK1ProductDiscount = discount.sk1Discount!
    let sk2Discount: SK2ProductDiscount = discount.sk2Discount!

    print(
        offerIdentifier!,
        currentyCode!,
        price,
        decimalPrice,
        localizedPriceString,
        paymentMode,
        priceFormatter!,
        subscriptionPeriod,
        sk1Discount,
        sk2Discount
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
