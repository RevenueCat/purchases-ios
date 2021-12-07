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

@objc(RCPromotionalOffer)
public class PromotionalOffer: NSObject {

    @objc(RCPaymentMode)
    public enum PaymentMode: Int {

        case none = -1
        case payAsYouGo = 0
        case payUpFront = 1
        case freeTrial = 2

    }

    // TODO: remove?
    internal enum IntroDurationType: Int {

        case none = -1
        case freeTrial = 0
        case introPrice = 1

    }

    public let offerIdentifier: String?
    public let price: Decimal
    public let paymentMode: PaymentMode

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    convenience init(with productDiscount: SKProductDiscount) {
        let skPaymentMode = productDiscount.paymentMode
        let rcPaymentMode = PaymentMode(skProductDiscountPaymentMode: skPaymentMode)
        self.init(offerIdentifier: productDiscount.identifier,
                  price: productDiscount.price as Decimal,
                  paymentMode: rcPaymentMode)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    convenience init(with subscriptionOffer: Product.SubscriptionOffer) {
        self.init(
            offerIdentifier: subscriptionOffer.id,
            price: subscriptionOffer.price,
            paymentMode: PaymentMode(subscriptionOfferPaymentMode: subscriptionOffer.paymentMode)
        )
    }

    init(offerIdentifier: String?, price: Decimal, paymentMode: PaymentMode) {
        self.offerIdentifier = offerIdentifier
        self.price = price
        self.paymentMode = paymentMode
    }

}

extension PromotionalOffer.PaymentMode {
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    init(skProductDiscountPaymentMode paymentMode: SKProductDiscount.PaymentMode) {
        switch paymentMode {
        case .payUpFront:
            self = .payUpFront
        case .payAsYouGo:
            self = .payAsYouGo
        case .freeTrial:
            self = .freeTrial
        @unknown default:
            self = .none
        }
    }

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
