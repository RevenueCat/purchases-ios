//
//  TestStoreProductDiscountAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 6/26/23.
//

import RevenueCat

var testProductDiscount: TestStoreProductDiscount!

func checkTestStoreProductDiscountAPI() {
    // Getters
    let identifier: String = testProductDiscount.identifier
    let price: Decimal = testProductDiscount.price
    let localizedPriceString: String = testProductDiscount.localizedPriceString
    let paymentMode: StoreProductDiscount.PaymentMode = testProductDiscount.paymentMode
    let subscriptionPeriod: SubscriptionPeriod = testProductDiscount.subscriptionPeriod
    let numberOfPeriods: Int = testProductDiscount.numberOfPeriods
    let type: StoreProductDiscount.DiscountType = testProductDiscount.type

    // Setters
    testProductDiscount.identifier = identifier
    testProductDiscount.price = price
    testProductDiscount.localizedPriceString = localizedPriceString
    testProductDiscount.paymentMode = paymentMode
    testProductDiscount.subscriptionPeriod = subscriptionPeriod
    testProductDiscount.numberOfPeriods = numberOfPeriods
    testProductDiscount.type = type
}

private func checkCreateStoreProduct() {
    _ = TestStoreProductDiscount(
        identifier: "",
        price: 3.99,
        localizedPriceString: "",
        paymentMode: .payAsYouGo,
        subscriptionPeriod: .init(value: 1, unit: .month),
        numberOfPeriods: 2,
        type: .introductory
    )

    _ = TestStoreProductDiscount(
        identifier: "",
        price: 1.99,
        localizedPriceString: "",
        paymentMode: .freeTrial,
        subscriptionPeriod: .init(value: 0, unit: .day),
        numberOfPeriods: 1,
        type: .promotional
    )
}
