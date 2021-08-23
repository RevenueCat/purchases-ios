//
//  EntitlementInfosTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases
import PurchasesCoreSwift

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
    
    func testMultipleEntitlements() {
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
                    ],
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
        
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        expect(subscriberInfo.entitlements.all.count).to(equal(2))
        // The default is "pro_cat"
        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
        // Check for "lifetime_cat" entitlement
        verifyEntitlementActive(true, entitlement: "lifetime_cat")
        verifyRenewal(false, entitlement: "lifetime_cat")
        verifyPeriodType(PeriodType.normal, expectedEntitlement: "lifetime_cat")
        verifyStore(Store.appStore, expectedEntitlement: "lifetime_cat")
        verifySandbox(false, expectedEntitlement: "lifetime_cat")
        verifyProduct(expectedIdentifier: "lifetime",
                      expectedLatestPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                      expectedOriginalPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                      expectedExpirationDate: nil,
                      expectedEntitlement: "lifetime_cat"
        )
    }
    
    func testStringAccessor() {
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
        
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        
        expect(subscriberInfo.entitlements["pro_cat"]).toNot(beNil())
        expect(subscriberInfo.entitlements.active["pro_cat"]).toNot(beNil())
    }

    func testActiveSubscription() {
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

        verifyEntitlementActive()
    }

    func testInactiveSubscription() {
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

        verifyEntitlementActive(false)
    }

    func testGetsEmptySubscriberInfo() {
        stubResponse()
        let subscriberInfo = PurchaserInfo(data: response)

        expect(subscriberInfo?.firstSeen).toNot(beNil())
        expect(subscriberInfo?.originalAppUserId).to(equal("cesarsandbox1"))
        expect(subscriberInfo?.entitlements.all.count).to(be(0))
    }

    func testCreatesEntitlementInfos() {
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

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }


    func testCreatesEntitlementWithNonSubscriptionsAndSubscription() {
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
                        ],
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

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(false)
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct(expectedIdentifier: "lifetime",
                      expectedLatestPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                      expectedOriginalPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                      expectedExpirationDate: nil)
    }


    func testSubscriptionWillRenew(){
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

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionWontRenewBillingError() {
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

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(false, expectedBillingIssueDetectedAt: formatter.date(from: "2019-07-27T23:30:41Z"))
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionWontRenewCancelled() {
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

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(false, expectedUnsubscribeDetectedAt: formatter.date(from: "2019-07-27T23:30:41Z"))
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionWontRenewBillingErrorAndCancelled() {
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

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(false, expectedUnsubscribeDetectedAt: formatter.date(from: "2019-07-27T23:30:41Z"), expectedBillingIssueDetectedAt: formatter.date(from: "2019-07-27T22:30:41Z"))
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct()
    }

    func testSubscriptionIsSandboxInteger() {
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

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal()
        verifyPeriodType()
        verifyStore()
        verifySandbox(true)
        verifyProduct()
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
            "unsubscribe_detected_at": nil,
        ]
        if (ownershipType != nil) {
            monthly["ownership_type"] = ownershipType!
        }
        return [
            "monthly_freetrial": monthly
        ]
    }

    func testParseOwnershipTypeAssignsTheRightValue() {
        let mockEntitlements = [
            "pro_cat": [
                "expires_date": "2200-07-26T23:50:40Z",
                "product_identifier": "monthly_freetrial",
                "purchase_date": "2019-07-26T23:45:40Z"
            ]
        ]
        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: "PURCHASED"))

        var subscriberInfo = PurchaserInfo(data: response)!
        var entitlement: EntitlementInfo? = subscriberInfo.entitlements.active["pro_cat"]
        expect(entitlement).toNot(beNil())
        expect(entitlement!.ownershipType) == .purchased

        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: "FAMILY_SHARED"))

        subscriberInfo = PurchaserInfo(data: response)!
        entitlement = subscriberInfo.entitlements.active["pro_cat"]
        expect(entitlement).toNot(beNil())
        expect(entitlement!.ownershipType) == .familyShared

        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: "BOATY_MCBOATFACE"))

        subscriberInfo = PurchaserInfo(data: response)!
        entitlement = subscriberInfo.entitlements.active["pro_cat"]
        expect(entitlement).toNot(beNil())
        expect(entitlement!.ownershipType) == .unknown
    }

    func testParseOwnershipTypeDefaultsToPurchasedIfMissing() {
        let mockEntitlements = [
            "pro_cat": [
                "expires_date": "2200-07-26T23:50:40Z",
                "product_identifier": "monthly_freetrial",
                "purchase_date": "2019-07-26T23:45:40Z"
            ]
        ]
        stubResponse(entitlements: mockEntitlements,
                     subscriptions: mockSubscriptions(ownershipType: nil))

        let subscriberInfo = PurchaserInfo(data: response)!
        let entitlement: EntitlementInfo? = subscriberInfo.entitlements.active["pro_cat"]
        expect(entitlement).toNot(beNil())
        expect(entitlement!.ownershipType) == .purchased
    }

    func testNonSubscription(){
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
                        ],
                    ]
                ],
                subscriptions: [:]
        )

        verifySubscriberInfo()
        verifyEntitlementActive()
        verifyRenewal(false)
        verifyPeriodType()
        verifyStore()
        verifySandbox()
        verifyProduct(expectedIdentifier: "lifetime",
                      expectedLatestPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                      expectedOriginalPurchaseDate: formatter.date(from: "2019-07-26T23:45:40Z"),
                      expectedExpirationDate: nil)

    }

    func testParseStoreFromSubscription() {
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

        verifyStore(Store.appStore)
        
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
        verifyStore(Store.macAppStore)
        
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
        verifyStore(Store.playStore)
        
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
        verifyStore(Store.promotional)
        
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
        verifyStore(Store.stripe)
        
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
        verifyStore(Store.unknownStore)
    }

    func testParseStoreFromNonSubscription() {
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
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(Store.appStore)

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
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(Store.macAppStore)

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
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(Store.playStore)

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
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(Store.promotional)

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
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(Store.stripe)

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
                        ],
                    ]
                ],
                subscriptions: [:]
        )
        verifyStore(Store.unknownStore)
    }

    func testParsePeriod() {
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

        verifyPeriodType(PeriodType.normal)

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
        verifyPeriodType(PeriodType.intro)

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
        verifyPeriodType(PeriodType.trial)

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
        verifyPeriodType(PeriodType.normal)
    }

    func testParsePeriodForNonSubscription() {
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
                    ],
                ]
            ],
            subscriptions: [:]
        )
        verifyPeriodType(PeriodType.normal)
    }

    func testPromoWillRenew() {
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

        verifyRenewal(false)
    }

    func verifySubscriberInfo() {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!

        expect(subscriberInfo).toNot(beNil())
        expect(subscriberInfo.firstSeen).to(equal(formatter.date(from: "2019-07-26T23:29:50Z")))
        expect(subscriberInfo.originalAppUserId).to(equal("cesarsandbox1"))
    }

    func verifyEntitlementActive(_ expectedEntitlementActive: Bool = true, entitlement: String = "pro_cat") {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements[entitlement]!

        expect(proCat.identifier) == entitlement
        expect(subscriberInfo.entitlements.all.keys.contains(entitlement)) == true
        expect(subscriberInfo.entitlements.active.keys.contains(entitlement)) == expectedEntitlementActive
        expect(proCat.isActive) == expectedEntitlementActive
    }

    func verifyRenewal(_ expectedWillRenew: Bool = true,
                       expectedUnsubscribeDetectedAt: Date? = nil,
                       expectedBillingIssueDetectedAt: Date? = nil,
                       entitlement: String = "pro_cat") {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements[entitlement]!

        expect(proCat.willRenew) == expectedWillRenew
        
        if (expectedUnsubscribeDetectedAt != nil) {
            expect(proCat.unsubscribeDetectedAt) == expectedUnsubscribeDetectedAt
        } else {
            expect(proCat.unsubscribeDetectedAt).to(beNil())
        }
        
        if (expectedBillingIssueDetectedAt != nil) {
            expect(proCat.billingIssueDetectedAt) == expectedBillingIssueDetectedAt
        } else {
            expect(proCat.billingIssueDetectedAt).to(beNil())
        }
    }

    func verifyPeriodType(_ expectedPeriodType: PeriodType = PeriodType.normal, expectedEntitlement: String = "pro_cat") {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements[expectedEntitlement]!

        expect(proCat.periodType) == expectedPeriodType
    }

    func verifyStore(_ expectedStore: Store = Store.appStore, expectedEntitlement: String = "pro_cat") {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements[expectedEntitlement]!

        expect(proCat.store) == expectedStore
    }

    func verifySandbox(_ expectedIsSandbox: Bool = false, expectedEntitlement: String = "pro_cat") {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements[expectedEntitlement]!

        expect(proCat.isSandbox) == expectedIsSandbox
    }
    
    func verifyProduct(expectedIdentifier: String = "monthly_freetrial", expectedEntitlement: String = "pro_cat") {
        verifyProduct(expectedIdentifier: expectedIdentifier,
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
                       expectedEntitlement: String = "pro_cat") {
        let subscriberInfo: PurchaserInfo = PurchaserInfo(data: response)!
        let proCat: EntitlementInfo = subscriberInfo.entitlements[expectedEntitlement]!

        if (expectedLatestPurchaseDate != nil) {
            expect(proCat.latestPurchaseDate) == expectedLatestPurchaseDate
        } else {
            expect(proCat.latestPurchaseDate).to(beNil())
        }

        if (expectedOriginalPurchaseDate != nil) {
            expect(proCat.originalPurchaseDate) == expectedOriginalPurchaseDate
        } else {
            expect(proCat.originalPurchaseDate).to(beNil())
        }
        
        if (expectedExpirationDate != nil) {
            expect(proCat.expirationDate) == expectedExpirationDate
        } else {
            expect(proCat.expirationDate).to(beNil())
        }
        
        expect(proCat.productIdentifier) == expectedIdentifier
    }
}
