//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStoreProductDiscount.swift
//
//  Created by Nacho Soto on 1/17/22.

@testable import RevenueCat

struct MockStoreProductDiscount: StoreProductDiscountType {
    let offerIdentifier: String?
    let price: Decimal
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod
    let type: StoreProductDiscount.DiscountType
}
