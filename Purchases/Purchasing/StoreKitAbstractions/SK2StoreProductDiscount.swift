//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2StoreProductDiscount.swift
//
//  Created by Nacho Soto on 1/17/22.

import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
internal struct SK2StoreProductDiscount: StoreProductDiscountType {

    init(sk2Discount: SK2ProductDiscount) {
        self.underlyingSK2Discount = sk2Discount

        self.offerIdentifier = sk2Discount.id
        self.price = sk2Discount.price
        self.paymentMode = .init(subscriptionOfferPaymentMode: sk2Discount.paymentMode)
        self.subscriptionPeriod = .from(sk2SubscriptionPeriod: sk2Discount.period)
    }

    let underlyingSK2Discount: SK2ProductDiscount

    let offerIdentifier: String?
    let price: Decimal
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod

}

private extension StoreProductDiscount.PaymentMode {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    init(subscriptionOfferPaymentMode paymentMode: Product.SubscriptionOffer.PaymentMode) {
        switch paymentMode {
        case .payUpFront:
            self = .payUpFront
        case .payAsYouGo:
            self = .payAsYouGo
        case .freeTrial:
            self = .freeTrial
        default:
            self = .none
        }
    }

}
