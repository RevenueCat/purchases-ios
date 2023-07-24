//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStoreProductDiscount.swift
//
//  Created by Nacho Soto on 6/26/23.

import Foundation

/// A type that contains the necessary data to create a ``StoreProduct``.
public struct TestStoreProductDiscount {

    // Note: this class inherits its docs from `StoreProductDiscountType`
    // swiftlint:disable missing_docs

    public var identifier: String
    public var price: Decimal
    public var localizedPriceString: String
    public var paymentMode: StoreProductDiscount.PaymentMode
    public var subscriptionPeriod: SubscriptionPeriod
    public var numberOfPeriods: Int
    public var type: StoreProductDiscount.DiscountType

    public init(
        identifier: String,
        price: Decimal,
        localizedPriceString: String,
        paymentMode: StoreProductDiscount.PaymentMode,
        subscriptionPeriod: SubscriptionPeriod,
        numberOfPeriods: Int,
        type: StoreProductDiscount.DiscountType
    ) {
        self.identifier = identifier
        self.price = price
        self.localizedPriceString = localizedPriceString
        self.paymentMode = paymentMode
        self.subscriptionPeriod = subscriptionPeriod
        self.numberOfPeriods = numberOfPeriods
        self.type = type
    }

}

extension TestStoreProductDiscount: StoreProductDiscountType {

    var offerIdentifier: String? {
        return self.identifier
    }

    var currencyCode: String? {
        // Test currency defaults to current locale
        return Locale.current.rc_currencyCode
    }

}

extension TestStoreProductDiscount {

    /// Convert it into a ``StoreProductDiscount``.
    public func toStoreProductDiscount() -> StoreProductDiscount {
        return .from(discount: self)
    }

}
