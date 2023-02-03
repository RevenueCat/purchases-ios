//
//  EntitlementInfosTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class EntitlementInfosTests: TestCase {

    private static let formatter = ISO8601DateFormatter()
    private var response: [String: Any] = [:]

    override func setUp() {
        super.setUp()

        self.stubResponse()
    }

    func testMultipleEntitlements() throws {
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ],
                "lifetime_cat": [
                    "expires_date": nil,
                    "product_identifier": "lifetime",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            nonSubscriptions: [
                "lifetime": [
                    [
                        "id": "5b9ba226bc",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T22:10:27Z",
                        "purchase_date": "2019-07-26T22:10:27Z",
                        "store": "app_store"
                    ],
                    [
                        "id": "ea820afcc4",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:45:40Z",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store"
                    ]
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "app_store",
                    "unsubscribe_detected_at": nil
                ]
            ]
        )

        let subscriberInfo = try CustomerInfo(data: response)
        expect(subscriberInfo.entitlements.all.count).to(equal(2))
        // The default is "pro_cat"
        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal()
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct()
        // Check for "lifetime_cat" entitlement
        try verifyEntitlementActive(true, entitlement: "lifetime_cat")
        try verifyRenewal(false, entitlement: "lifetime_cat")
        try verifyPeriodType(PeriodType.normal, expectedEntitlement: "lifetime_cat")
        try verifyStore(Store.appStore, expectedEntitlement: "lifetime_cat")
        try verifySandbox(false, expectedEntitlement: "lifetime_cat")
        try verifyProduct(expectedIdentifier: "lifetime",
                          expectedLatestPurchaseDate: Self.formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedOriginalPurchaseDate: Self.formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedExpirationDate: nil,
                          expectedEntitlement: "lifetime_cat"
        )
    }

    func testStringAccessor() throws {
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "1999-07-26T23:30:41Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2000-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "1999-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "1999-07-26T23:30:41Z",
                    "store": "app_store",
                    "unsubscribe_detected_at": nil
                ]
            ]
        )

        let subscriberInfo = try CustomerInfo(data: response)

        expect(subscriberInfo.entitlements["pro_cat"]).toNot(beNil())
        expect(subscriberInfo.entitlements.active["pro_cat"]).toNot(beNil())
    }

    func testActiveSubscription() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "1999-07-26T23:30:41Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "1999-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "1999-07-26T23:30:41Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ]
        )

        try verifyEntitlementActive()
    }

    func testSubscriptionActiveIfExpiresDateEqualsRequestDate() throws {
        let expirationAndRequestDate = "2019-08-16T10:30:42Z"
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": expirationAndRequestDate,
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "1999-07-26T23:30:41Z"
                    ]
                ],
                nonSubscriptions: [:],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "1999-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "1999-07-26T23:30:41Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ],
                requestDate: expirationAndRequestDate
        )

        try verifyEntitlementActive()
    }

    func testInactiveSubscription() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2000-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "1999-07-26T23:30:41Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2000-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "1999-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "1999-07-26T23:30:41Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ]
        )

        try verifyEntitlementActive(false)
    }

    func testGetsEmptySubscriberInfo() throws {
        stubResponse()
        let subscriberInfo = try CustomerInfo(data: response)

        expect(subscriberInfo.originalAppUserId) == "cesarsandbox1"
        expect(subscriberInfo.entitlements.all).to(beEmpty())
    }

    func testCreatesEntitlementInfos() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal()
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct()
    }

    func testCreatesEntitlementWithNonSubscriptionsAndSubscription() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "app_store"
                        ]
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ]
        )

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal(false)
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct(expectedIdentifier: "lifetime",
                          expectedLatestPurchaseDate: Self.formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedOriginalPurchaseDate: Self.formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedExpirationDate: nil)
    }

    func testSubscriptionWillRenew() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal()
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct()
    }

    func testSubscriptionWontRenewBillingError() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": "2019-07-27T23:30:41Z",
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal(false, expectedBillingIssueDetectedAt: Self.formatter.date(from: "2019-07-27T23:30:41Z"))
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct()
    }

    func testSubscriptionWontRenewCancelled() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": "2019-07-27T23:30:41Z"
                    ]
                ])

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal(false, expectedUnsubscribeDetectedAt: Self.formatter.date(from: "2019-07-27T23:30:41Z"))
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct()
    }

    func testSubscriptionWontRenewBillingErrorAndCancelled() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": "2019-07-27T22:30:41Z",
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": "2019-07-27T23:30:41Z"
                    ]
                ])

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal(
            false,
            expectedUnsubscribeDetectedAt: Self.formatter.date(from: "2019-07-27T23:30:41Z"),
            expectedBillingIssueDetectedAt: Self.formatter.date(from: "2019-07-27T22:30:41Z")
        )
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct()
    }

    func testSubscriptionIsSandboxInteger() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": true,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal()
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox(true)
        try verifyProduct()
    }

    func mockSubscriptions(ownershipType: String?) -> [String: Any] {
        var monthly: [String: Any?] = [
            "billing_issues_detected_at": nil,
            "expires_date": "2200-07-26T23:50:40Z",
            "is_sandbox": true,
            "original_purchase_date": "2019-07-26T23:30:41Z",
            "period_type": "normal",
            "purchase_date": "2019-07-26T23:45:40Z",
            "store": "app_store",
            "unsubscribe_detected_at": nil
        ]
        if ownershipType != nil {
            monthly["ownership_type"] = ownershipType!
        }
        return [
            "monthly_freetrial": monthly
        ]
    }

    func testParseOwnershipTypeAssignsTheRightValue() throws {
        let mockEntitlements = [
            "pro_cat": [
                "expires_date": "2200-07-26T23:50:40Z",
                "product_identifier": "monthly_freetrial",
                "purchase_date": "2019-07-26T23:45:40Z"
            ]
        ]
        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: "PURCHASED"))

        var subscriberInfo = try CustomerInfo(data: response)
        var entitlement = try XCTUnwrap(subscriberInfo.entitlements.active["pro_cat"])

        expect(entitlement.ownershipType) == .purchased

        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: "FAMILY_SHARED"))

        subscriberInfo = try CustomerInfo(data: response)
        entitlement = try XCTUnwrap(subscriberInfo.entitlements.active["pro_cat"])

        expect(entitlement.ownershipType) == .familyShared

        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: "BOATY_MCBOATFACE"))

        subscriberInfo = try CustomerInfo(data: response)
        entitlement = try XCTUnwrap(subscriberInfo.entitlements.active["pro_cat"])

        expect(entitlement.ownershipType) == .unknown
    }

    func testParseOwnershipTypeDefaultsToPurchasedIfMissing() throws {
        let mockEntitlements = [
            "pro_cat": [
                "expires_date": "2200-07-26T23:50:40Z",
                "product_identifier": "monthly_freetrial",
                "purchase_date": "2019-07-26T23:45:40Z"
            ]
        ]
        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: nil))

        let subscriberInfo = try CustomerInfo(data: response)
        let entitlement = try XCTUnwrap(subscriberInfo.entitlements.active["pro_cat"])

        expect(entitlement.ownershipType) == .purchased
    }

    func testNonSubscription() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "app_store"
                        ]
                    ]
                ],
                subscriptions: [:]
        )

        try verifySubscriberInfo()
        try verifyEntitlementActive()
        try verifyRenewal(false)
        try verifyPeriodType()
        try verifyStore()
        try verifySandbox()
        try verifyProduct(expectedIdentifier: "lifetime",
                          expectedLatestPurchaseDate: Self.formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedOriginalPurchaseDate: Self.formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedExpirationDate: nil)

    }

    func testParseStoreFromSubscription() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        try verifyStore(.appStore)

        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "mac_app_store",
                    "unsubscribe_detected_at": nil
                ]
            ])
        try verifyStore(.macAppStore)

        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "play_store",
                    "unsubscribe_detected_at": nil
                ]
            ])
        try verifyStore(.playStore)

        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "promotional",
                    "unsubscribe_detected_at": nil
                ]
            ])
        try verifyStore(.promotional)

        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "stripe",
                    "unsubscribe_detected_at": nil
                ]
            ])
        try verifyStore(.stripe)

        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "amazon",
                    "unsubscribe_detected_at": nil
                ]
            ])
        try verifyStore(.amazon)

        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2200-07-26T23:50:40Z",
                    "product_identifier": "monthly_freetrial",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            subscriptions: [
                "monthly_freetrial": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2200-07-26T23:50:40Z",
                    "is_sandbox": false,
                    "original_purchase_date": "2019-07-26T23:30:41Z",
                    "period_type": "normal",
                    "purchase_date": "2019-07-26T23:45:40Z",
                    "store": "tienda",
                    "unsubscribe_detected_at": nil
                ]
            ])
        try verifyStore(.unknownStore)
    }

    func testParseStoreFromNonSubscription() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "app_store"
                        ]
                    ]
                ],
                subscriptions: [:]
        )
        try verifyStore(.appStore)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "mac_app_store"
                        ]
                    ]
                ],
                subscriptions: [:]
        )
        try verifyStore(.macAppStore)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "play_store"
                        ]
                    ]
                ],
                subscriptions: [:]
        )
        try verifyStore(.playStore)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "promotional"
                        ]
                    ]
                ],
                subscriptions: [:]
        )
        try verifyStore(.promotional)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "stripe"
                        ]
                    ]
                ],
                subscriptions: [:]
        )
        try verifyStore(.stripe)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "amazon"
                        ]
                    ]
                ],
                subscriptions: [:]
        )
        try verifyStore(.amazon)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": nil,
                        "product_identifier": "lifetime",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                nonSubscriptions: [
                    "lifetime": [
                        [
                            "id": "5b9ba226bc",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T22:10:27Z",
                            "purchase_date": "2019-07-26T22:10:27Z",
                            "store": "app_store"
                        ],
                        [
                            "id": "ea820afcc4",
                            "is_sandbox": false,
                            "original_purchase_date": "2019-07-26T23:45:40Z",
                            "purchase_date": "2019-07-26T23:45:40Z",
                            "store": "tienda"
                        ]
                    ]
                ],
                subscriptions: [:]
        )
        try verifyStore(.unknownStore)
    }

    func testParsePeriod() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "normal",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        try verifyPeriodType(.normal)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "intro",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])
        try verifyPeriodType(.intro)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "trial",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])
        try verifyPeriodType(.trial)

        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2200-07-26T23:50:40Z",
                        "product_identifier": "monthly_freetrial",
                        "purchase_date": "2019-07-26T23:45:40Z"
                    ]
                ],
                subscriptions: [
                    "monthly_freetrial": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2200-07-26T23:50:40Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:30:41Z",
                        "period_type": "period",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": nil
                    ]
                ])
        try verifyPeriodType(.normal)
    }

    func testParsePeriodForNonSubscription() throws {
        stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": nil,
                    "product_identifier": "lifetime",
                    "purchase_date": "2019-07-26T23:45:40Z"
                ]
            ],
            nonSubscriptions: [
                "lifetime": [
                    [
                        "id": "5b9ba226bc",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T22:10:27Z",
                        "purchase_date": "2019-07-26T22:10:27Z",
                        "store": "app_store"
                    ],
                    [
                        "id": "ea820afcc4",
                        "is_sandbox": false,
                        "original_purchase_date": "2019-07-26T23:45:40Z",
                        "purchase_date": "2019-07-26T23:45:40Z",
                        "store": "app_store"
                    ]
                ]
            ],
            subscriptions: [:]
        )
        try verifyPeriodType(.normal)
    }

    func testPromoWillRenew() throws {
        stubResponse(
                entitlements: [
                    "pro_cat": [
                        "expires_date": "2221-01-10T02:35:25Z",
                        "product_identifier": "rc_promo_pro_cat_lifetime",
                        "purchase_date": "2021-02-27T02:35:25Z"
                    ]
                ],
                subscriptions: [
                    "rc_promo_pro_cat_lifetime": [
                        "billing_issues_detected_at": nil,
                        "expires_date": "2221-01-10T02:35:25Z",
                        "is_sandbox": false,
                        "original_purchase_date": "2021-02-27T02:35:25Z",
                        "period_type": "normal",
                        "purchase_date": "2021-02-27T02:35:25Z",
                        "store": "promotional",
                        "unsubscribe_detected_at": nil
                    ]
                ])

        try verifyRenewal(false)
    }

    // MARK: - Active

    private func stubResponseWithActiveEntitlement(inSandbox sandbox: Bool) {
        self.stubResponse(
            entitlements: [
                "pro_cat": [
                    "expires_date": "2221-01-10T02:35:25Z",
                    "product_identifier": "rc_promo_pro_cat_lifetime",
                    "purchase_date": "2021-02-27T02:35:25Z"
                ],
                "another_entitlement": [
                    "expires_date": "2016-01-10T02:35:25Z",
                    "product_identifier": "another_product",
                    "purchase_date": "2015-02-27T02:35:25Z"
                ]
            ],
            subscriptions: [
                "rc_promo_pro_cat_lifetime": [
                    "billing_issues_detected_at": nil,
                    "expires_date": "2221-01-10T02:35:25Z",
                    "is_sandbox": sandbox,
                    "original_purchase_date": "2021-02-27T02:35:25Z",
                    "period_type": "normal",
                    "purchase_date": "2021-02-27T02:35:25Z",
                    "store": "promotional",
                    "unsubscribe_detected_at": nil
                ]
            ])
    }

    func testActiveInAnyEnvironmentIncludesSandboxInSandbox() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: true)
        try self.verifyEntitlementActiveInAnyEnvironment(sandbox: true)
    }

    func testActiveInAnyEnvironmentIncludesProductionInProduction() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: false)
        try self.verifyEntitlementActiveInAnyEnvironment(sandbox: false)
    }

    func testActiveInAnyEnvironmentIncludesSandboxInProduction() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: true)
        try self.verifyEntitlementActiveInAnyEnvironment(sandbox: false)
    }

    func testActiveInAnyEnvironmentIncludesProductionInSandbox() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: false)
        try self.verifyEntitlementActiveInAnyEnvironment(sandbox: true)
    }

    func testActiveInCurrentEnvironmentIncludesSandboxInSandbox() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: true)
        try self.verifyEntitlementActiveInCurrentEnvironment(sandbox: true)
    }

    func testActiveInCurrentEnvironmentIncludesProductionInProduction() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: false)
        try self.verifyEntitlementActiveInCurrentEnvironment(sandbox: false)
    }

    func testActiveInCurrentEnvironmentDoesNotIncludeSandboxInProduction() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: true)
        try self.verifyEntitlementActiveInCurrentEnvironment(false, sandbox: false)
    }

    func testActiveInCurrentEnvironmentDoesNotIncludesProductionInSandbox() throws {
        self.stubResponseWithActiveEntitlement(inSandbox: false)
        try self.verifyEntitlementActiveInCurrentEnvironment(false, sandbox: true)
    }

    // MARK: -

    func testRawData() throws {
        let info = try CustomerInfo(data: self.response)

        expect(info.entitlements.all.values).to(allPass {
            !$0.rawData.isEmpty
        })
    }

}

