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

// Fixme: remove and simply encode data in `StoreProduct`: https://github.com/RevenueCat/purchases-ios/issues/1045
struct ProductInfo {

    let productIdentifier: String
    let paymentMode: PromotionalOffer.PaymentMode
    let currencyCode: String?
    let price: NSDecimalNumber
    let normalDuration: String?
    let introDuration: String?
    let introDurationType: PromotionalOffer.IntroDurationType
    let introPrice: NSDecimalNumber?
    let subscriptionGroup: String?
    let discounts: [PromotionalOffer]?

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
