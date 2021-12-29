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
    let price: Decimal
    let normalDuration: String?
    let introDuration: String?
    let introDurationType: PromotionalOffer.IntroDurationType
    let introPrice: Decimal?
    let subscriptionGroup: String?
    let discounts: [PromotionalOffer]?

    var cacheKey: String {
        var key = """
        \(productIdentifier)-\(price)-\(currencyCode ?? "")-\(paymentMode.rawValue)-\(introPrice ?? 0)-\
        \(subscriptionGroup ?? "")-\(normalDuration ?? "")-\(introDuration ?? "")-\(introDurationType.rawValue)
        """

        guard let discounts = discounts else {
            return key
        }

        for offer in discounts {
            key += "-\(offer.offerIdentifier ?? "null offer id")"
        }
        return key
    }

}

extension ProductInfo: Encodable {

    public enum CodingKeys: String, CodingKey {

        case productIdentifier = "product_id"
        case paymentMode = "payment_mode"
        case currencyCode = "currency"
        case price
        case normalDuration = "normal_duration"
        case introDuration = "intro_duration"
        case trialDuration = "trial_duration"
        case introPrice = "introductory_price"
        case subscriptionGroup = "subscription_group_id"
        case discounts = "offers"

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.productIdentifier, forKey: .productIdentifier)

        if self.paymentMode != .none {
            try container.encode(self.paymentMode, forKey: .paymentMode)
        }
        try container.encode(self.currencyCode, forKey: .currencyCode)
        try container.encode((self.price as NSDecimalNumber).description, forKey: .price)
        try container.encodeIfPresent(self.subscriptionGroup, forKey: .subscriptionGroup)
        try container.encodeIfPresent(self.discounts, forKey: .discounts)

        try container.encodeIfPresent((self.introPrice as NSDecimalNumber?)?.description,
                                      forKey: .introPrice)

        try container.encodeIfPresent(self.normalDuration, forKey: .normalDuration)

        if let introDuration = self.introDuration {
            switch self.introDurationType {
            case .introPrice:
                try container.encode(introDuration, forKey: .introDuration)

            case .freeTrial:
                try container.encode(introDuration, forKey: .trialDuration)

            default: break
            }
        }
    }

}
