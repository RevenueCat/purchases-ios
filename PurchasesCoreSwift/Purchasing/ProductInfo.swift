//
//  ProductInfo.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/2/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@objc(RCProductInfo) public class ProductInfo: NSObject {

    // TODO(post migration): Change back to internal
    @objc public let productIdentifier: String
    @objc public let paymentMode: PaymentMode
    @objc public let currencyCode: String?
    @objc public let price: NSDecimalNumber
    @objc public let normalDuration: String?
    @objc public let introDuration: String?
    @objc public let introDurationType: RCIntroDurationType
    @objc public let introPrice: NSDecimalNumber?
    @objc public let subscriptionGroup: String?
    @objc public let discounts: [PromotionalOffer]?

    @objc(RCPaymentMode) public enum PaymentMode: Int {
        case none = -1
        case payAsYouGo = 0
        case payUpFront = 1
        case freeTrial = 2
    }

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    @objc static public func paymentMode(fromSKProductDiscountPaymentMode paymentMode: SKProductDiscount.PaymentMode) -> ProductInfo.PaymentMode {
        switch paymentMode {
        case .payUpFront:
            return .payUpFront
        case .payAsYouGo:
            return .payAsYouGo
        case .freeTrial:
            return .freeTrial
        default:
            return .none
        }
    }

    @objc public init(productIdentifier: String,
                      paymentMode: PaymentMode,
                      currencyCode: String?,
                      price: NSDecimalNumber,
                      normalDuration: String?,
                      introDuration: String?,
                      introDurationType: RCIntroDurationType,
                      introPrice: NSDecimalNumber?,
                      subscriptionGroup: String?,
                      discounts: [PromotionalOffer]?) {
        self.productIdentifier = productIdentifier
        self.paymentMode = paymentMode
        self.currencyCode = currencyCode
        self.price = price
        self.normalDuration = normalDuration
        self.introDuration = introDuration
        self.introDurationType = introDurationType
        self.introPrice = introPrice
        self.subscriptionGroup = subscriptionGroup
        self.discounts = discounts
    }

    @objc public func asDictionary() -> [String: NSObject] {
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

    @objc public var cacheKey: String {
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
