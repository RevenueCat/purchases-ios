//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProductDiscountType+Mock.swift
//
//  Created by Facundo Menzella on 7/5/25.

import Foundation
@_spi(Internal) import RevenueCat

@_spi(Internal) extension StoreProductDiscountType {

    static func discount(
        paymentMode: StoreProductDiscount.PaymentMode = .payAsYouGo,
        price: Decimal = 0.99,
        subscriptionPeriod: SubscriptionPeriod = .init(value: 1, unit: .month),
        numberOfPeriods: Int = 3,
        type: StoreProductDiscount.DiscountType = .introductory
    ) -> any StoreProductDiscountType {
        MockStoreProductDiscount(
            offerIdentifier: "offerIdentifier",
            currencyCode: "USD",
            price: price,
            localizedPriceString: "\(price) USD",
            paymentMode: paymentMode,
            subscriptionPeriod: subscriptionPeriod,
            numberOfPeriods: numberOfPeriods,
            type: type
        )
    }
}

struct MockStoreProductDiscount: StoreProductDiscountType {

    let offerIdentifier: String?
    let currencyCode: String?
    let price: Decimal
    let localizedPriceString: String
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: RevenueCat.SubscriptionPeriod
    let numberOfPeriods: Int
    let type: StoreProductDiscount.DiscountType

    static func mock(
        paymentMode: StoreProductDiscount.PaymentMode = .payAsYouGo,
        price: Decimal = 0.99,
        subscriptionPeriod: SubscriptionPeriod = .init(value: 1, unit: .month),
        numberOfPeriods: Int = 3,
        discountType: StoreProductDiscount.DiscountType
    ) -> MockStoreProductDiscount {
        MockStoreProductDiscount(
            offerIdentifier: nil,
            currencyCode: nil,
            price: 0.01,
            localizedPriceString: "$0.01",
            paymentMode: paymentMode,
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
            numberOfPeriods: 6,
            type: discountType
        )
    }
}
