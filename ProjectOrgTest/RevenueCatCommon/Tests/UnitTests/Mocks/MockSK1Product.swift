//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
@testable import RevenueCat
import StoreKit

class MockSK1Product: SK1Product {
    var mockProductIdentifier: String
    var mockLocalizedTitle: String

    init(mockProductIdentifier: String, mockSubscriptionGroupIdentifier: String? = nil) {
        self.mockProductIdentifier = mockProductIdentifier
        self.mockSubscriptionGroupIdentifier = mockSubscriptionGroupIdentifier
        self.mockLocalizedTitle = mockProductIdentifier

        super.init()
    }

    override var productIdentifier: String {
        return self.mockProductIdentifier
    }

    var mockSubscriptionGroupIdentifier: String?
    override var subscriptionGroupIdentifier: String? {
        return self.mockSubscriptionGroupIdentifier
    }

    var mockPriceLocale: Locale?
    override var priceLocale: Locale {
        return mockPriceLocale ?? Locale(identifier: "en_US")
    }

    var mockPrice: Decimal?
    override var price: NSDecimalNumber {
        return (mockPrice ?? 2.99) as NSDecimalNumber
    }

    override var localizedTitle: String {
        return self.mockLocalizedTitle
    }

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    override var introductoryPrice: SKProductDiscount? {
        return mockDiscount
    }

    private var _mockDiscount: Any?

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    var mockDiscount: SKProductDiscount? {
        // swiftlint:disable:next force_cast
        get { return self._mockDiscount as! SKProductDiscount? }
        set { self._mockDiscount = newValue }
    }

    @available(iOS 12.2, macCatalyst 13.0, tvOS 12.2, macOS 10.13.2, *)
    override var discounts: [SKProductDiscount] {
        return self.mockDiscount.map { [$0] } ?? []
    }

    private lazy var _mockSubscriptionPeriod: Any? = {
        if #available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *) {
            return SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)
        } else {
            return nil
        }
    }()

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    var mockSubscriptionPeriod: SKProductSubscriptionPeriod? {
        // swiftlint:disable:next force_cast
        get { self._mockSubscriptionPeriod as! SKProductSubscriptionPeriod? }
        set { self._mockSubscriptionPeriod = newValue }
    }

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    override var subscriptionPeriod: SKProductSubscriptionPeriod? {
        return mockSubscriptionPeriod
    }
}
