//
// Created by Andrés Boedo on 6/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
class MockSKProductDiscount: SKProductDiscount {
    var mockPaymentMode: SKProductDiscount.PaymentMode?
    override var paymentMode: SKProductDiscount.PaymentMode {
        return mockPaymentMode ?? SKProductDiscount.PaymentMode.payAsYouGo
    }

    var mockPrice: Decimal?
    override var price: NSDecimalNumber {
        return (mockPrice as NSDecimalNumber?) ?? 1.99
    }

    var mockIdentifier: String?
    override var identifier: String {
        return mockIdentifier ?? "identifier"
    }

    lazy var mockSubscriptionPeriod: SKProductSubscriptionPeriod? = nil

    override var subscriptionPeriod: SKProductSubscriptionPeriod {
        return mockSubscriptionPeriod ?? SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)
    }
}
