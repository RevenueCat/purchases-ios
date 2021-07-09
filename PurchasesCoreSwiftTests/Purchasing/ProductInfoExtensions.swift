//
// Created by Andrés Boedo on 6/5/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import PurchasesCoreSwift

extension ProductInfo {
    static func createMockProductInfo(productIdentifier: String = "product_id",
                                      paymentMode: ProductInfo.PaymentMode = .none,
                                      currencyCode: String = "UYU",
                                      price: NSDecimalNumber = 15.99,
                                      normalDuration: String? = nil,
                                      introDuration: String? = nil,
                                      introDurationType: RCIntroDurationType = .none,
                                      introPrice: NSDecimalNumber? = nil,
                                      subscriptionGroup: String? = nil,
                                      discounts: [PromotionalOffer]? = nil) -> ProductInfo {
        ProductInfo(productIdentifier: productIdentifier,
                    paymentMode: paymentMode,
                    currencyCode: currencyCode,
                    price: price,
                    normalDuration: normalDuration,
                    introDuration: introDuration,
                    introDurationType: introDurationType,
                    introPrice: introPrice,
                    subscriptionGroup: subscriptionGroup,
                    discounts: discounts)
    }
}
