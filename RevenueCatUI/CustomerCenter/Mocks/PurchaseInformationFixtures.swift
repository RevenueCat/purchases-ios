//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInformationFixtures.swift
//
//  Created by Cesar de la Vega on 10/25/24.

import Foundation
@_spi(Internal) import RevenueCat
import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PurchaseInformationFixtures {

    static func product(
        id: String,
        title: String,
        duration: SKProduct.PeriodUnit?,
        price: Decimal,
        priceLocale: String = "en_US",
        offerIdentifier: String? = nil
    ) -> StoreProduct {
        // Using SK1 products because they can be mocked, but CustomerCenterViewModel
        // works with generic `StoreProduct`s regardless of what they contain
        let sk1Product = MockSK1Product(mockProductIdentifier: id, mockLocalizedTitle: title)
        sk1Product.mockPrice = price
        sk1Product.mockPriceLocale = Locale(identifier: priceLocale)
        if let duration = duration {
            sk1Product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: duration)
        } else {
            sk1Product.mockSubscriptionPeriod = nil
        }
        if let offerIdentifier = offerIdentifier {
            sk1Product.mockDiscount = SKProductDiscount(identifier: offerIdentifier)
        }
        return StoreProduct(sk1Product: sk1Product)
    }

    static let screenWithIneligiblePromo: CustomerCenterConfigData.Screen = .init(
        type: .management,
        title: "Manage Subscription",
        subtitle: "Manage your subscription details here",
        paths: [
            .init(
                id: "1",
                title: "Didn't receive purchase",
                url: nil,
                openMethod: nil,
                type: .missingPurchase,
                detail: .promotionalOffer(CustomerCenterConfigData.HelpPath.PromotionalOffer(
                    iosOfferId: "offer_id",
                    eligible: false,
                    title: "title",
                    subtitle: "subtitle",
                    productMapping: ["product_id": "offer_id"]
                )),
                refundWindowDuration: .forever
            )
        ],
        offering: nil
    )

    static func screenWithPromo(offerID: String) -> CustomerCenterConfigData.Screen {
        return .init(
            type: .management,
            title: "Manage Subscription",
            subtitle: "Manage your subscription details here",
            paths: [
                .init(
                    id: "1",
                    title: "Didn't receive purchase",
                    url: nil,
                    openMethod: nil,
                    type: .missingPurchase,
                    detail: .promotionalOffer(CustomerCenterConfigData.HelpPath.PromotionalOffer(
                        iosOfferId: offerID,
                        eligible: true,
                        title: "title",
                        subtitle: "subtitle",
                        productMapping: ["product_id": "offer_id"]
                    )),
                    refundWindowDuration: .forever
                )
            ],
            offering: nil
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class MockSK1Product: SK1Product {

    var mockProductIdentifier: String
    var mockLocalizedTitle: String

    init(mockProductIdentifier: String, mockLocalizedTitle: String) {
        self.mockProductIdentifier = mockProductIdentifier
        self.mockLocalizedTitle = mockLocalizedTitle

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

    override var introductoryPrice: SKProductDiscount? {
        return mockDiscount
    }

    private var _mockDiscount: Any?

    var mockDiscount: SKProductDiscount? {
        // swiftlint:disable:next force_cast
        get { return self._mockDiscount as! SKProductDiscount? }
        set { self._mockDiscount = newValue }
    }

    override var discounts: [SKProductDiscount] {
        return self.mockDiscount.map { [$0] } ?? []
    }

    private lazy var _mockSubscriptionPeriod: Any? = {
        return SKProductSubscriptionPeriod(numberOfUnits: 1, unit: SKProduct.PeriodUnit.month)
    }()

    var mockSubscriptionPeriod: SKProductSubscriptionPeriod? {
        // swiftlint:disable:next force_cast
        get { self._mockSubscriptionPeriod as! SKProductSubscriptionPeriod? }
        set { self._mockSubscriptionPeriod = newValue }
    }

    override var subscriptionPeriod: SKProductSubscriptionPeriod? {
        return mockSubscriptionPeriod
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension MockSK1Product: @unchecked Sendable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension SKProductSubscriptionPeriod {

    convenience init(numberOfUnits: Int,
                     unit: SK1Product.PeriodUnit) {
        self.init()
        self.setValue(numberOfUnits, forKey: "numberOfUnits")
        self.setValue(unit.rawValue, forKey: "unit")
    }

}

fileprivate extension SKProductDiscount {

    convenience init(identifier: String) {
        self.init()
        self.setValue(identifier, forKey: "identifier")
        self.setValue(subscriptionPeriod, forKey: "subscriptionPeriod")
    }

}
