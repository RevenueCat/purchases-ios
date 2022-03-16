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

class EntitlementInfosTests: XCTestCase {

    private let formatter = DateFormatter()
    private var response: [String: Any] = [:]

    override func setUp() {
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        stubResponse()
    }

    func stubResponse(entitlements: [String: Any] = [:],
                      nonSubscriptions: [String: Any] = [:],
                      subscriptions: [String: Any] = [:]) {
        response = [
            "request_date": "2019-08-16T10:30:42Z",
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
                          expectedLatestPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedOriginalPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
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
                          expectedLatestPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedOriginalPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
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
        try verifyRenewal(false, expectedBillingIssueDetectedAt: formatter.date(from: "2019-07-27T23:30:41Z"))
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
        try verifyRenewal(false, expectedUnsubscribeDetectedAt: formatter.date(from: "2019-07-27T23:30:41Z"))
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
            expectedUnsubscribeDetectedAt: formatter.date(from: "2019-07-27T23:30:41Z"),
            expectedBillingIssueDetectedAt: formatter.date(from: "2019-07-27T22:30:41Z")
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
                          expectedLatestPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedOriginalPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
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

    func verifySubscriberInfo() throws {
        let subscriberInfo = try CustomerInfo(data: response)

        expect(subscriberInfo).toNot(beNil())
        expect(subscriberInfo.firstSeen).to(equal(formatter.date(from: "2019-07-26T23:29:50Z")))
        expect(subscriberInfo.originalAppUserId).to(equal("cesarsandbox1"))
    }

    func verifyEntitlementActive(_ expectedEntitlementActive: Bool = true, entitlement: String = "pro_cat") throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[entitlement])

        expect(proCat.identifier) == entitlement
        expect(subscriberInfo.entitlements.all.keys.contains(entitlement)) == true
        expect(subscriberInfo.entitlements.active.keys.contains(entitlement)) == expectedEntitlementActive
        expect(proCat.isActive) == expectedEntitlementActive
    }

    func verifyRenewal(_ expectedWillRenew: Bool = true,
                       expectedUnsubscribeDetectedAt: Date? = nil,
                       expectedBillingIssueDetectedAt: Date? = nil,
                       entitlement: String = "pro_cat") throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[entitlement])

        expect(proCat.willRenew) == expectedWillRenew

        if expectedUnsubscribeDetectedAt != nil {
            expect(proCat.unsubscribeDetectedAt) == expectedUnsubscribeDetectedAt
        } else {
            expect(proCat.unsubscribeDetectedAt).to(beNil())
        }

        if expectedBillingIssueDetectedAt != nil {
            expect(proCat.billingIssueDetectedAt) == expectedBillingIssueDetectedAt
        } else {
            expect(proCat.billingIssueDetectedAt).to(beNil())
        }
    }

    func verifyPeriodType(
        _ expectedPeriodType: PeriodType = PeriodType.normal,
        expectedEntitlement: String = "pro_cat"
    ) throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        expect(proCat.periodType) == expectedPeriodType
    }

    func verifyStore(_ expectedStore: Store = Store.appStore, expectedEntitlement: String = "pro_cat") throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        expect(proCat.store) == expectedStore
    }

    func verifySandbox(_ expectedIsSandbox: Bool = false, expectedEntitlement: String = "pro_cat") throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        expect(proCat.isSandbox) == expectedIsSandbox
    }

    func verifyProduct(expectedIdentifier: String = "monthly_freetrial",
                       expectedEntitlement: String = "pro_cat") throws {
        try verifyProduct(expectedIdentifier: expectedIdentifier,
                          expectedLatestPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                          expectedOriginalPurchaseDate: formatter.date(from: "2019-07-26T23:30:41Z"),
                          expectedExpirationDate: formatter.date(from: "2200-07-26T23:50:40Z"),
                          expectedEntitlement: expectedEntitlement
        )
    }

    func verifyProduct(expectedIdentifier: String,
                       expectedLatestPurchaseDate: Date?,
                       expectedOriginalPurchaseDate: Date?,
                       expectedExpirationDate: Date?,
                       expectedEntitlement: String = "pro_cat") throws {
        let subscriberInfo = try CustomerInfo(data: response)
        let proCat = try XCTUnwrap(subscriberInfo.entitlements[expectedEntitlement])

        if expectedLatestPurchaseDate != nil {
            expect(proCat.latestPurchaseDate) == expectedLatestPurchaseDate
        } else {
            expect(proCat.latestPurchaseDate).to(beNil())
        }

        if expectedOriginalPurchaseDate != nil {
            expect(proCat.originalPurchaseDate) == expectedOriginalPurchaseDate
        } else {
            expect(proCat.originalPurchaseDate).to(beNil())
        }

        if expectedExpirationDate != nil {
            expect(proCat.expirationDate) == expectedExpirationDate
        } else {
            expect(proCat.expirationDate).to(beNil())
        }

        expect(proCat.productIdentifier) == expectedIdentifier
    }
}
