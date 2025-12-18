//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoFixtures.swift
//
//  Created by Cesar de la Vega on 28/10/24.

import Foundation
@_spi(Internal) import RevenueCat

// swiftlint:disable force_unwrapping
// swiftlint:disable:next type_body_length
class CustomerInfoFixtures {

    private init() {}

    class Subscription {

        let id: String
        let json: String

        init(id: String,
             store: String,
             purchaseDate: String,
             expirationDate: String?,
             priceAmount: Decimal = 4.99,
             currency: String = "USD",
             unsubscribeDetectedAt: String? = nil,
             periodType: PeriodType = .normal) {
            self.id = id
            self.json = """
            {
                "auto_resume_date": null,
                "billing_issues_detected_at": null,
                "expires_date": \(expirationDate != nil ? "\"\(expirationDate!)\"" : "null"),
                "grace_period_expires_date": null,
                "is_sandbox": true,
                "original_purchase_date": "\(purchaseDate)",
                "ownership_type": "PURCHASED",
                "period_type": "\(periodType.stringValue)",
                "purchase_date": "\(purchaseDate)",
                "refunded_at": null,
                "store": "\(store)",
                "store_transaction_id": "0",
                "unsubscribe_detected_at": \(unsubscribeDetectedAt != nil ? "\"\(unsubscribeDetectedAt!)\"" : "null"),
                "display_name": "Weekly Scratched Sofa",
                "price": {
                  "amount": \(periodType == .trial ? 0 : priceAmount),
                  "currency": \"\(currency)\"
                }
            }
            """
        }

    }

    class Entitlement {

        let id: String
        let json: String

        init(entitlementId: String, productId: String, purchaseDate: String, expirationDate: String? = nil) {
            self.id = entitlementId
            self.json = """
            {
                "expires_date": \(expirationDate != nil ? "\"\(expirationDate!)\"" : "null"),
                "grace_period_expires_date": null,
                "product_identifier": "\(productId)",
                "purchase_date": "\(purchaseDate)"
            }
            """
        }

    }

    class NonSubscriptionTransaction {
        let productId: String
        let id: String
        let json: String

        init(productId: String = "onetime", id: String, store: String, purchaseDate: String) {
            self.productId = productId
            self.id = id
            self.json = """
            {
                "id": "\(id)",
                "is_sandbox": true,
                "original_purchase_date": "\(purchaseDate)",
                "purchase_date": "\(purchaseDate)",
                "store": "\(store)",
                "store_transaction_id": "123"
            }
            """
        }
    }

    static func customerInfo(
        subscriptions: [Subscription],
        entitlements: [Entitlement],
        nonSubscriptions: [NonSubscriptionTransaction] = []
    ) -> CustomerInfo {
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

        let nonSubscriptionsByProduct = Dictionary(grouping: nonSubscriptions, by: { $0.productId })
        let nonSubscriptionsJson = nonSubscriptionsByProduct.map { productId, purchases in
            """
            "\(productId)": [
                \(purchases.map { $0.json }.joined(separator: ",\n"))
            ]
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
                    \(nonSubscriptionsJson)
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

    private static func makeCustomerInfo(
        store: String,
        productId: String = "com.revenuecat.product",
        purchaseDate: String = "2022-04-12T00:03:28Z",
        expirationDate: String? = "2062-04-12T00:03:35Z",
        unsubscribeDetectedAt: String? = nil,
        periodType: PeriodType = .normal
    ) -> CustomerInfo {
        return customerInfo(
            subscriptions: [
                Subscription(
                    id: productId,
                    store: store,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate,
                    unsubscribeDetectedAt: unsubscribeDetectedAt,
                    periodType: periodType
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
    }

    static let customerInfoWithAppleSubscriptions: CustomerInfo = {
        makeCustomerInfo(store: "app_store")
    }()

    static let customerInfoWithExpiredAppleSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "app_store",
            purchaseDate: "1999-04-12T00:03:28Z",
            expirationDate: "2000-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithLifetimeAppSubscrition: CustomerInfo = {
        makeCustomerInfo(
            store: "app_store",
            purchaseDate: "1999-04-12T00:03:28Z",
            expirationDate: nil
        )
    }()

    static let customerInfoWithNonRenewingAppleSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "app_store",
            unsubscribeDetectedAt: "2023-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithGoogleSubscriptions: CustomerInfo = {
        makeCustomerInfo(store: "play_store")
    }()

    static let customerInfoWithNonRenewingGoogleSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "play_store",
            unsubscribeDetectedAt: "2023-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithAmazonSubscriptions: CustomerInfo = {
        makeCustomerInfo(store: "amazon")
    }()

    static let customerInfoWithExpiredGoogleSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "play_store",
            purchaseDate: "1999-04-12T00:03:28Z",
            expirationDate: "2000-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithStripeSubscriptions: CustomerInfo = {
        makeCustomerInfo(store: "stripe")
    }()

    static let customerInfoWithNonRenewingStripeSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "stripe",
            unsubscribeDetectedAt: "2023-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithExpiredStripeSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "stripe",
            purchaseDate: "1999-04-12T00:03:28Z",
            expirationDate: "2000-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithRCBillingSubscriptions: CustomerInfo = {
        makeCustomerInfo(store: "rc_billing")
    }()

    static let customerInfoWithNonRenewingRCBillingSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "rc_billing",
            unsubscribeDetectedAt: "2023-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithExpiredRCBillingSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "rc_billing",
            purchaseDate: "1999-04-12T00:03:28Z",
            expirationDate: "2000-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithPaddleSubscriptions: CustomerInfo = {
        makeCustomerInfo(store: "paddle")
    }()

    static let customerInfoWithNonRenewingPaddleSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "paddle",
            unsubscribeDetectedAt: "2023-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithExpiredPaddleSubscriptions: CustomerInfo = {
        makeCustomerInfo(
            store: "paddle",
            purchaseDate: "1999-04-12T00:03:28Z",
            expirationDate: "2000-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithPromotional: CustomerInfo = {
        makeCustomerInfo(store: "promotional", productId: "rc_promo_pro_cat_yearly")
    }()

    static let customerInfoWithLifetimePromotional: CustomerInfo = {
        makeCustomerInfo(
            store: "promotional",
            productId: "rc_promo_pro_cat_lifetime",
            purchaseDate: "2022-04-12T00:03:28Z",
            expirationDate: "2600-04-12T00:03:35Z"
        )
    }()

    static let customerInfoWithSimulatedStoreSubscriptions: CustomerInfo = {
        makeCustomerInfo(store: "test_store")
    }()

}
