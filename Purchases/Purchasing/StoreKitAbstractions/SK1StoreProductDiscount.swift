//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK1StoreProductDiscount.swift
//
//  Created by Nacho Soto on 1/17/22.

import StoreKit

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
internal struct SK1StoreProductDiscount: StoreProductDiscountType {

    init?(sk1Discount: SK1ProductDiscount) {
        guard let paymentMode = StoreProductDiscount.PaymentMode(skProductDiscountPaymentMode: sk1Discount.paymentMode),
              let subscriptionPeriod = SubscriptionPeriod.from(sk1SubscriptionPeriod: sk1Discount.subscriptionPeriod),
              let type = StoreProductDiscount.DiscountType.from(sk1Discount: sk1Discount)
        else { return nil }

        self.underlyingSK1Discount = sk1Discount

        if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
            self.offerIdentifier = sk1Discount.identifier
        } else {
            self.offerIdentifier = nil
        }
        self.currencyCode = sk1Discount.priceLocale.currencyCode
        self.price = sk1Discount.price as Decimal
        self.paymentMode = paymentMode
        self.subscriptionPeriod = subscriptionPeriod
        self.type = type
    }

    let underlyingSK1Discount: SK1ProductDiscount

    let offerIdentifier: String?
    let currencyCode: String?
    let price: Decimal
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod
    let type: StoreProductDiscount.DiscountType

    var localizedPriceString: String {
        return priceFormatter?.string(from: underlyingSK1Discount.price) ?? ""
    }
}

private extension StoreProductDiscount.PaymentMode {

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    init?(skProductDiscountPaymentMode paymentMode: SKProductDiscount.PaymentMode) {
        switch paymentMode {
        case .payUpFront:
            self = .payUpFront
        case .payAsYouGo:
            self = .payAsYouGo
        case .freeTrial:
            self = .freeTrial
        @unknown default:
            Logger.appleWarning(Strings.storeKit.skunknown_payment_mode(String.init(describing: paymentMode)))
            return nil
        }
    }

}
