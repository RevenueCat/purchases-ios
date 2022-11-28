//
// Created by Andrés Boedo on 6/5/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

extension RCProductInfo {
    static func createMockProductInfo(productIdentifier: String = "product_id",
                                      paymentMode: RCPaymentMode = .none,
                                      currencyCode: String = "UYU",
                                      countryCode: String? = nil,
                                      price: NSDecimalNumber = 15.99,
                                      normalDuration: String? = nil,
                                      introDuration: String? = nil,
                                      introDurationType: RCIntroDurationType = .none,
                                      introPrice: NSDecimalNumber? = nil,
                                      subscriptionGroup: String? = nil,
                                      discounts: [RCPromotionalOffer]? = nil) -> RCProductInfo {
        RCProductInfo(productIdentifier: productIdentifier,
                      paymentMode: paymentMode,
                      currencyCode: currencyCode,
                      countryCode: countryCode,
                      price: price,
                      normalDuration: normalDuration,
                      introDuration: introDuration,
                      introDurationType: introDurationType,
                      introPrice: introPrice,
                      subscriptionGroup: subscriptionGroup,
                      discounts: discounts)
    }
}
