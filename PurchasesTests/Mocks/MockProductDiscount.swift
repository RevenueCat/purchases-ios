//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import StoreKit

@available(iOS 11.2, *)
class MockProductDiscount: SKProductDiscount {

    init(identifier: String? = "offerid",
         paymentMode: SKProductDiscount.PaymentMode = SKProductDiscount.PaymentMode.freeTrial,
         price: NSDecimalNumber = 2.99 as NSDecimalNumber,
         subscriptionPeriod: SKProductSubscriptionPeriod = SKProductSubscriptionPeriod(),
         numberOfPeriods: Int = 2) {
        self.privateIdentifier = identifier
        self.privatePaymentMode = paymentMode
        self.privatePrice = price
        self.privateNumberOfPeriods = numberOfPeriods
        self.privateSubscriptionPeriod = subscriptionPeriod
    }

    private let privateSubscriptionPeriod: SKProductSubscriptionPeriod
    override var subscriptionPeriod: SKProductSubscriptionPeriod {
        return privateSubscriptionPeriod
    }

    private let privateNumberOfPeriods: Int
    override var numberOfPeriods: Int {
        return privateNumberOfPeriods
    }

    private var privateIdentifier: String?
    public override var identifier: String? {
        get {
            return privateIdentifier
        }
        set {
            privateIdentifier = newValue
        }
    }

    private var privatePaymentMode: SKProductDiscount.PaymentMode
    public override var paymentMode: SKProductDiscount.PaymentMode {
        get {
            return privatePaymentMode
        }
        set {
            privatePaymentMode = newValue
        }
    }

    private var privatePrice: NSDecimalNumber
    public override var price: NSDecimalNumber {
        get {
            return privatePrice
        }
        set {
            privatePrice = newValue
        }
    }

    public override var priceLocale: Locale {
        return Locale.current
    }
}
