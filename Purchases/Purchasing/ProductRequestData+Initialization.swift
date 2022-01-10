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

    /// Initializes a `ProductRequestData` from an `SK1Product`
    init(with product: SK1Product) {
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
            currencyCode: product.priceLocale.currencyCode,
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

    static func extractIntroDurationType(for product: SK1Product) -> StoreProductDiscount.PaymentMode {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let paymentMode = product.introductoryPrice?.paymentMode {
            return .init(skProductDiscountPaymentMode: paymentMode)
        } else {
            return .none
        }
    }

    static func extractSubscriptionGroup(for product: SK1Product) -> String? {
        if #available(iOS 12.0, macOS 10.14.0, tvOS 12.0, *) {
            return product.subscriptionGroupIdentifier
        } else {
            return nil
        }
    }

    static func extractDiscounts(for product: SK1Product) -> [StoreProductDiscount]? {
        if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
            return product.discounts.map(StoreProductDiscount.init(with:))
        } else {
            return nil
        }
    }

    static func extractPaymentMode(for product: SK1Product) -> StoreProductDiscount.PaymentMode {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let paymentMode = product.introductoryPrice?.paymentMode {
            return StoreProductDiscount.PaymentMode(skProductDiscountPaymentMode: paymentMode)
        } else {
            return .none
        }
    }

    static func extractIntroPrice(for product: SK1Product) -> NSDecimalNumber? {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let introductoryPrice = product.introductoryPrice {
            return introductoryPrice.price
        } else {
            return nil
        }
    }

    static func extractNormalDuration(for product: SK1Product) -> String? {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let subscriptionPeriod = product.subscriptionPeriod,
           subscriptionPeriod.numberOfUnits != 0 {
            return ISOPeriodFormatter.string(fromProductSubscriptionPeriod: subscriptionPeriod)
        } else {
            return nil
        }
    }

    static func extractIntroDuration(for product: SK1Product) -> String? {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let subscriptionPeriod = product.introductoryPrice?.subscriptionPeriod {
            return ISOPeriodFormatter.string(fromProductSubscriptionPeriod: subscriptionPeriod)
        } else {
            return nil
        }
    }

}
