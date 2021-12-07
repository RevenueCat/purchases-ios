//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductInfoExtractor.swift
//
//  Created by Juanpe Catalán on 8/7/21.
//

import Foundation
import StoreKit

enum ProductInfoExtractor {

    static func extractInfo(from product: SK1Product) -> ProductInfo {
        let paymentMode = extractPaymentMode(for: product)
        let introPrice = extractIntroPrice(for: product)

        let normalDuration = extractNormalDuration(for: product)
        let introDuration = extractIntroDuration(for: product)
        let introDurationType = extractIntroDurationType(for: product)

        let subscriptionGroup = extractSubscriptionGroup(for: product)
        let discounts = extractDiscounts(for: product)

        return ProductInfo(
            productIdentifier: product.productIdentifier,
            paymentMode: paymentMode,
            currencyCode: product.priceLocale.rc_currencyCode(),
            price: product.price,
            normalDuration: normalDuration,
            introDuration: introDuration,
            introDurationType: introDurationType,
            introPrice: introPrice,
            subscriptionGroup: subscriptionGroup,
            discounts: discounts
        )
    }

}

// MARK: - private methods

private extension ProductInfoExtractor {

    static func extractIntroDurationType(for product: SK1Product) -> PromotionalOffer.IntroDurationType {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let paymentMode = product.introductoryPrice?.paymentMode {
            return paymentMode == .freeTrial ? .freeTrial : .introPrice
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

    static func extractDiscounts(for product: SK1Product) -> [PromotionalOffer]? {
        if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
            return product.discounts.map(PromotionalOffer.init(with:))
        } else {
            return nil
        }
    }

    static func extractPaymentMode(for product: SK1Product) -> PromotionalOffer.PaymentMode {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let paymentMode = product.introductoryPrice?.paymentMode {
            return PromotionalOffer.PaymentMode(skProductDiscountPaymentMode: paymentMode)
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
