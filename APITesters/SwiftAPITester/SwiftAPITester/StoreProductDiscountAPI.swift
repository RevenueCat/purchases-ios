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
    let price: Decimal = discount.price
    let paymentMode: StoreProductDiscount.PaymentMode = discount.paymentMode
    let subscriptionPeriod: SubscriptionPeriod = discount.subscriptionPeriod

    print(
        offerIdentifier!,
        price,
        paymentMode,
        subscriptionPeriod
    )
}

var mode: StoreProductDiscount.PaymentMode!

func checkPaymentModeEnum() {
    switch mode! {
    case
            .none,
            .payAsYouGo,
            .payUpFront,
            .freeTrial:
        break

    @unknown default: fatalError()
    }
}