private extension EntitlementInfosTests {

    func stubResponse(entitlements: [String: Any] = [:],
                      nonSubscriptions: [String: Any] = [:],
                      subscriptions: [String: Any] = [:],
                      requestDate: String = "2019-08-16T10:30:42Z") {
        self.response = [
            "request_date": requestDate,
            "subscriber": [
                "entitlements": entitlements,
                "first_seen": "2019-07-26T23:29:50Z",
                "non_subscriptions": nonSubscriptions,
                "original_app_user_id": "cesarsandbox1",
                "original_application_version": "1.0",
                "subscriptions": subscriptions
            ]
        ]
    }

    func verifySubscriberInfo(file: FileString = #file, line: UInt = #line) throws {
        let subscriberInfo = try CustomerInfo(data: response)

        expect(file: file, line: line, subscriberInfo).toNot(beNil())
        expect(file: file, line: line, subscriberInfo.firstSeen).to(
            equal(Self.formatter.date(from: "2019-07-26T23:29:50Z")),
            description: "Invalid first seen date"
        )
        expect(file: file, line: line, subscriberInfo.originalAppUserId) == "cesarsandbox1"
    }

    func verifyEntitlementActive(
        _ expectedEntitlementActive: Bool = true,
        entitlement: String = "pro_cat",
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[entitlement])

