//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
import StoreKit
@testable import RevenueCat

class MockSK1Product: SK1Product {
    var mockProductIdentifier: String

    init(mockProductIdentifier: String, mockSubscriptionGroupIdentifier: String? = nil) {
        self.mockProductIdentifier = mockProductIdentifier
        self.mockSubscriptionGroupIdentifier = mockSubscriptionGroupIdentifier
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
        return mockPriceLocale ?? Locale(identifier: "en_US")
    }

    var mockPrice: NSDecimalNumber?
    override var price: NSDecimalNumber {
        return mockPrice ?? 2.99 as NSDecimalNumber
    }

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    override var introductoryPrice: SKProductDiscount? {
        return mockDiscount
    }

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    lazy var mockDiscount: SKProductDiscount? = nil

    @available(iOS 12.2, macCatalyst 13.0, tvOS 12.2, macOS 10.13.2, *)
    override var discounts: [SKProductDiscount] {
        return (mockDiscount != nil) ? [mockDiscount!] : []
    }

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    lazy var mockSubscriptionPeriod: SKProductSubscriptionPeriod? = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    override var subscriptionPeriod: SKProductSubscriptionPeriod? {
        return mockSubscriptionPeriod
    }
}
