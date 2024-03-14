//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductRequestData+Initialization.swift
//
//  Created by Juanpe Catalán on 8/7/21.
//

import Foundation
import StoreKit

extension ProductRequestData {

    /// Initializes a `ProductRequestData` from a `StoreProduct`
    init(with product: StoreProduct, storefront: StorefrontType?) {
        let paymentMode = Self.extractPaymentMode(for: product)
        let introPrice = Self.extractIntroPrice(for: product)

        let normalDuration = Self.extractNormalDuration(for: product)
        let introDuration = Self.extractIntroDuration(for: product)
        let introDurationType = Self.extractIntroDurationType(for: product)

        let subscriptionGroup = Self.extractSubscriptionGroup(for: product)
        let discounts = Self.extractDiscounts(for: product)

        self.init(
            productIdentifier: product.productIdentifier,
            paymentMode: paymentMode,
            currencyCode: product.priceFormatter?.currencyCode,
            storefront: storefront,
            price: product.price as Decimal,
            normalDuration: normalDuration,
            introDuration: introDuration,
            introDurationType: introDurationType,
            introPrice: introPrice as Decimal?,
            subscriptionGroup: subscriptionGroup,
            discounts: discounts
        )
    }

}

// MARK: - private methods

private extension ProductRequestData {

    static func extractIntroDurationType(for product: StoreProduct) -> StoreProductDiscount.PaymentMode? {
        return product.introductoryDiscount?.paymentMode
    }

    static func extractSubscriptionGroup(for product: StoreProduct) -> String? {
        return product.subscriptionGroupIdentifier
    }

    static func extractDiscounts(for product: StoreProduct) -> [StoreProductDiscount]? {
        return product.discounts
    }

    static func extractPaymentMode(for product: StoreProduct) -> StoreProductDiscount.PaymentMode? {
        return product.introductoryDiscount?.paymentMode
    }

    static func extractIntroPrice(for product: StoreProduct) -> NSDecimalNumber? {
       return product.introductoryDiscount?.price as NSDecimalNumber?
    }

    static func extractNormalDuration(for product: StoreProduct) -> String? {
        if let subscriptionPeriod = product.subscriptionPeriod,
           subscriptionPeriod.value != 0 {
            return ISOPeriodFormatter.string(fromProductSubscriptionPeriod: subscriptionPeriod)
        } else {
            return nil
        }
    }

    static func extractIntroDuration(for product: StoreProduct) -> String? {
        if let subscriptionPeriod = product.introductoryDiscount?.subscriptionPeriod {
            return ISOPeriodFormatter.string(fromProductSubscriptionPeriod: subscriptionPeriod)
        } else {
            return nil
        }
    }

}
