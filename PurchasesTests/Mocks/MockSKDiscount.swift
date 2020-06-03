//
// Created by Andrés Boedo on 6/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@available(iOS 11.2, *)
class MockDiscount: SKProductDiscount {
    var mockPaymentMode: SKProductDiscount.PaymentMode?
    override var paymentMode: SKProductDiscount.PaymentMode {
        return mockPaymentMode ?? SKProductDiscount.PaymentMode.payAsYouGo
    }

    override var price: NSDecimalNumber {
        return 1.99 as NSDecimalNumber
    }

    var mockIdentifier: String?
    override var identifier: String {
        return mockIdentifier ?? "identifier"
    }
}