        expect(file: file, line: line, proCat.identifier) == entitlement
        expect(file: file, line: line, subscriberInfo.entitlements.all.keys.contains(entitlement)) == true
        expect(file: file, line: line, subscriberInfo.entitlements.active.keys.contains(entitlement))
        == expectedEntitlementActive
        expect(file: file, line: line, proCat.isActive) == expectedEntitlementActive
    }

    private func extractEntitlements(identifier: String,
                                     inSandbox sandbox: Bool) throws -> EntitlementInfos {
        return try CustomerInfo(
            data: self.response,
            sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: sandbox)
        ).entitlements
    }

    func verifyEntitlementActiveInAnyEnvironment(
        _ expectedEntitlementActive: Bool = true,
        identifier: String = "pro_cat",
        sandbox: Bool,
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let entitlements = try self.extractEntitlements(identifier: identifier, inSandbox: sandbox)
        let entitlement = try XCTUnwrap(entitlements[identifier])

        expect(file: file, line: line, entitlement.identifier) == identifier
        expect(file: file, line: line, Set(entitlements.all.keys)).to(contain([identifier]))
        expect(file: file, line: line, entitlement.isActive) == true
        expect(file: file, line: line, entitlement.isActiveInAnyEnvironment) == expectedEntitlementActive

        expect(file: file, line: line, Set(entitlements.activeInAnyEnvironment.keys))
        == (expectedEntitlementActive ? [identifier] : [])
    }

    func verifyEntitlementActiveInCurrentEnvironment(
        _ expectedEntitlementActive: Bool = true,
        identifier: String = "pro_cat",
        sandbox: Bool,
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let entitlements = try self.extractEntitlements(identifier: identifier, inSandbox: sandbox)
        let entitlement = try XCTUnwrap(entitlements[identifier])

        expect(file: file, line: line, entitlement.identifier) == identifier
        expect(file: file, line: line, entitlements.all.keys).to(contain([identifier]))
        expect(file: file, line: line, entitlement.isActive) == true
        expect(file: file, line: line, entitlement.isActiveInCurrentEnvironment) == expectedEntitlementActive

        expect(file: file, line: line, Set(entitlements.activeInCurrentEnvironment.keys))
        == (expectedEntitlementActive ? [identifier] : [])
    }

    func verifyRenewal(_ expectedWillRenew: Bool = true,
                       expectedUnsubscribeDetectedAt: Date? = nil,
                       expectedBillingIssueDetectedAt: Date? = nil,
                       entitlement: String = "pro_cat",
                       file: FileString = #file,
                       line: UInt = #line) throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[entitlement])

        expect(file: file, line: line, proCat.willRenew) == expectedWillRenew

        if expectedUnsubscribeDetectedAt != nil {
            expect(file: file, line: line, proCat.unsubscribeDetectedAt).to(
                equal(expectedUnsubscribeDetectedAt),
                description: "Invalid unsubscribe date"
            )
        } else {
            expect(file: file, line: line, proCat.unsubscribeDetectedAt).to(beNil())
        }

        if expectedBillingIssueDetectedAt != nil {
            expect(file: file, line: line, proCat.billingIssueDetectedAt).to(
                equal(expectedBillingIssueDetectedAt),
                description: "Invalid billing issue date"
            )
        } else {
            expect(file: file, line: line, proCat.billingIssueDetectedAt).to(beNil())
        }
    }

    func verifyPeriodType(
        _ expectedPeriodType: PeriodType = .normal,
        expectedEntitlement: String = "pro_cat",
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        expect(file: file, line: line, proCat.periodType) == expectedPeriodType
    }

    func verifyStore(
        _ expectedStore: Store = .appStore,
        expectedEntitlement: String = "pro_cat",
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        expect(file: file, line: line, proCat.store) == expectedStore
    }

    func verifySandbox(
        _ expectedIsSandbox: Bool = false,
        expectedEntitlement: String = "pro_cat",
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        expect(file: file, line: line, proCat.isSandbox) == expectedIsSandbox
    }

    func verifyProduct(
        expectedIdentifier: String = "monthly_freetrial",
        expectedEntitlement: String = "pro_cat",
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        try verifyProduct(
            expectedIdentifier: expectedIdentifier,
            expectedLatestPurchaseDate: Self.formatter.date(from: "2019-07-26T23:45:40Z"),
            expectedOriginalPurchaseDate: Self.formatter.date(from: "2019-07-26T23:30:41Z"),
            expectedExpirationDate: Self.formatter.date(from: "2200-07-26T23:50:40Z"),
            expectedEntitlement: expectedEntitlement,
            file: file, line: line
        )
    }

    func verifyProduct(
        expectedIdentifier: String,
        expectedLatestPurchaseDate: Date?,
        expectedOriginalPurchaseDate: Date?,
        expectedExpirationDate: Date?,
        expectedEntitlement: String = "pro_cat",
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        expect(file: file, line: line, proCat.identifier).to(
            equal(expectedEntitlement),
            description: "Invalid identifier"
        )

        if expectedLatestPurchaseDate != nil {
            expect(file: file, line: line, proCat.latestPurchaseDate).to(
                equal(expectedLatestPurchaseDate),
                description: "Invalid latest purchase date"
            )
        } else {
            expect(file: file, line: line, proCat.latestPurchaseDate).to(beNil())
        }

        if expectedOriginalPurchaseDate != nil {
            expect(file: file, line: line, proCat.originalPurchaseDate).to(
                equal(expectedOriginalPurchaseDate),
                description: "Invalid original purchase date"
            )
        } else {
            expect(file: file, line: line, proCat.originalPurchaseDate).to(beNil())
        }

        if expectedExpirationDate != nil {
            expect(file: file, line: line, proCat.expirationDate).to(
                equal(expectedExpirationDate),
                description: "Invalid expiration date"
            )
        } else {
            expect(file: file, line: line, proCat.expirationDate).to(beNil())
        }

        expect(file: file, line: line, proCat.productIdentifier).to(
            equal(expectedIdentifier),
            description: "Invalid product identifier"
        )
    }

}
