//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@available(iOS 12.2, *)
class MockProductDiscount: SKProductDiscount {

    var mockIdentifier: String

    init(mockIdentifier: String) {
        self.mockIdentifier = mockIdentifier
        super.init()
    }

    override var price: NSDecimalNumber {
        return 2.99 as NSDecimalNumber
    }

    override var priceLocale: Locale {
        return Locale.current
    }

    override var identifier: String {
        return self.mockIdentifier
    }

    override var subscriptionPeriod: SKProductSubscriptionPeriod {
        return SKProductSubscriptionPeriod()
    }

    override var numberOfPeriods: Int {
        return 2
    }

    override var paymentMode: SKProductDiscount.PaymentMode {
        return SKProductDiscount.PaymentMode.freeTrial;
    }
}
