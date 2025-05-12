//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroductoryOffer.swift
//
//  Created by Facundo Menzella on 12/5/25.

@_spi(Internal) import RevenueCat
import StoreKit

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppliedTransactionOffer: Equatable, Hashable, Sendable {

    let id: String?
    let type: StoreProductDiscount.DiscountType?
    let paymentMode: StoreProductDiscount.PaymentMode?
    let period: RevenueCat.SubscriptionPeriod?

    @available(iOS 17.2, *)
    init?(from storeKitOffer: StoreKit.Transaction.Offer?) {
        guard let storeKitOffer,
              let type = storeKitOffer.type.discountType else {
            return nil
        }

        self.id = storeKitOffer.id
        self.type = type
        self.paymentMode = storeKitOffer.paymentMode?.paymentMode

        if #available(iOS 18.4, *) {
            self.period = storeKitOffer.period.map {
                RevenueCat.SubscriptionPeriod.from(sk2SubscriptionPeriod: $0)
            } ?? nil
        } else {
            self.period = nil
        }
    }

    init(
        id: String?,
        type: StoreProductDiscount.DiscountType?,
        paymentMode: StoreProductDiscount.PaymentMode?,
        period: RevenueCat.SubscriptionPeriod?
    ) {
        self.id = id
        self.type = type
        self.paymentMode = paymentMode
        self.period = period
    }
}

@available(iOS 17.2, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension StoreKit.Transaction.Offer.PaymentMode {

    @available(iOS 17.2, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    var paymentMode: StoreProductDiscount.PaymentMode? {
        if self == StoreKit.Transaction.Offer.PaymentMode.freeTrial {
            return .freeTrial
        } else if self == StoreKit.Transaction.Offer.PaymentMode.payAsYouGo {
            return .payAsYouGo
        } else if self == StoreKit.Transaction.Offer.PaymentMode.payUpFront {
            return .payUpFront
        } else {
            return nil
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension StoreKit.Transaction.OfferType {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    var discountType: StoreProductDiscount.DiscountType? {
        if self == StoreKit.Transaction.OfferType.promotional {
            return .promotional
        } else if self == StoreKit.Transaction.OfferType.introductory {
            return .introductory
        } else {
            return nil
        }
    }
}

#endif
