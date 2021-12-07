//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductInfo.swift
//
//  Created by Joshua Liebowitz on 7/2/21.
//

import Foundation
import StoreKit

struct ProductInfo {

    let productIdentifier: String
    let paymentMode: PaymentMode
    let currencyCode: String?
    let price: NSDecimalNumber
    let normalDuration: String?
    let introDuration: String?
    let introDurationType: IntroDurationType
    let introPrice: NSDecimalNumber?
    let subscriptionGroup: String?
    let discounts: [PromotionalOffer]?

    enum PaymentMode: Int {

        case none = -1
        case payAsYouGo = 0
        case payUpFront = 1
        case freeTrial = 2

    }

    enum IntroDurationType: Int {

        case none = -1
        case freeTrial = 0
        case introPrice = 1

    }

    func asDictionary() -> [String: NSObject] {
        var dict: [String: NSObject] = [:]
        dict["product_id"] = productIdentifier as NSString
        dict["price"] = price

        if let currencyCode = currencyCode {
            dict["currency"] = currencyCode as NSObject
        }

        if paymentMode != .none {
            dict["payment_mode"] = NSNumber(value: paymentMode.rawValue)
        }

        if let introPrice = introPrice {
            dict["introductory_price"] = introPrice
        }

        if let subscriptionGroup = subscriptionGroup as NSString? {
            dict["subscription_group_id"] = subscriptionGroup
        }

        if discounts != nil {
            dict.merge(self.discountsAsDictionary()) { (_, new) in new }
        }

        dict.merge(self.productDurationsAsDictionary()) { (_, new) in new }

        return dict
    }

    var cacheKey: String {
        var key = """
        \(productIdentifier)-\(price)-\(currencyCode ?? "")-\(paymentMode.rawValue)-\(introPrice ?? 0)-\
        \(subscriptionGroup ?? "")-\(normalDuration ?? "")-\(introDuration ?? "")-\(introDurationType.rawValue)
        """

        guard let discounts = discounts else {
            return key
        }

        if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
            for offer in discounts {
                key += "-\(offer.offerIdentifier ?? "null offer id")"
            }
        }
        return key
    }

    private func discountsAsDictionary() -> [String: NSObject] {
        var discountDict: [String: NSObject] = [:]
            if #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, *) {
                if let discounts = self.discounts {
                    let offers = NSMutableArray()
                    for discount in discounts {
                        guard let offerIdentifier = discount.offerIdentifier else {
                            break
                        }

                        offers.add(["offer_identifier": offerIdentifier,
                                    "price": discount.price,
                                    "payment_mode": discount.paymentMode.rawValue])

                    }
                    discountDict["offers"] = offers
                }
            }
        return discountDict
    }

    private func productDurationsAsDictionary() -> [String: NSObject] {
        var durations: [String: NSObject] = [:]

        if let normalDuration = normalDuration as NSString? {
            durations["normal_duration"] = normalDuration
        }

        guard let introDuration = introDuration as NSString? else {
            return durations
        }

        if introDurationType == .introPrice {
            durations["intro_duration"] = introDuration
        }
        if introDurationType == .freeTrial {
            durations["trial_duration"] = introDuration
        }

        return durations
    }

}

extension ProductInfo.PaymentMode {
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

    // TODO: test?
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
