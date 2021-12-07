//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOffer.swift
//
//  Created by Joshua Liebowitz on 7/2/21.
//

import Foundation
import StoreKit

class PromotionalOffer {

    let offerIdentifier: String?
    let price: Decimal
    let paymentMode: ProductInfo.PaymentMode

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    convenience init(with productDiscount: SKProductDiscount) {
        let skPaymentMode = productDiscount.paymentMode
        let rcPaymentMode = ProductInfo.PaymentMode(skProductDiscountPaymentMode: skPaymentMode)
        self.init(offerIdentifier: productDiscount.identifier,
                  price: productDiscount.price as Decimal,
                  paymentMode: rcPaymentMode)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    convenience init(with subscriptionOffer: Product.SubscriptionOffer) {
        self.init(
            offerIdentifier: subscriptionOffer.id,
            price: subscriptionOffer.price,
            paymentMode: ProductInfo.PaymentMode(subscriptionOfferPaymentMode: subscriptionOffer.paymentMode)
        )
    }

    init(offerIdentifier: String?, price: Decimal, paymentMode: ProductInfo.PaymentMode) {
        self.offerIdentifier = offerIdentifier
        self.price = price
        self.paymentMode = paymentMode
    }

}
