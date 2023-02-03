//
// Created by Andrés Boedo on 6/5/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

extension ProductRequestData {

    static func createMockProductData(productIdentifier: String = "product_id",
                                      paymentMode: StoreProductDiscount.PaymentMode? = nil,
                                      currencyCode: String = "UYU",
                                      storefrontCountryCode: String = "ESP",
                                      price: Decimal = 15.99,
                                      normalDuration: String? = nil,
                                      introDuration: String? = nil,
                                      introDurationType: StoreProductDiscount.PaymentMode? = nil,
                                      introPrice: Decimal? = nil,
                                      subscriptionGroup: String? = nil,
                                      discounts: [StoreProductDiscountType]? = nil) -> ProductRequestData {
        ProductRequestData(productIdentifier: productIdentifier,
                           paymentMode: paymentMode,
                           currencyCode: currencyCode,
                           storefront: MockStorefront(countryCode: storefrontCountryCode),
                           price: price,
                           normalDuration: normalDuration,
                           introDuration: introDuration,
                           introDurationType: introDurationType,
                           introPrice: introPrice,
                           subscriptionGroup: subscriptionGroup,
                           discounts: discounts.map { $0.map(StoreProductDiscount.from) })
    }

}
