//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockSKProduct: SKProduct {
    var mockProductIdentifier: String

    init(mockProductIdentifier: String) {
        self.mockProductIdentifier = mockProductIdentifier
        super.init()
    }

    override var productIdentifier: String {
        return self.mockProductIdentifier
    }

    var mockSubscriptionGroupIdentifier: String?
    override var subscriptionGroupIdentifier: String? {
        return self.mockSubscriptionGroupIdentifier;
    }

    var mockPriceLocale: Locale?
    override var priceLocale: Locale {
        return mockPriceLocale ?? Locale.current
    }

    var mockPrice: NSDecimalNumber?
    override var price: NSDecimalNumber {
        return mockPrice ?? 2.99 as NSDecimalNumber
    }

    @available(iOS 11.2, *)
    override var introductoryPrice: SKProductDiscount? {
        if #available(iOS 12.2, *) {
            return mockDiscount ?? MockDiscount()
        } else {
            return MockDiscount()
        }
    }

    @available(iOS 12.2, *)
    lazy var mockDiscount: SKProductDiscount? = nil

    @available(iOS 12.2, *)
    override var discounts: [SKProductDiscount] {
        return (mockDiscount != nil) ? [mockDiscount!] : []
    }

    @available(iOS 11.2, *)
    lazy var mockSubscriptionPeriod: SKProductSubscriptionPeriod? = nil

    @available(iOS 11.2, *)
    override var subscriptionPeriod: SKProductSubscriptionPeriod {
        return mockSubscriptionPeriod ?? SKProductSubscriptionPeriod(numberOfUnits: 1, unit:.month)
    }
}
