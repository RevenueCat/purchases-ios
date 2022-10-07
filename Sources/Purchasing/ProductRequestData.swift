//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductRequestData.swift
//
//  Created by Joshua Liebowitz on 7/2/21.
//

import Foundation
import StoreKit

/// Encapsulates ``StoreProductType`` information to be sent to the backend
/// when posting receipts.
/// - SeeAlso: `Backend/post(receiptData:appUserID:isRestore:productData:...`
struct ProductRequestData {

    /// Determines what triggered a receipt to be posted
    enum InitiationSource: CaseIterable {

        /// From a call to restore purchases
        case restore

        /// From a purchase
        case purchase

        /// From a transaction in the queue
        case queue

    }

    let productIdentifier: String
    let paymentMode: StoreProductDiscount.PaymentMode?
    let currencyCode: String?
    let storefront: StorefrontType?
    let price: Decimal
    let normalDuration: String?
    let introDuration: String?
    let introDurationType: StoreProductDiscount.PaymentMode?
    let introPrice: Decimal?
    let subscriptionGroup: String?
    let discounts: [StoreProductDiscount]?

    var cacheKey: String {
        var key =
        """
        \(productIdentifier)-\(price)-\(currencyCode ?? "")-\(storefront?.countryCode ?? "")-\
        \(paymentMode?.rawValue ?? -1)-\(introPrice ?? 0)-\(subscriptionGroup ?? "")-\(normalDuration ?? "")-\
        \(introDuration ?? "")-\(introDurationType?.rawValue ?? -1)
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

extension ProductRequestData: Encodable {

    enum CodingKeys: String, CodingKey {

        case productIdentifier = "product_id"
        case paymentMode = "payment_mode"
        case currencyCode = "currency"
        case storefront = "store_country"
        case price
        case normalDuration = "normal_duration"
        case introDuration = "intro_duration"
        case trialDuration = "trial_duration"
        case introPrice = "introductory_price"
        case subscriptionGroup = "subscription_group_id"
        case discounts = "offers"

    }

    // Note: prices are encoded price as `String` (using `NSDecimalNumber.description`)
    // to preserve precision and avoid values like "1.89999999"
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.productIdentifier, forKey: .productIdentifier)

        try container.encodeIfPresent(self.paymentMode, forKey: .paymentMode)
        try container.encode(self.currencyCode, forKey: .currencyCode)
        try container.encode(self.storefront?.countryCode, forKey: .storefront)
        try container.encode((self.price as NSDecimalNumber).description, forKey: .price)
        try container.encodeIfPresent(self.subscriptionGroup, forKey: .subscriptionGroup)
        try container.encodeIfPresent(self.discounts, forKey: .discounts)

        try container.encodeIfPresent((self.introPrice as NSDecimalNumber?)?.description,
                                      forKey: .introPrice)

        try container.encodeIfPresent(self.normalDuration, forKey: .normalDuration)

        if let introDuration = self.introDuration {
            switch self.introDurationType {
            case .payUpFront:
                try container.encode(introDuration, forKey: .introDuration)

            case .freeTrial:
                try container.encode(introDuration, forKey: .trialDuration)

            default: break
            }
        }
    }

}
