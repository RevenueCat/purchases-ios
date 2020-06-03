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

    override var priceLocale: Locale {
        return Locale.current
    }

    override var price: NSDecimalNumber {
        return 2.99 as NSDecimalNumber
    }

    @available(iOS 11.2, *)
    override var introductoryPrice: SKProductDiscount? {
        return MockDiscount()
    }

    var mockDiscountIdentifier: String?
    @available(iOS 12.2, *)
    override var discounts: [SKProductDiscount] {
        if (mockDiscountIdentifier != nil) {
            return [MockProductDiscount(mockIdentifier: mockDiscountIdentifier!)];
        } else {
            return []
        }
    }
}
