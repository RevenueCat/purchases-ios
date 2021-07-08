//
//  ProductInfoExtractor.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 8/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

// TODO(post migration): Change back to internal and consider converting to a struct
@objc(RCProductInfoExtractor)
public class ProductInfoExtractor: NSObject {
    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)
    private lazy var isoPeriodFormatter = ISOPeriodFormatter()

    // TODO(post migration): Change back to internal
    @objc(extractInfoFromSKProduct:)
    public func extractInfo(from product: SKProduct) -> ProductInfo? {
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
            currencyCode: product.priceLocale.rc_currencyCode() ?? "USD",
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
    func extractIntroDurationType(for product: SKProduct) -> RCIntroDurationType {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let paymentMode = product.introductoryPrice?.paymentMode {
            return paymentMode == .freeTrial ? .freeTrial : .introPrice
        } else {
            return .none
        }
    }

    func extractSubscriptionGroup(for product: SKProduct) -> String? {
        if #available(iOS 12.0, macOS 10.14.0, tvOS 12.0, *) {
            return product.subscriptionGroupIdentifier
        } else {
            return nil
        }
    }

    func extractDiscounts(for product: SKProduct) -> [PromotionalOffer]? {
        if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
            return product.discounts.map(PromotionalOffer.init(withProductDiscount:))
        } else {
            return nil
        }
    }

    func extractPaymentMode(for product: SKProduct) -> ProductInfo.PaymentMode {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let paymentMode = product.introductoryPrice?.paymentMode {
            return ProductInfo.paymentMode(fromSKProductDiscountPaymentMode: paymentMode)
        } else {
            return .none
        }
    }

    func extractIntroPrice(for product: SKProduct) -> NSDecimalNumber? {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let introductoryPrice = product.introductoryPrice {
            return introductoryPrice.price
        } else {
            return nil
        }
    }

    func extractNormalDuration(for product: SKProduct) -> String? {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let subscriptionPeriod = product.subscriptionPeriod,
           subscriptionPeriod.numberOfUnits != 0 {
            return isoPeriodFormatter.string(fromProductSubscriptionPeriod: subscriptionPeriod)
        } else {
            return nil
        }
    }

    func extractIntroDuration(for product: SKProduct) -> String? {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *),
           let subscriptionPeriod = product.introductoryPrice?.subscriptionPeriod {
            return isoPeriodFormatter.string(fromProductSubscriptionPeriod: subscriptionPeriod)
        } else {
            return nil
        }
    }
}
