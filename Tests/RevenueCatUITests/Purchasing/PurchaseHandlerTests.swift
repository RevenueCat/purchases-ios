//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHandlerTests.swift
//
//  Created by Nacho Soto on 7/31/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class PurchaseHandlerTests: TestCase {

    func testInitialState() async throws {
        let handler: PurchaseHandler = .mock()

        expect(handler.purchaseResult).to(beNil())
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.purchased) == false
        expect(handler.restored) == false
        expect(handler.actionInProgress) == false
    }

    func testPurchaseSetsCustomerInfo() async throws {
        let handler: PurchaseHandler = .mock()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)

        expect(handler.purchaseResult?.customerInfo) === TestData.customerInfo
        expect(handler.restoredCustomerInfo).to(beNil())
        expect(handler.purchased) == true
        expect(handler.actionInProgress) == false
    }

    func testCancellingPurchase() async throws {
        let handler: PurchaseHandler = .cancelling()

        _ = try await handler.purchase(package: TestData.packageWithIntroOffer)
        expect(handler.purchaseResult).to(beNil())
        expect(handler.purchased) == false
        expect(handler.actionInProgress) == false
    }

    func testRestorePurchases() async throws {
        let handler: PurchaseHandler = .mock()

        let result = try await handler.restorePurchases()

        expect(result.info) === TestData.customerInfo
        expect(result.success) == false
        expect(handler.restored) == true
        expect(handler.restoredCustomerInfo) === TestData.customerInfo
        expect(handler.purchaseResult).to(beNil())
        expect(handler.actionInProgress) == false
    }

    func testRestorePurchasesWithActiveSubscriptions() async throws {
        let handler: PurchaseHandler = .mock(Self.customerInfoWithSubscriptions)

        let result = try await handler.restorePurchases()
        expect(result.info) === Self.customerInfoWithSubscriptions
        expect(result.success) == true
    }

    func testRestorePurchasesWithNonSubscriptions() async throws {
        let handler: PurchaseHandler = .mock(Self.customerInfoWithNonSubscriptions)

        let result = try await handler.restorePurchases()
        expect(result.info) === Self.customerInfoWithNonSubscriptions
        expect(result.success) == true
    }

    func testCloseEventIsTrackedOnlyAfterImpressionAndOnlyOnce() async throws {
        let handler: PurchaseHandler = .mock()

        let eventData: PaywallEvent.Data = .init(
            offering: TestData.offeringWithIntroOffer,
            paywall: TestData.paywallWithIntroOffer,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .init(identifier: "en_US"),
            darkMode: false
        )

        let result1 = handler.trackPaywallClose()
        expect(result1) == false

        handler.trackPaywallImpression(eventData)

        let result2 = handler.trackPaywallClose()
        expect(result2) == true
        let result3 = handler.trackPaywallClose()
        expect(result3) == false
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PurchaseHandlerTests {

    static let customerInfoWithSubscriptions: CustomerInfo = {
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
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2062-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "2022-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "2022-04-12T00:03:28Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                }
            }
        }
        """
        )
    }()

    static let customerInfoWithNonSubscriptions: CustomerInfo = {
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
                    "com.revenuecat.product.tip": [
                        {
                            "purchase_date": "2022-02-11T00:03:28Z",
                            "original_purchase_date": "2022-03-10T00:04:28Z",
                            "id": "17459f5ff7",
                            "store_transaction_id": "340001090153249",
                            "store": "app_store",
                            "is_sandbox": false
                        }
                    ]
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                },
                "entitlements": {
                }
            }
        }
        """
        )
    }()

}

#endif
