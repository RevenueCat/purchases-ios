//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionInformationFixtures.swift
//
//  Created by Cesar de la Vega on 10/25/24.

import Foundation
@testable import RevenueCat
@testable import RevenueCatUI
import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class SubscriptionInformationFixtures {

    private init() {}

    class Subscription {

        let id: String
        let json: String

        init(id: String,
             store: String,
             purchaseDate: String,
             expirationDate: String,
             unsubscribeDetectedAt: String? = nil) {
            self.id = id
            self.json = """
            {
                "billing_issues_detected_at": null,
                "expires_date": "\(expirationDate)",
                "grace_period_expires_date": null,
                "is_sandbox": true,
                "original_purchase_date": "\(purchaseDate)",
                "period_type": "intro",
                "purchase_date": "\(purchaseDate)",
                "store": "\(store)",
                "unsubscribe_detected_at": \(unsubscribeDetectedAt != nil ? "\"\(unsubscribeDetectedAt!)\"" : "null")
            }
            """
        }

    }

    class Entitlement {

        let id: String
        let json: String

        init(entitlementId: String, productId: String, purchaseDate: String, expirationDate: String) {
            self.id = entitlementId
            self.json = """
            {
                "expires_date": "\(expirationDate)",
                "product_identifier": "\(productId)",
                "purchase_date": "\(purchaseDate)"
            }
            """
        }

    }

    static func product(
        id: String,
        title: String,
        duration: SKProduct.PeriodUnit,
        price: Decimal,
        priceLocale: String = "en_US",
        offerIdentifier: String? = nil
    ) -> StoreProduct {
        // Using SK1 products because they can be mocked, but CustomerCenterViewModel
        // works with generic `StoreProduct`s regardless of what they contain
        let sk1Product = MockSK1Product(mockProductIdentifier: id, mockLocalizedTitle: title)
        sk1Product.mockPrice = price
        sk1Product.mockPriceLocale = Locale(identifier: priceLocale)
        sk1Product.mockSubscriptionPeriod = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: duration)
        if let offerIdentifier = offerIdentifier {
            sk1Product.mockDiscount = SKProductDiscount(identifier: offerIdentifier)
        }
        return StoreProduct(sk1Product: sk1Product)
    }

    static func customerInfo(subscriptions: [Subscription], entitlements: [Entitlement]) -> CustomerInfo {
        let subscriptionsJson = subscriptions.map { subscription in
            """
            "\(subscription.id)": \(subscription.json)
            """
        }.joined(separator: ",\n")

        let entitlementsJson = entitlements.map { entitlement in
            """
            "\(entitlement.id)": \(entitlement.json)
            """
        }.joined(separator: ",\n")

        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    \(subscriptionsJson)
                },
                "entitlements": {
                    \(entitlementsJson)
                }
            }
        }
        """
        )
    }

    static let customerInfoWithAppleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithExpiredAppleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "1999-04-12T00:03:28Z"
        let expirationDate = "2000-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithNonRenewingAppleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        let unsubscribeDetectedAt = "2023-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "app_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    unsubscribeDetectedAt: unsubscribeDetectedAt
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithGoogleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "play_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithNonRenewingGoogleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        let unsubscribeDetectedAt = "2023-04-12T00:03:35Z"

        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "play_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    unsubscribeDetectedAt: unsubscribeDetectedAt
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithExpiredGoogleSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "1999-04-12T00:03:28Z"
        let expirationDate = "2000-04-12T00:03:35Z"

        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "play_store",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithStripeSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "stripe",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithNonRenewingStripeSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        let unsubscribeDetectedAt = "2023-04-12T00:03:35Z"

        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "stripe",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    unsubscribeDetectedAt: unsubscribeDetectedAt
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithExpiredStripeSubscriptions: CustomerInfo = {
        let productId = "com.revenuecat.product"
        let purchaseDate = "1999-04-12T00:03:28Z"
        let expirationDate = "2000-04-12T00:03:35Z"

        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "stripe",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithPromotional: CustomerInfo = {
        let productId = "rc_promo_pro_cat_yearly"
        let purchaseDate = "2051-04-12T00:03:28Z"
        let expirationDate = "2062-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "promotional",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

    static let customerInfoWithLifetimePromotional: CustomerInfo = {
        let productId = "rc_promo_pro_cat_lifetime"
        let purchaseDate = "2022-04-12T00:03:28Z"
        let expirationDate = "2600-04-12T00:03:35Z"
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: "promotional",
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ],
            entitlements: [
                Entitlement(
                    entitlementId: "premium",
                    productId: productId,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
            ]
        )
    }()

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
                    subtitle: "subtitle"
                ))
            )
        ]
    )

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
