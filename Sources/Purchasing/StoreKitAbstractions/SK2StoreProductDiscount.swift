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

    init?(sk2Discount: SK2ProductDiscount, currencyCode: String?) {
        guard let paymentMode = StoreProductDiscount.PaymentMode(subscriptionOfferPaymentMode: sk2Discount.paymentMode),
              let subscriptionPeriod = SubscriptionPeriod.from(sk2SubscriptionPeriod: sk2Discount.period),
              let type = StoreProductDiscount.DiscountType.from(sk2Discount: sk2Discount)
        else { return nil }

        self.underlyingSK2Discount = sk2Discount

        self.offerIdentifier = sk2Discount.id
        self.currencyCode = currencyCode
        self.price = sk2Discount.price
        self.paymentMode = paymentMode
        self.subscriptionPeriod = subscriptionPeriod
        self.numberOfPeriods = sk2Discount.periodCount
        self.type = type
    }

    let underlyingSK2Discount: SK2ProductDiscount

    let offerIdentifier: String?
    let currencyCode: String?
    let price: Decimal
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod
    let numberOfPeriods: Int
    let type: StoreProductDiscount.DiscountType

    var localizedPriceString: String { underlyingSK2Discount.displayPrice }
}

#if swift(<5.7)
// `SK2ProductDiscount` isn't `Sendable` until iOS 16.0 / Swift 5.7
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SK2StoreProductDiscount: @unchecked Sendable {}
#endif

// MARK: - Private

private extension StoreProductDiscount.PaymentMode {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    init?(subscriptionOfferPaymentMode paymentMode: Product.SubscriptionOffer.PaymentMode) {
        switch paymentMode {
        case .payUpFront:
            self = .payUpFront
        case .payAsYouGo:
            self = .payAsYouGo
        case .freeTrial:
            self = .freeTrial
        default:
            Logger.appleWarning(Strings.storeKit.skunknown_payment_mode(String.init(describing: paymentMode)))
            return nil
        }
    }

}
